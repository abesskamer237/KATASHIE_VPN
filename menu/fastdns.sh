clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "")
export MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
export XRAY_CONF="/etc/xray/config.json"
export FD_XHTTP_PORT=15000
export FD_WS_PORT=15001
export SSLH_LISTEN_PORT=7777

# ─── Helpers ──────────────────────────────────────────────────────────────────

function fd_sslh_active() {
    systemctl is-active --quiet sslh 2>/dev/null
}

function fd_dnstt_installed() {
    local svc
    svc=$(find /etc/systemd/system/ -maxdepth 1 \( -name "*slowdns*.service" -o -name "*dnstt*.service" \) | head -n 1)
    [ -n "$svc" ]
}

function fd_get_dnstt_service() {
    find /etc/systemd/system/ -maxdepth 1 \( -name "*slowdns*.service" -o -name "*dnstt*.service" \) | head -n 1
}

function fd_xhttp_inbound_present() {
    grep -q "\"port\": \"$FD_XHTTP_PORT\"" "$XRAY_CONF" 2>/dev/null || \
    grep -q "\"port\": $FD_XHTTP_PORT" "$XRAY_CONF" 2>/dev/null
}

function fd_count_accounts() {
    grep -c "^#% " "$XRAY_CONF" 2>/dev/null || echo 0
}

# ─── 1. SETUP FAST DNS ────────────────────────────────────────────────────────
# Architecture:
#   Client (dnstt-client DNS tunnel) ──► dnstt-server (UDP 5300/53)
#       └──► SSLH (127.0.0.1:7777) ──► HTTP? → Xray VLESS+XHTTP (127.0.0.1:15000)
#                                    └──► SSH?  → OpenSSH (127.0.0.1:22)
#   Client (direct HTTPS) ──► Nginx 443 ──► /fastdns-ws → Xray VLESS+WS (127.0.0.1:15001)
#                                        └──► /fastdns   → Xray VLESS+XHTTP (127.0.0.1:15000)

function setup_fastdns() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}              FAST DNS SETUP                    ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC}  Architecture Fast DNS:"
    echo -e "${LN}┃${NC}  DNSTT → SSLH:$SSLH_LISTEN_PORT → XHTTP:$FD_XHTTP_PORT (Xray)"
    echo -e "${LN}┃${NC}                         └──────► SSH:22"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC}  SlowDNS MUST already be installed (option [07] DNS)"
    echo -e "${LN}┃${NC}  before running this setup."
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press ENTER to start setup or Ctrl+C to cancel..."
    echo ""

    # ── 1. Verify SlowDNS is installed ──
    echo -e "\n${LN}[1/5]${NC} Checking SlowDNS (dnstt) service..."
    if ! fd_dnstt_installed; then
        echo -e " ${RD}[ERROR] No dnstt/slowdns service found in /etc/systemd/system/${NC}"
        echo -e " ${RD}        Please install SlowDNS first via the DNS PANEL menu.${NC}"
        echo ""
        read -n 1 -s -r -p "  Press any key to return..."
        fastdns_menu
        return
    fi
    local SERVICE_FILE
    SERVICE_FILE=$(fd_get_dnstt_service)
    echo -e " ${GR}-> Service found: $SERVICE_FILE${NC}"

    # ── 2. Add XHTTP and WS inbounds if not already in config.json ──
    echo -e "\n${LN}[2/5]${NC} Checking Xray XHTTP inbound (port $FD_XHTTP_PORT)..."
    if ! fd_xhttp_inbound_present; then
        echo -e " ${GR}-> XHTTP inbound not found — injecting into $XRAY_CONF...${NC}"
        python3 - "$XRAY_CONF" "$FD_XHTTP_PORT" "$FD_WS_PORT" <<'PYEOF'
import sys, re

path  = sys.argv[1]
xport = sys.argv[2]
wport = sys.argv[3]

with open(path, 'r') as f:
    lines = f.readlines()

# Find the line that closes the inbounds array (matches "]," or "]") and
# is immediately followed by the "outbounds" key, so we target the right array.
insert_idx = None
for i in range(len(lines) - 1, -1, -1):
    if re.match(r'^\s*\],?\s*$', lines[i]) and i + 1 < len(lines) and '"outbounds"' in lines[i + 1]:
        insert_idx = i
        break

if insert_idx is None:
    print("ERROR: Could not find end of inbounds array", file=sys.stderr)
    sys.exit(1)

# Add a trailing comma to the closing brace of the current last inbound.
# Guard against an empty inbounds array (prev line would be "[", not "}").
prev_idx = insert_idx - 1
if prev_idx >= 0 and re.search(r'\}', lines[prev_idx]):
    lines[prev_idx] = lines[prev_idx].rstrip().rstrip(',') + ',\n'

