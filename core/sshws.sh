clear
export DEBIAN_FRONTEND=noninteractive
export SERVER_HOST="https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main"
setup_variables() {
MYIP=$(wget -qO- ipv4.icanhazip.com)
NET=$(ip -o -4 route show to default | awk '{print $5}')
source /etc/os-release
ver=$VERSION_ID
}
set_simple_password() {
curl -sS ${SERVER_HOST}/module/password | \
openssl aes-256-cbc -d -a -pass pass:scvps07gg -pbkdf2 > /etc/pam.d/common-password
chmod 644 /etc/pam.d/common-password
}
setup_rc_local() {
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END
cat > /etc/rc.local <<-END
exit 0
END
chmod +x /etc/rc.local
systemctl daemon-reload
systemctl enable rc-local
systemctl start rc-local
}
disable_ipv6() {
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ icho 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
}
configure_nginx() {
apt-get install -y nginx
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
wget -q -O /etc/nginx/nginx.conf "${SERVER_HOST}/module/nginx.conf"
rm -f /etc/nginx/conf.d/default.conf
mkdir -p /etc/systemd/system/nginx.service.d
printf "[Service]
ExecStartPost=/bin/sleep 0.1
" > /etc/systemd/system/nginx.service.d/override.conf
systemctl daemon-reload
systemctl enable --now nginx
}
setup_web_directories() {
mkdir -p /home/vps/public_html
wget -q -O /home/vps/public_html/index.html "${SERVER_HOST}/module/index"
chown -R www-data:www-data /home/vps/public_html
}
install_badvpn() {
wget -q -O /usr/bin/badvpn-udpgw "${SERVER_HOST}/module/newudpgw"
chmod +x /usr/bin/badvpn-udpgw
wget -q -O /etc/systemd/system/badvpn@.service "${SERVER_HOST}/module/badvpn@.service"
systemctl daemon-reload
systemctl enable --now badvpn@7100
systemctl enable --now badvpn@7200
systemctl enable --now badvpn@7300
echo "BadVPN installed and started on ports 7100-7300."
}
configure_ssh_dropbear() {
apt-get install -y dropbear
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
for port in 500 40000 81 51443 58080 666; do
sed -i "/^Port 22/a Port $port" /etc/ssh/sshd_config
done
systemctl restart ssh
sed -i 's/^NO_START=1/NO_START=0/' /etc/default/dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's#DROPBEAR_EXTRA_ARGS=.*#DROPBEAR_EXTRA_ARGS="-p 50000 -p 109 -p 110 -p 69"#g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
systemctl enable --now dropbear
}
configure_stunnel() {
STUNNEL_VERSION="5.75"
STUNNEL_URL="https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz"
INSTALL_DIR="/usr/local/bin"
ETC_DIR="/etc/stunnel5"
CONF_FILE="$ETC_DIR/stunnel5.conf"
PEM_FILE="$ETC_DIR/stunnel5.pem"
SYSTEMD_UNIT="/etc/systemd/system/stunnel5.service"
echo "[*] Installing dependencies ..."
apt update -y
apt install -y build-essential libssl-dev libwrap0-dev zlib1g-dev unzip wget
echo "[*] Installing stunnel5 ..."
cd /root
rm -rf "stunnel-${STUNNEL_VERSION}" "stunnel-${STUNNEL_VERSION}.tar.gz"
wget -q -O "stunnel-${STUNNEL_VERSION}.tar.gz" "$STUNNEL_URL"
tar xzf "stunnel-${STUNNEL_VERSION}.tar.gz"
cd "stunnel-${STUNNEL_VERSION}"
./configure --prefix=/usr/local
make -j$(nproc)
make install
cp /usr/local/bin/stunnel "$INSTALL_DIR/stunnel5"
chmod 755 "$INSTALL_DIR/stunnel5"
echo "[*] Setting up certificates ..."
rm -rf "$ETC_DIR"
mkdir -p "$ETC_DIR"
if [[ -f /etc/xray/xray.crt && -f /etc/xray/xray.key ]]; then
echo "[*] Found existing Xray certs, using them."
cat /etc/xray/xray.key /etc/xray/xray.crt > "$PEM_FILE"
else
echo "[*] No certs found, generating self-signed certificate ..."
openssl req -new -x509 -days 1095 -nodes \
-subj "/C=MY/ST=Selangor/L=ShahAlam/O=nexustunnelpro/OU=stunnel/CN=$(hostname -f)/emailAddress=admin@localhost" \
-out "$ETC_DIR/stunnel.crt" -keyout "$ETC_DIR/stunnel.key"
cat "$ETC_DIR/stunnel.key" "$ETC_DIR/stunnel.crt" > "$PEM_FILE"
fi
chmod 600 "$PEM_FILE"
echo "[*] Writing stunnel5.conf ..."
cat > "$CONF_FILE" <<-EOF
cert = $PEM_FILE
client = no
foreground = yes
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear-447]
accept = 447
connect = 127.0.0.1:109
[openssh-777]
accept = 777
connect = 127.0.0.1:22
[openvpn-442]
accept = 442
connect = 127.0.0.1:1194
[openssh-8181]
accept = 8181
connect = 127.0.0.1:22
EOF
echo "[*] Creating systemd service ..."
cat > "$SYSTEMD_UNIT" <<-EOF
[Unit]
Description=Stunnel5 Service
Documentation=https://stunnel.org
After=network.target
[Service]
ExecStart=$INSTALL_DIR/stunnel5 $CONF_FILE
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
echo "[*] Enabling and starting stunnel5 ..."
systemctl daemon-reload
systemctl enable stunnel5
systemctl restart stunnel5
rm -rf /root/stunnel-5.75
rm /root/stunnel-5.75.tar.gz
}
install_ddos_deflate() {
apt-get install -y cron
if [ -d '/usr/local/ddos' ]; then
echo "Please uninstall previous version first"
return
fi
mkdir -p /usr/local/ddos
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
ln -sf /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
}
setup_firewall() {
apt-get install -y iptables-persistent
for t in "get_peers" "announce_peer" "find_node" "BitTorrent" "BitTorrent protocol" "peer_id=" ".torrent" "announce.php?passkey=" "torrent" "announce" "info_hash"; do
iptables -A FORWARD -m string --string "$t" --algo bm -j DROP
done
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
}
setup_cronjobs() {
cat > /etc/cron.d/re_otm <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 2 * * * root /sbin/reboot
END
cat > /etc/cron.d/xp_otm <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * * root /usr/bin/xp
END
echo "7" > /home/re_otm
systemctl restart cron
}
cleanup_system() {
apt-get autoclean -y >/dev/null 2>&1
apt-get -y --purge remove samba* apache2* bind9* sendmail* >/dev/null 2>&1 || true
apt-get autoremove -y >/dev/null 2>&1
history -c
echo "unset HISTFILE" >> /etc/profile
rm -f /root/*.pem /root/ssh.sh /root/bbr.sh
}
restart_services() {
systemctl restart nginx || true
systemctl restart ssh || true
systemctl restart dropbear || true
systemctl restart fail2ban || true
systemctl restart vnstat || true
}
update_banner() {
wget -q -O /etc/issue.net "${SERVER_HOST}/module/issue.net"
grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config || \
echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear
}
install_depsws() {
echo "[INFO] Installing dependencies..."
apt-get update -y
apt-get install -y wget curl python3
}
install_ws_scripts() {
echo "[INFO] Downloading WebSocket scripts..."
wget -q -O /usr/local/bin/ws-dropbear "${SERVER_HOST}/module/dropbear-ws.py"
wget -q -O /usr/local/bin/ws-stunnel "${SERVER_HOST}/module/ws-stunnel"
chmod +x /usr/local/bin/ws-dropbear
chmod +x /usr/local/bin/ws-stunnel
}
install_ws_services() {
echo "[INFO] Setting up systemd services..."
wget -q -O /etc/systemd/system/ws-dropbear.service "${SERVER_HOST}/module/service-wsdropbear"
wget -q -O /etc/systemd/system/ws-stunnel.service "${SERVER_HOST}/module/ws-stunnel.service"
chmod 644 /etc/systemd/system/ws-dropbear.service
chmod 644 /etc/systemd/system/ws-stunnel.service
systemctl daemon-reload
}
enable_start_ws_services() {
echo "[INFO] Enabling and starting WebSocket services..."
for service in ws-dropbear ws-stunnel; do
systemctl enable "${service}.service"
systemctl restart "${service}.service"
systemctl --no-pager --quiet status "${service}.service" || true
done
}
mainws() {
install_depsws
install_ws_scripts
install_ws_services
enable_start_ws_services
echo ""
echo "[*] SSH WebSocket Installed Successfully!"
echo "[*] Loading..."
sleep 3
clear
}
main() {
setup_variables
set_simple_password
setup_rc_local
disable_ipv6
configure_nginx
setup_web_directories
install_badvpn
configure_ssh_dropbear
configure_stunnel
install_ddos_deflate
setup_firewall
setup_cronjobs
cleanup_system
update_banner
restart_services
echo ""
echo "[*] SSH Tunnel Installed Successfully.."
echo "[*] loadingg...."
sleep 5
clear
mainws
}
main
