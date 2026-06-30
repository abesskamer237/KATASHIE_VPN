clear
export DEBIAN_FRONTEND=noninteractive
export MYIP=$(wget -qO- ipinfo.io/ip)
export MYIP2="s/xxxxxxxxx/$MYIP/g"
export PORT_OVPN_TCP=1194
export PORT_OVPN_UDP=2200
export PORT_SQUID=3128
export PORT_OHP=8000
export SERVER_HOST="https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main"
export DTC=$(ip -o -4 route show to default | awk '{print $5}')
install_packages() {
rm /home/vps/public_html/*.ovpn
apt update -y && apt-get -y upgrade
apt install -y openvpn easy-rsa unzip iptables-persistent squid
}
config_squid() {
local SQUID_CONF="/etc/squid/squid.conf"
cat >"$SQUID_CONF" <<EOF
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 442
acl Safe_ports port 21 70 80 210 443 280 488 591 777 1025-65535
acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8880
http_port $PORT_SQUID
coredump_dir /var/spool/squid
visible_hostname NEXUS-TUNNEL-PRO
EOF
sed -i "$MYIP2" "$SQUID_CONF"
systemctl enable squid
systemctl restart squid
}
setup_openvpn() {
mkdir -p /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/ || exit
wget -q -O vpn.zip "${SERVER_HOST}/module/vpn.zip"
unzip -o vpn.zip && rm -f vpn.zip
chown -R root:root /etc/openvpn/server/easy-rsa/
mkdir -p /usr/lib/openvpn/
cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so \
/usr/lib/openvpn/openvpn-plugin-auth-pam.so
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
systemctl enable --now openvpn-server@server-tcp-${PORT_OVPN_TCP}
systemctl enable --now openvpn-server@server-udp-${PORT_OVPN_UDP}
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
}
make_client_conf() {
local FILE=$1
local PROTO=$2
local PORT=$3
cat > /etc/openvpn/${FILE}.ovpn <<-EOF
setenv FRIENDLY_NAME "OVPN VPN NEXUS TUNNEL PRO"
setenv CLIENT_CERT 0
client
dev tun
proto $PROTO
remote xxxxxxxxx $PORT
http-proxy xxxxxxxxx $PORT_SQUID
http-proxy-option CUSTOM-HEADER X-Forwarded-Host domain.com
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>
EOF
sed -i $MYIP2 /etc/openvpn/${FILE}.ovpn
cp /etc/openvpn/${FILE}.ovpn /home/vps/public_html/${FILE}.ovpn
}
setup_ohp() {
wget -q -O /usr/local/bin/ohp "${SERVER_HOST}/module/ohp"
chmod +x /usr/local/bin/ohp
cat > /etc/openvpn/client-ohp.ovpn <<-EOF
setenv FRIENDLY_NAME "OHP VPN NEXUS TUNNEL PRO"
setenv CLIENT_CERT 0
client
dev tun
proto tcp
remote bug.com 443
http-proxy $MYIP $PORT_OHP
http-proxy-option CUSTOM-HEADER "X-Forwarded-Host bug.com"
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>
EOF
sed -i $MYIP2 /etc/openvpn/client-ohp.ovpn
cp /etc/openvpn/client-ohp.ovpn /home/vps/public_html/client-ohp.ovpn
cat > /etc/systemd/system/ohp.service <<-EOF
[Unit]
Description=Proxy Squid
Documentation=${host}
Wants=network.target
After=network.target
[Service]
ExecStart=/usr/local/bin/ohp -port $PORT_OHP -proxy 127.0.0.1:$PORT_SQUID -tunnel 127.0.0.1:$PORT_OVPN_TCP
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ohp
systemctl restart ohp
}
setup_iptables() {
iptables -t nat -I POSTROUTING -s 10.6.0.0/24 -o $DTC -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.7.0.0/24 -o $DTC -j MASQUERADE
iptables-save > /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
}
finalize() {
systemctl restart openvpn
history -c
rm /root/vpn.sh
}
install_packages
config_squid
setup_openvpn
make_client_conf client-tcp-1194 tcp ${PORT_OVPN_TCP}
make_client_conf client-udp-2200 udp ${PORT_OVPN_UDP}
make_client_conf client-tcp-ssl tcp ${PORT_OVPN_TCP}
setup_ohp
setup_iptables
finalize