template = (
    '    {\n'
    '      "listen": "127.0.0.1",\n'
    '      "port": XPORT,\n'
    '      "protocol": "vless",\n'
    '      "settings": {\n'
    '        "decryption": "none",\n'
    '        "clients": [\n'
    '          {\n'
    '            "id": "22f5a909-37d9-4174-aa54-1e503ad7e523"\n'
    '#fastdns\n'
    '          }\n'
    '        ]\n'
    '      },\n'
    '      "streamSettings": {\n'
    '        "network": "xhttp",\n'
    '        "xhttpSettings": {\n'
    '          "path": "/fastdns",\n'
    '          "mode": "stream-one"\n'
    '        }\n'
    '      }\n'
    '    },\n'
    '    {\n'
    '      "listen": "127.0.0.1",\n'
    '      "port": WPORT,\n'
    '      "protocol": "vless",\n'
    '      "settings": {\n'
    '        "decryption": "none",\n'
    '        "clients": [\n'
    '          {\n'
    '            "id": "22f5a909-37d9-4174-aa54-1e503ad7e523"\n'
    '#fastdnsws\n'
    '          }\n'
    '        ]\n'
    '      },\n'
    '      "streamSettings": {\n'
    '        "network": "ws",\n'
    '        "wsSettings": {\n'
    '          "path": "/fastdns-ws"\n'
    '        }\n'
    '      }\n'
    '    }\n'
)

new_blocks = template.replace('XPORT', xport).replace('WPORT', wport)
lines.insert(insert_idx, new_blocks)

with open(path, 'w') as f:
    f.writelines(lines)

print("Fast DNS inbounds injected successfully.")
PYEOF
        if ! fd_xhttp_inbound_present; then
            echo -e " ${RD}[ERROR] Failed to inject XHTTP inbound into $XRAY_CONF${NC}"
            echo ""
            read -n 1 -s -r -p "  Press any key to return..."
            fastdns_menu
            return
        fi
        echo -e " ${GR}-> XHTTP and WS inbounds injected successfully${NC}"
    else
        echo -e " ${GR}-> XHTTP inbound OK (port $FD_XHTTP_PORT)${NC}"
    fi

    # ── 3. Install SSLH multiplexer ──
    echo -e "\n${LN}[3/5]${NC} Installing SSLH protocol multiplexer..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y sslh >/dev/null 2>&1
    if ! command -v sslh >/dev/null 2>&1; then
        echo -e " ${RD}[ERROR] Failed to install sslh. Check apt sources.${NC}"
        echo ""
        read -n 1 -s -r -p "  Press any key to return..."
        fastdns_menu
        return
    fi
    echo -e " ${GR}-> SSLH installed${NC}"

    # Configure SSLH: listen on 127.0.0.1:7777
    # HTTP traffic  → Xray XHTTP (127.0.0.1:15000)
    # SSH traffic   → OpenSSH (127.0.0.1:22)
    cat > /etc/default/sslh <<EOF
RUN=yes
DAEMON=/usr/sbin/sslh
DAEMON_OPTS="--user sslh --listen 127.0.0.1:$SSLH_LISTEN_PORT --ssh 127.0.0.1:22 --http 127.0.0.1:$FD_XHTTP_PORT --pidfile /var/run/sslh/sslh.pid"
EOF
    # Also write a modern config file for systems that use it
    if [ -d /etc/sslh ]; then
        cat > /etc/sslh/sslh.cfg <<EOF
verbose: false;
foreground: false;
inetd: false;
numeric: false;
timeout: 5;
user: "sslh";
listen:
(
    { host: "127.0.0.1"; port: "$SSLH_LISTEN_PORT"; }
);
protocols:
(
    { name: "ssh";  host: "127.0.0.1"; port: "22";            log_level: 0; },
    { name: "http"; host: "127.0.0.1"; port: "$FD_XHTTP_PORT"; log_level: 0; }
);
EOF
    fi
    systemctl enable sslh >/dev/null 2>&1
    systemctl restart sslh 2>/dev/null
    echo -e " ${GR}-> SSLH configured on 127.0.0.1:$SSLH_LISTEN_PORT${NC}"
    echo -e " ${GR}   HTTP  → Xray XHTTP :$FD_XHTTP_PORT${NC}"
    echo -e " ${GR}   SSH   → OpenSSH    :22${NC}"

    # ── 4. Redirect dnstt to SSLH instead of SSH:22 ──
    echo -e "\n${LN}[4/5]${NC} Redirecting dnstt → SSLH (port $SSLH_LISTEN_PORT)..."
    # Backup original service file (only if no backup exists yet)
    if [ ! -f "${SERVICE_FILE}.bak" ]; then
        cp "$SERVICE_FILE" "${SERVICE_FILE}.bak"
        echo -e " ${GR}-> Backup saved: ${SERVICE_FILE}.bak${NC}"
    fi
    # Replace only the destination address at the end of the ExecStart line
    # (e.g. 127.0.0.1:22 or localhost:22 → 127.0.0.1:7777), leaving bind
    # addresses like -udp :5300 untouched.
    sed -i -E "/^ExecStart=/ s/127\.0\.0\.1:[0-9]+[[:space:]]*$/127.0.0.1:$SSLH_LISTEN_PORT/" "$SERVICE_FILE"
    sed -i -E "/^ExecStart=/ s/localhost:[0-9]+[[:space:]]*$/127.0.0.1:$SSLH_LISTEN_PORT/" "$SERVICE_FILE"
    systemctl daemon-reload
    local DNSTT_SVC
    DNSTT_SVC=$(basename "$SERVICE_FILE")
    systemctl restart "${DNSTT_SVC%.service}" 2>/dev/null || systemctl restart "$DNSTT_SVC" 2>/dev/null
    echo -e " ${GR}-> dnstt now routes to SSLH :$SSLH_LISTEN_PORT${NC}"

    # ── 5. Update Nginx for direct XHTTP + WS access ──
    echo -e "\n${LN}[5/5]${NC} Updating Nginx with Fast DNS locations..."
    local NGINX_CONF="/etc/nginx/nginx.conf"
    if ! grep -q "fastdns-ws" "$NGINX_CONF" 2>/dev/null; then
        # Insert the two location blocks before the Fallback comment
        python3 - "$NGINX_CONF" "$FD_XHTTP_PORT" "$FD_WS_PORT" <<'PYEOF'
