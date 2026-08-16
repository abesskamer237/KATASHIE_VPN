UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • SETUP_DNS" || clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
echo "Please Wait ... Installing required packages"
REQUIRED_PACKAGES=(
curl wget dnsutils git screen whois pwgen python jq fail2ban sudo
gnutls-bin mlocate dh-make libaudit-dev build-essential dos2unix debconf-utils
)
for package in "${REQUIRED_PACKAGES[@]}"; do
if ! dpkg-query -W --showformat='${Status}
' "$package" | grep -q "install ok installed"; then
apt-get -qq install "$package" -y &>/dev/null
fi
done
clear
echo "Installing Go (golang)..."
rm -fr /usr/bin/go
wget -q --timeout=30 --tries=3 https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
rm -f /root/go1.22.0.linux-amd64.tar.gz
echo 'export PATH="/usr/local/go/bin:$PATH:/rere"' > /root/.bashrc
cd ~ || exit
source .bashrc
go version
install_slowdns() {
cd /root || exit
rm -rf /etc/slowdns
git clone https://www.bamsoftware.com/git/dnstt.git
cd dnstt/dnstt-server || exit
rm -f go.sum
go mod tidy
go build
mkdir -p /etc/slowdns
mv dnstt-server /etc/slowdns/dns-server
chmod +x /etc/slowdns/dns-server
/etc/slowdns/dns-server -gen-key \
-privkey-file /etc/slowdns/server.key \
-pubkey-file /etc/slowdns/server.pub
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo
while true; do
if [ -r /dev/tty ]; then read -r -p "  NS Domain : " -e Nameserver </dev/tty; else read -r -p "  NS Domain : " -e Nameserver; fi
if [[ -z "$Nameserver" ]]; then
echo -e "${RD}NS Domain cannot be empty. Please enter a value.${NC}"
else
break
fi
done
echo "$Nameserver" > /etc/slowdns/nsdomain
systemctl stop dnstt 2>/dev/null || true
pkill dns-server 2>/dev/null || true
rm -f /etc/systemd/system/dnstt.service
cat >/etc/systemd/system/dnstt.service <<END
[Unit]
Description=SlowDNS Service
Documentation=https://google.com
After=network.target nss-lookup.target
[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/slowdns/dns-server -udp :5300 -privkey-file /etc/slowdns/server.key $Nameserver 127.0.0.1:22
Restart=on-failure
[Install]
WantedBy=multi-user.target
END
systemctl daemon-reload
systemctl enable dnstt
systemctl start dnstt
sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config
systemctl restart ssh
}
install_firewall() {
local interface
interface=$(ip route get 8.8.8.8 | awk '/dev/ {print $5}')
iptables -I INPUT -p udp --dport 5300 -j ACCEPT &>/dev/null
iptables -t nat -I PREROUTING -i "$interface" -p udp --dport 53 -j REDIRECT --to-ports 5300
iptables-save >/etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
}
install_slowdns
install_firewall
echo ""
rm -rf /root/go /root/dnstt
echo " SlowDNS Autoscript installation completed!"
