clear
RED='[31m'
GREEN='[32m'
BLUE='[34m'
NC='[0m'
export SERVER_HOST="https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main"
update_system() {
echo -e "${BLUE}Updating server...${NC}"
sudo apt-get update && sudo apt-get upgrade -y
}
stop_service() {
echo -e "${BLUE}Stopping existing ZIVPN service...${NC}"
if systemctl is-active --quiet zivpn.service; then
systemctl stop zivpn.service
fi
}
download_udp_service() {
echo -e "${BLUE}Downloading ZIVPN UDP service...${NC}"
wget -q https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn
mkdir -p /etc/zivpn
touch /etc/zivpn/user.db
wget -q -O /etc/zivpn/config.json "${SERVER_HOST}/module/zvpn.json"
}
generate_certificates() {
echo -e "${BLUE}Generating certificate files...${NC}"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
-subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
-keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
sysctl -w net.core.rmem_max=16777216 &> /dev/null
sysctl -w net.core.wmem_max=16777216 &> /dev/null
}
create_systemd_service() {
echo -e "${BLUE}Creating systemd service...${NC}"
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP VPN Server
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
EOF
}
enable_and_start_service() {
echo -e "${BLUE}Enabling and starting ZIVPN service...${NC}"
systemctl daemon-reload
systemctl enable zivpn.service
systemctl start zivpn.service
}
configure_firewall() {
echo -e "${BLUE}Configuring firewall rules...${NC}"
local iface
iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
}
touchfile() {
touch /etc/zivpn/user.db
}
cleanup() {
rm -f setup_zivpn.* &> /dev/null
}
main() {
update_system
stop_service
download_udp_service
generate_certificates
create_systemd_service
enable_and_start_service
configure_firewall
touchfile
cleanup
echo -e "${GREEN}ZIVPN UDP installed successfully!${NC}"
}
main