import sys, re

path  = sys.argv[1]
xport = sys.argv[2]
wport = sys.argv[3]

with open(path, 'r') as f:
    content = f.read()

new_blocks = f"""
        # FAST DNS XHTTP
        location /fastdns {{
            proxy_redirect off;
            proxy_pass http://127.0.0.1:{xport};
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }}

        # FAST DNS WS
        location /fastdns-ws {{
            proxy_redirect off;
            proxy_pass http://127.0.0.1:{wport};
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }}

"""

# Insert before the Fallback (root) block
content = re.sub(
    r'(\s*# Fallback \(root\))',
    new_blocks + r'\1',
    content,
    count=1
)

with open(path, 'w') as f:
    f.write(content)
print("Nginx updated.")
PYEOF
        if nginx -t >/dev/null 2>&1; then
            systemctl reload nginx 2>/dev/null || systemctl restart nginx 2>/dev/null
            echo -e " ${GR}-> Nginx updated and reloaded${NC}"
        else
            echo -e " ${RD}[WARN] Nginx config test failed. Nginx NOT reloaded.${NC}"
            echo -e " ${RD}       Check /etc/nginx/nginx.conf manually.${NC}"
        fi
    else
        echo -e " ${GR}-> Nginx already has Fast DNS locations. Skipped.${NC}"
    fi

    systemctl restart xray 2>/dev/null

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}           FAST DNS SETUP COMPLETE              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${GR}Architecture active:${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Client dnstt-client"
    echo -e "${LN}┃${NC}   → DNS tunnel (UDP 53/5300)"
    echo -e "${LN}┃${NC}     → SSLH 127.0.0.1:$SSLH_LISTEN_PORT"
    echo -e "${LN}┃${NC}       HTTP  → Xray VLESS+XHTTP :$FD_XHTTP_PORT"
    echo -e "${LN}┃${NC}       SSH   → OpenSSH :22"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Direct (HTTPS via Nginx)"
    echo -e "${LN}┃${NC}   :443 /fastdns    → Xray XHTTP :$FD_XHTTP_PORT"
    echo -e "${LN}┃${NC}   :443 /fastdns-ws → Xray WS    :$FD_WS_PORT"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} ${GR}Next: Create accounts with option [02]${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return to the menu..."
    fastdns_menu
}

# ─── 2. CREATE ACCOUNT ────────────────────────────────────────────────────────
# Inserts the new user into BOTH the XHTTP inbound (#fastdns marker)
# and the WS inbound (#fastdnsws marker) so the same UUID/account works
# for both transport types.

