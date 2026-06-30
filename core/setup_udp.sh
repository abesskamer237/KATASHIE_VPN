clear
export SERVER_HOST="https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main"
export UDP_DIR="/etc/udp-custom"
export SERVICE_FILE="/etc/systemd/system/udp-custom.service"
update_system() {
apt update -y && apt upgrade -y
apt install -y wget unzip
}
install_udp_custom() {
rm -rf "$UDP_DIR"
mkdir -p "$UDP_DIR"
wget -q "${SERVER_HOST}/module/udp-custom-linux-amd64" -O "$UDP_DIR/udp-custom"
chmod +x "$UDP_DIR/udp-custom"
wget -q "${SERVER_HOST}/module/udp_config.json" -O "$UDP_DIR/config.json"
chmod 644 "$UDP_DIR/config.json"
}
create_service() {
local exclude_arg=""
[ -n "$1" ] && exclude_arg="-exclude $1"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=UDP Custom by ePro Dev. Team
[Service]
User=root
Type=simple
ExecStart=$UDP_DIR/udp-custom server $exclude_arg
WorkingDirectory=$UDP_DIR
Restart=always
RestartSec=2s
[Install]
WantedBy=multi-user.target
EOF
}
start_service() {
systemctl daemon-reload
systemctl enable udp-custom &>/dev/null
systemctl restart udp-custom &>/dev/null
}
update_system
install_udp_custom
create_service "$1"
start_service