function add_fastdns() {
    clear
    if ! fd_xhttp_inbound_present; then
        echo -e "${RD} [ERROR] Fast DNS not set up. Run option [01] first.${NC}"
        sleep 2
        fastdns_menu
        return
    fi
    while true; do
        echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${LN}┃${NC} ${BG}           ADD FAST DNS ACCOUNT               ${NC} ${LN}┃${NC}"
        echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
        echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
        echo ""
        read -rp "  Enter username: " user
        if [[ -z "$user" ]]; then
            echo -e " ${RD}Username cannot be empty. Please try again.${NC}"
            continue
        fi
        if [[ ! "$user" =~ ^[a-zA-Z0-9_]{1,32}$ ]]; then
            echo -e " ${RD}Username: letters, numbers, underscores only (max 32).${NC}"
            continue
        fi
        if grep -qw "fdns-x-$user" "$XRAY_CONF" 2>/dev/null; then
            echo -e " ${RD}This username already exists. Choose another one.${NC}"
            read -n 1 -s -r -p "  Press any key..."
            clear
            continue
        fi
        break
    done
    while true; do
        read -rp "  Validity (days): " masaaktif
        if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
            echo -e " ${RD}Expiry days must be a positive number.${NC}"
            continue
        fi
        break
    done

    local uuid exp
    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")

    # Insert into XHTTP inbound (marked with #fastdns)
    sed -i '/#fastdns$/a\#% '"$user $exp $uuid"'\
},{"id": "'"$uuid"'","email": "fdns-x-'"$user"'"' "$XRAY_CONF"

    # Insert into WebSocket inbound (marked with #fastdnsws)
    sed -i '/#fastdnsws$/a\#%w '"$user $exp $uuid"'\
},{"id": "'"$uuid"'","email": "fdns-w-'"$user"'"' "$XRAY_CONF"

    systemctl restart xray >/dev/null 2>&1

    # ── Generate connection links ──
    export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "")
    local PUB="" DNS_DOMAIN=""
    PUB=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "N/A")
    DNS_DOMAIN=$(cat /etc/slowdns/nsdomain 2>/dev/null || echo "N/A")

    # XHTTP links (for direct HTTPS through Nginx or through tunnel)
    local xhttp_tls xhttp_ntls ws_tls ws_ntls
    xhttp_tls="vless://${uuid}@${DOMAIN}:443?encryption=none&security=tls&type=xhttp&path=/fastdns&host=${DOMAIN}&sni=${DOMAIN}#${user}"
    xhttp_ntls="vless://${uuid}@${DOMAIN}:80?encryption=none&type=xhttp&path=/fastdns&host=${DOMAIN}#${user}"
    ws_tls="vless://${uuid}@${DOMAIN}:443?path=/fastdns-ws&security=tls&encryption=none&type=ws&host=${DOMAIN}#${user}"
    ws_ntls="vless://${uuid}@${DOMAIN}:80?path=/fastdns-ws&encryption=none&type=ws&host=${DOMAIN}#${user}"

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}          FAST DNS ACCOUNT DETAILS              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Username    : ${user}"
    echo -e "${LN}┃${NC} UUID        : ${uuid}"
    echo -e "${LN}┃${NC} Expiry Date : ${exp}"
    echo -e "${LN}┃${NC} Domain      : ${DOMAIN}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} ${GR}[MODE 1] XHTTP via HTTPS (direct — fast)${NC}"
    echo -e "${LN}┃${NC} Protocol    : VLESS + XHTTP"
    echo -e "${LN}┃${NC} Port TLS    : 443   Path: /fastdns"
    echo -e "${LN}┃${NC} Port NoTLS  : 80    Path: /fastdns"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} TLS  : ${xhttp_tls}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} NTLS : ${xhttp_ntls}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} ${GR}[MODE 2] WebSocket via HTTPS (fallback)${NC}"
    echo -e "${LN}┃${NC} Protocol    : VLESS + WebSocket"
    echo -e "${LN}┃${NC} Port TLS    : 443   Path: /fastdns-ws"
    echo -e "${LN}┃${NC} Port NoTLS  : 80    Path: /fastdns-ws"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} TLS  : ${ws_tls}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} NTLS : ${ws_ntls}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} ${GR}[MODE 3] SlowDNS tunnel (no-TCP bypass)${NC}"
    echo -e "${LN}┃${NC} Use the XHTTP link above inside dnstt-client."
    echo -e "${LN}┃${NC} SlowDNS PubKey  : ${PUB}"
    echo -e "${LN}┃${NC} SlowDNS NS      : ${DNS_DOMAIN}"
    echo -e "${LN}┃${NC} dnstt Server    : ${DOMAIN} (UDP 53)"
    echo -e "${LN}┃${NC} Config app      : VLESS+XHTTP → localhost (dnstt port)"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return to the menu..."
    fastdns_menu
}

# ─── 3. RENEW ACCOUNT ─────────────────────────────────────────────────────────
# Extends the expiry of an existing Fast DNS account.
# Updates the #% and #%w marker lines in both inbounds simultaneously.

function renew_fastdns() {
    clear
    local count
    count=$(fd_count_accounts)
    if [[ "$count" -eq 0 ]]; then
        echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${LN}┃${NC} ${BG}           RENEW FAST DNS ACCOUNT              ${NC} ${LN}┃${NC}"
        echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
        echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
        echo -e "${LN}┃${NC} ${RD}No Fast DNS accounts found.${NC}"
        echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
        echo ""
        read -n 1 -s -r -p "  Press any key to return..."
        fastdns_menu
        return
    fi
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}           RENEW FAST DNS ACCOUNT              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Username          Expiry Date"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    grep -E "^#% " "$XRAY_CONF" | awk '{print $2, $3}' | sort -u | while read -r u e; do
        printf "${LN}┃${NC} %-18s %s\n" "$u" "$e"
    done
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} (Enter to go back)"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    while true; do
        read -rp "  Input Username: " user
        if [[ -z "$user" ]]; then
            fastdns_menu
            return
        fi
        if ! grep -qwE "^#% $user" "$XRAY_CONF" 2>/dev/null; then
            echo -e " ${RD}Username not found. Try again.${NC}"
            continue
        fi
        break
    done
    while true; do
        read -rp "  Extend by (days): " masaaktif
        if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
            echo -e " ${RD}Enter a positive number of days.${NC}"
            continue
        fi
        break
    done

    local exp uuid now d1 d2 exp2 exp3 exp4
    exp=$(grep -wE "^#% $user" "$XRAY_CONF" | awk '{print $3}' | sort -u | head -1)
    uuid=$(grep -wE "^#% $user" "$XRAY_CONF" | awk '{print $4}' | sort -u | head -1)
    now=$(date +%Y-%m-%d)
    d1=$(date -d "$exp" +%s 2>/dev/null || echo "")
    d2=$(date -d "$now" +%s)
    if [[ -z "$d1" || "$d1" -le 0 ]]; then
        # Expiry date is invalid or already past — extend from today
        exp4=$(date -d "$masaaktif days" +"%Y-%m-%d")
    else
        exp2=$(( (d1 - d2) / 86400 ))
        exp3=$(( exp2 + masaaktif ))
        exp4=$(date -d "$exp3 days" +"%Y-%m-%d")
    fi

    # Update both XHTTP and WS marker lines
    sed -i "/^#% $user /c\\#% $user $exp4 $uuid" "$XRAY_CONF"
    sed -i "/^#%w $user /c\\#%w $user $exp4 $uuid" "$XRAY_CONF"
    systemctl restart xray >/dev/null 2>&1

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}         FAST DNS ACCOUNT RENEWED              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Username   : ${user}"
    echo -e "${LN}┃${NC} UUID       : ${uuid}"
    echo -e "${LN}┃${NC} Days Added : ${masaaktif}"
    echo -e "${LN}┃${NC} New Expiry : ${exp4}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    fastdns_menu
}

# ─── 4. DELETE ACCOUNT ────────────────────────────────────────────────────────
# Removes the user from both XHTTP and WS inbounds atomically.

function delete_fastdns() {
    clear
    local count
    count=$(fd_count_accounts)
    if [[ "$count" -eq 0 ]]; then
        echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${LN}┃${NC} ${BG}          DELETE FAST DNS ACCOUNT              ${NC} ${LN}┃${NC}"
        echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
        echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
        echo -e "${LN}┃${NC} ${RD}No Fast DNS accounts found.${NC}"
        echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
        echo ""
        read -n 1 -s -r -p "  Press any key to return..."
        fastdns_menu
        return
    fi
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}          DELETE FAST DNS ACCOUNT              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Username          Expiry Date"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    grep -E "^#% " "$XRAY_CONF" | awk '{print $2, $3}' | sort -u | while read -r u e; do
        printf "${LN}┃${NC} %-18s %s\n" "$u" "$e"
    done
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} (Enter to go back)"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -rp "  Input Username: " duser
    if [[ -z "$duser" ]]; then
        fastdns_menu
        return
    fi
    local exp
    exp=$(grep -wE "^#% $duser" "$XRAY_CONF" | awk '{print $3}' | sort -u | head -1)
    if [[ -z "$exp" ]]; then
        echo -e " ${RD}Username not found.${NC}"
        sleep 2
        fastdns_menu
        return
    fi
    # Remove marker lines and JSON client objects from both inbounds
    sed -i -e "/^#% $duser /d" -e "/\"email\": \"fdns-x-$duser\"/d" "$XRAY_CONF"
    sed -i -e "/^#%w $duser /d" -e "/\"email\": \"fdns-w-$duser\"/d" "$XRAY_CONF"
    systemctl restart xray >/dev/null 2>&1

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}         FAST DNS ACCOUNT DELETED              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Username : ${duser}"
    echo -e "${LN}┃${NC} Expired  : ${exp}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    fastdns_menu
}

# ─── 5. LIST ACCOUNTS ─────────────────────────────────────────────────────────
# Shows all accounts with username, UUID and expiry, then offers to view
# the full connection links for a specific user.

function list_fastdns() {
    clear
    local count
    count=$(fd_count_accounts)
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}           FAST DNS ACCOUNT LIST               ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Total accounts : ${count}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} Username          Expiry"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    if [[ "$count" -eq 0 ]]; then
        echo -e "${LN}┃${NC} ${RD}No accounts found.${NC}"
    else
        grep -E "^#% " "$XRAY_CONF" | awk '{print $2, $3}' | sort -u | while read -r u e; do
            printf "${LN}┃${NC} %-18s %s\n" "$u" "$e"
        done
    fi
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Enter username to view links, or Enter to go back"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -rp "  Username: " user
    if [[ -z "$user" ]]; then
        fastdns_menu
        return
    fi
    view_fastdns "$user"
}

# ─── 6. VIEW ACCOUNT (links) ─────────────────────────────────────────────────

function view_fastdns() {
    local user="$1"
    if [[ -z "$user" ]]; then
        clear
        if [[ $(fd_count_accounts) -eq 0 ]]; then
            echo -e " ${RD}No Fast DNS accounts found.${NC}"
            sleep 2
            fastdns_menu
            return
        fi
        echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${LN}┃${NC} ${BG}           VIEW FAST DNS ACCOUNT               ${NC} ${LN}┃${NC}"
        echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
        grep -E "^#% " "$XRAY_CONF" | awk '{print $2, $3}' | sort -u | while read -r u e; do
            printf "${LN}┃${NC} %-18s %s\n" "$u" "$e"
        done
        echo ""
        read -rp "  Username: " user
        if [[ -z "$user" ]]; then
            fastdns_menu
            return
        fi
    fi

    local exp UUID
    exp=$(grep -wE "^#% $user" "$XRAY_CONF" | awk '{print $3}' | sort -u | head -1)
    UUID=$(grep -wE "^#% $user" "$XRAY_CONF" | awk '{print $4}' | sort -u | head -1)
    if [[ -z "$exp" ]]; then
        echo -e " ${RD}Username not found.${NC}"
        sleep 2
        fastdns_menu
        return
    fi

    export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "")
    local PUB DNS_DOMAIN
    PUB=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "N/A")
    DNS_DOMAIN=$(cat /etc/slowdns/nsdomain 2>/dev/null || echo "N/A")

    local xhttp_tls xhttp_ntls ws_tls ws_ntls
    xhttp_tls="vless://${UUID}@${DOMAIN}:443?encryption=none&security=tls&type=xhttp&path=/fastdns&host=${DOMAIN}&sni=${DOMAIN}#${user}"
    xhttp_ntls="vless://${UUID}@${DOMAIN}:80?encryption=none&type=xhttp&path=/fastdns&host=${DOMAIN}#${user}"
    ws_tls="vless://${UUID}@${DOMAIN}:443?path=/fastdns-ws&security=tls&encryption=none&type=ws&host=${DOMAIN}#${user}"
    ws_ntls="vless://${UUID}@${DOMAIN}:80?path=/fastdns-ws&encryption=none&type=ws&host=${DOMAIN}#${user}"

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}           FAST DNS ACCOUNT DETAILS             ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Username    : ${user}"
    echo -e "${LN}┃${NC} UUID        : ${UUID}"
    echo -e "${LN}┃${NC} Expiry Date : ${exp}"
    echo -e "${LN}┃${NC} Domain      : ${DOMAIN}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} ${GR}XHTTP TLS (443):${NC}"
    echo -e "${LN}┃${NC} ${xhttp_tls}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} ${GR}XHTTP NoTLS (80):${NC}"
    echo -e "${LN}┃${NC} ${xhttp_ntls}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} ${GR}WS TLS (443):${NC}"
    echo -e "${LN}┃${NC} ${ws_tls}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} ${GR}WS NoTLS (80):${NC}"
    echo -e "${LN}┃${NC} ${ws_ntls}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} ${GR}SlowDNS Tunnel Config:${NC}"
    echo -e "${LN}┃${NC} PubKey   : ${PUB}"
    echo -e "${LN}┃${NC} NS Domain: ${DNS_DOMAIN}"
    echo -e "${LN}┃${NC} Server   : ${DOMAIN} (UDP 53)"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    fastdns_menu
}

# ─── 7. ACTIVE USERS ──────────────────────────────────────────────────────────
# Shows which Fast DNS users currently have an active Xray TCP connection
# by cross-referencing netstat with the Xray access log.

function active_fastdns() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}         FAST DNS ACTIVE USERS                 ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"

    local data any_active=false
    mapfile -t data < <(grep "^#% " "$XRAY_CONF" | awk '{print $2}')
    local live_ips
    mapfile -t live_ips < <(netstat -anp 2>/dev/null | grep ESTABLISHED | grep tcp6 | grep xray | awk '{print $5}' | cut -d: -f1 | sort -u)

    for user in "${data[@]}"; do
        [[ -z "$user" ]] && continue
        local matched=()
        for ip in "${live_ips[@]}"; do
            local hit
            hit=$(grep "fdns-x-$user\|fdns-w-$user" /var/log/xray/access.log 2>/dev/null | grep "$ip" | wc -l)
            [[ "$hit" -gt 0 ]] && matched+=("$ip")
        done
        if [[ ${#matched[@]} -gt 0 ]]; then
            any_active=true
            echo -e "${LN}┃${NC} User : ${user}"
            for ip in "${matched[@]}"; do
                echo -e "${LN}┃${NC}   → ${ip}"
            done
            echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
        fi
    done
    if [[ "$any_active" == false ]]; then
        echo -e "${LN}┃${NC} No active Fast DNS users."
        echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    fi
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    fastdns_menu
}

# ─── 8. STATUS ────────────────────────────────────────────────────────────────
# Displays the live status of every service involved in the Fast DNS stack:
# SSLH multiplexer, dnstt tunnel, Nginx proxy, and Xray core.

function status_fastdns() {
    clear
    local sslh_st dnstt_st nginx_st xray_st sslh_cfg

    sslh_st=$(systemctl is-active sslh 2>/dev/null); [[ -z "$sslh_st" ]] && sslh_st="inactive"
    nginx_st=$(systemctl is-active nginx 2>/dev/null); [[ -z "$nginx_st" ]] && nginx_st="inactive"
    xray_st=$(systemctl is-active xray 2>/dev/null); [[ -z "$xray_st" ]] && xray_st="inactive"

    local DNSTT_SVC_FILE
    DNSTT_SVC_FILE=$(fd_get_dnstt_service)
    if [[ -n "$DNSTT_SVC_FILE" ]]; then
        local svc_name
        svc_name=$(basename "${DNSTT_SVC_FILE%.service}")
        dnstt_st=$(systemctl is-active "$svc_name" 2>/dev/null); [[ -z "$dnstt_st" ]] && dnstt_st="inactive"
    else
        dnstt_st="not installed"
    fi

    local fmt_sslh fmt_dnstt fmt_nginx fmt_xray
    [[ "$sslh_st"  == "active" ]] && fmt_sslh="${GR}RUNNING${NC}"  || fmt_sslh="${RD}STOPPED${NC}"
    [[ "$dnstt_st" == "active" ]] && fmt_dnstt="${GR}RUNNING${NC}" || fmt_dnstt="${RD}${dnstt_st}${NC}"
    [[ "$nginx_st" == "active" ]] && fmt_nginx="${GR}RUNNING${NC}" || fmt_nginx="${RD}STOPPED${NC}"
    [[ "$xray_st"  == "active" ]] && fmt_xray="${GR}RUNNING${NC}"  || fmt_xray="${RD}STOPPED${NC}"

    # Read current SSLH destination from config
    sslh_cfg=$(grep "DAEMON_OPTS" /etc/default/sslh 2>/dev/null | grep -o "\-\-http [^ ]*" || echo "--http N/A")

    local PUB DNS_DOMAIN
    PUB=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "N/A")
    DNS_DOMAIN=$(cat /etc/slowdns/nsdomain 2>/dev/null || echo "N/A")
    local acct_count
    acct_count=$(fd_count_accounts)

    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}           FAST DNS STATUS                      ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} SSLH (mux)  : $(echo -e $fmt_sslh)   [127.0.0.1:$SSLH_LISTEN_PORT]"
    echo -e "${LN}┃${NC} SSLH routes : HTTP→:$FD_XHTTP_PORT (Xray)  SSH→:22"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} dnstt       : $(echo -e $fmt_dnstt)"
    echo -e "${LN}┃${NC} SlowDNS NS  : ${DNS_DOMAIN}"
    echo -e "${LN}┃${NC} PubKey      : ${PUB}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Nginx       : $(echo -e $fmt_nginx)"
    echo -e "${LN}┃${NC} Xray        : $(echo -e $fmt_xray)"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Inbound XHTTP  : 127.0.0.1:$FD_XHTTP_PORT  path=/fastdns"
    echo -e "${LN}┃${NC} Inbound WS     : 127.0.0.1:$FD_WS_PORT  path=/fastdns-ws"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Accounts    : ${acct_count}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    fastdns_menu
}

# ─── 9. UNINSTALL FAST DNS ────────────────────────────────────────────────────
# Reverts the dnstt service to its original SSH-only destination,
# stops SSLH, and removes the SSLH configuration.
# The Xray inbounds and Nginx locations are kept (harmless without SSLH).

function uninstall_fastdns() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}          UNINSTALL FAST DNS                    ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} This will:"
    echo -e "${LN}┃${NC}  • Restore dnstt → SSH:22 (original behaviour)"
    echo -e "${LN}┃${NC}  • Stop and disable SSLH"
    echo -e "${LN}┃${NC}  • SlowDNS will still work for SSH tunnelling"
    echo -e "${LN}┃${NC}  • Fast DNS accounts in Xray are kept"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} [01] • Confirm uninstall"
    echo -e "${LN}┃${NC} [00] • Cancel"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -rp "  Select: " opt
    case $opt in
    1|01) ;;
    *) fastdns_menu; return ;;
    esac

    local SERVICE_FILE
    SERVICE_FILE=$(fd_get_dnstt_service)
    if [[ -n "$SERVICE_FILE" && -f "${SERVICE_FILE}.bak" ]]; then
        echo -e " ${GR}-> Restoring original dnstt config from backup...${NC}"
        cp "${SERVICE_FILE}.bak" "$SERVICE_FILE"
        systemctl daemon-reload
        local svc_name
        svc_name=$(basename "${SERVICE_FILE%.service}")
        systemctl restart "$svc_name" 2>/dev/null || systemctl restart "$(basename "$SERVICE_FILE")" 2>/dev/null
        echo -e " ${GR}-> dnstt restored to original SSH destination${NC}"
    else
        echo -e " ${RD}[WARN] No dnstt backup found. Skipping restore.${NC}"
    fi

    echo -e " ${GR}-> Stopping and disabling SSLH...${NC}"
    systemctl stop sslh 2>/dev/null
    systemctl disable sslh 2>/dev/null
    rm -f /etc/default/sslh /etc/sslh/sslh.cfg 2>/dev/null

    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}          FAST DNS UNINSTALLED                  ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${GR}dnstt restored → SSH :22${NC}"
    echo -e "${LN}┃${NC} ${GR}SSLH stopped and disabled${NC}"
    echo -e "${LN}┃${NC} SlowDNS (SSH) is working normally again."
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    fastdns_menu
}

# ─── 10. RESTART FAST DNS SERVICES ───────────────────────────────────────────
# Resets any failed units then restarts dnstt, SSLH, Nginx, and Xray so the
# full Fast DNS stack comes back online without needing a full re-setup.

function restart_fastdns() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}         RESTART FAST DNS SERVICES              ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"

    # Clear any failed-unit flags and reload service definitions for all units
    if ! systemctl reset-failed 2>/dev/null; then
        echo -e "${LN}┃${NC} ${RD}[WARN] systemctl reset-failed failed — continuing anyway${NC}"
    fi
    systemctl daemon-reload 2>/dev/null

    # Restart dnstt / slowdns tunnel
    local DNSTT_SVC_FILE svc_name
    DNSTT_SVC_FILE=$(fd_get_dnstt_service)
    if [[ -n "$DNSTT_SVC_FILE" ]]; then
        svc_name=$(basename "${DNSTT_SVC_FILE%.service}")
        systemctl restart "$svc_name" 2>/dev/null
        local st
        st=$(systemctl is-active "$svc_name" 2>/dev/null); [[ -z "$st" ]] && st="inactive"
        if [[ "$st" == "active" ]]; then
            echo -e "${LN}┃${NC} dnstt ($svc_name)  : ${GR}RUNNING${NC}"
        else
            echo -e "${LN}┃${NC} dnstt ($svc_name)  : ${RD}${st}${NC}"
            echo -e "${LN}┃${NC}   ${RD}Check: journalctl -u $svc_name -n 20${NC}"
        fi
    else
        echo -e "${LN}┃${NC} dnstt  : ${RD}not installed${NC}"
    fi

    # Restart SSLH
    systemctl restart sslh 2>/dev/null
    local sslh_st
    sslh_st=$(systemctl is-active sslh 2>/dev/null); [[ -z "$sslh_st" ]] && sslh_st="inactive"
    [[ "$sslh_st" == "active" ]] \
        && echo -e "${LN}┃${NC} SSLH   : ${GR}RUNNING${NC}" \
        || echo -e "${LN}┃${NC} SSLH   : ${RD}${sslh_st}${NC}"

    # Restart Nginx
    systemctl restart nginx 2>/dev/null
    local nginx_st
    nginx_st=$(systemctl is-active nginx 2>/dev/null); [[ -z "$nginx_st" ]] && nginx_st="inactive"
    [[ "$nginx_st" == "active" ]] \
        && echo -e "${LN}┃${NC} Nginx  : ${GR}RUNNING${NC}" \
        || echo -e "${LN}┃${NC} Nginx  : ${RD}${nginx_st}${NC}"

    # Restart Xray
    systemctl restart xray 2>/dev/null
    local xray_st
    xray_st=$(systemctl is-active xray 2>/dev/null); [[ -z "$xray_st" ]] && xray_st="inactive"
    if [[ "$xray_st" == "active" ]]; then
        echo -e "${LN}┃${NC} Xray   : ${GR}RUNNING${NC}"
    else
        echo -e "${LN}┃${NC} Xray   : ${RD}${xray_st}${NC}"
        echo -e "${LN}┃${NC}   ${RD}Check: journalctl -u xray -n 20${NC}"
    fi

    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -n 1 -s -r -p "  Press any key to return..."
    fastdns_menu
}

# ─── MAIN MENU ────────────────────────────────────────────────────────────────

function fastdns_menu() {
    clear
    export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")

    local sslh_status dnstt_status
    if fd_sslh_active; then
        sslh_status="${GR}RUN${NC}"
    else
        sslh_status="${RD}OFF${NC}"
    fi
    if fd_dnstt_installed; then
        local dsvc
        dsvc=$(basename "$(fd_get_dnstt_service)" 2>/dev/null)
        dsvc="${dsvc%.service}"
        if systemctl is-active --quiet "$dsvc" 2>/dev/null; then
            dnstt_status="${GR}RUN${NC}"
        else
            dnstt_status="${RD}OFF${NC}"
        fi
    else
        dnstt_status="${RD}N/A${NC}"
    fi

    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}              FAST DNS MENU                     ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC}  SSLH : [$(echo -e $sslh_status)]    DNSTT : [$(echo -e $dnstt_status)]"
    echo -e "${LN}┃${NC}  Domain : ${DOMAIN}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} [01] • Setup Fast DNS     [06] • View Account"
    echo -e "${LN}┃${NC} [02] • Create Account     [07] • Active Users"
    echo -e "${LN}┃${NC} [03] • Renew Account      [08] • Status"
    echo -e "${LN}┃${NC} [04] • Delete Account     [09] • Uninstall"
    echo -e "${LN}┃${NC} [05] • List Accounts      [10] • Restart Services"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} [00] • Back to Main Menu"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -rp "  Select menu: " opt
    echo ""
    case $opt in
    1|01) clear ; setup_fastdns ;;
    2|02) clear ; add_fastdns ;;
    3|03) clear ; renew_fastdns ;;
    4|04) clear ; delete_fastdns ;;
    5|05) clear ; list_fastdns ;;
    6|06) clear ; view_fastdns "" ;;
    7|07) clear ; active_fastdns ;;
    8|08) clear ; status_fastdns ;;
    9|09) clear ; uninstall_fastdns ;;
    10)   clear ; restart_fastdns ;;
    0|00) clear ; menu ;;
    *)
        echo -e "${RD} [ERROR] Invalid selection!${NC}"
        sleep 1
        fastdns_menu
        ;;
    esac
}

fastdns_menu
