UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • NETGUARD" || clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
uninstall_netguard() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               NETGUARD UNINSTALL               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [*] Uninstalling Torrent"
echo -e "${LN}┃${NC} [*] Ads + YouTube Ads Blocker..."
if systemctl is-active --quiet blocker.service 2>/dev/null; then
systemctl stop blocker.service 2>/dev/null
fi
if systemctl is-enabled --quiet blocker.service 2>/dev/null; then
systemctl disable blocker.service 2>/dev/null
fi
rm -f /etc/systemd/system/blocker.service 2>/dev/null
systemctl daemon-reload 2>/dev/null
rm -f /usr/bin/blocker
if iptables -L TORRENT -n &>/dev/null; then
iptables -F TORRENT 2>/dev/null
iptables -X TORRENT 2>/dev/null
echo -e "${LN}┃${NC} [*] Removed TORRENT iptables rules."
fi
if grep -q "GoodbyeAds" /etc/hosts || grep -q "Thosts" /etc/hosts; then
cp /etc/hosts /etc/hosts.backup
sed -i '/GoodbyeAds/d' /etc/hosts
sed -i '/Thosts/d' /etc/hosts
echo -e "${LN}┃${NC} [*] Removed custom hosts entries."
fi
rm -f /etc/trackers
if [ -d /etc/blocker ]; then
rm -rf /etc/blocker
echo -e "${LN}┃${NC} [*] Removed /etc/blocker folder."
fi
echo -e "${LN}┃${NC} [*] Torrent uninstalled successfully"
sleep 1
echo -e "${LN}┃${NC} [*] Ads Blocker uninstalled successfully."
sleep 1
echo -e "${LN}┃${NC} [*] Netguard fully uninstalled."
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
netguard_menu
}
setup_core_file() {
echo -e "${LN}┃${NC} [**] Setting up blocker script..."
cat >/usr/bin/blocker <<'EOF'
export TORRENT_HOST="https://raw.githubusercontent.com/dotywrt/block-torrent/main"
export ADBLOCK_HOST="https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt"
export YT_ADBLOCK="https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"
export FILEHOST="https://raw.githubusercontent.com/dotywrt/block-torrent/main"
wget -q -O /etc/trackers ${FILEHOST}/domains
IFS=$'
'
L=$(/usr/bin/sort /etc/trackers | /usr/bin/uniq)
/sbin/iptables -F TORRENT 2>/dev/null
/sbin/iptables -X TORRENT 2>/dev/null
/sbin/iptables -N TORRENT 2>/dev/null
for p in {6881..6999} 6969 51413 12345; do
/sbin/iptables -A TORRENT -p tcp --dport "$p" -j DROP
/sbin/iptables -A TORRENT -p udp --dport "$p" -j DROP
done
for fn in $L; do
/sbin/iptables -A TORRENT -d "$fn" -j DROP
done
/sbin/iptables -A INPUT -j TORRENT 2>/dev/null
/sbin/iptables -A FORWARD -j TORRENT 2>/dev/null
/sbin/iptables -A OUTPUT -j TORRENT 2>/dev/null
curl -s -o /tmp/hosts_adblock "${ADBLOCK_HOST}"
curl -s -o /tmp/youtube_hosts "${YT_ADBLOCK}"
cat /tmp/hosts_adblock /tmp/youtube_hosts >> /etc/hosts
sed -i '/^#/d' /etc/hosts
sort -uf /etc/hosts > /etc/hosts.uniq && mv /etc/hosts{.uniq,}
rm -f /tmp/hosts_adblock /tmp/youtube_hosts
EOF
chmod +x /usr/bin/blocker
/usr/bin/blocker
}
systemd_blocker() {
SERVICE_FILE="/etc/systemd/system/blocker.service"
cat > "$SERVICE_FILE" <<'EOF'
[Unit]
Description=Torrent + Ads + YouTube Ads Blocker
After=network.target
[Service]
Type=oneshot
ExecStart=/usr/bin/blocker
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload 2>/dev/null
systemctl enable blocker.service 2>/dev/null
}
install_blocker() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  NETGUARD MENU                 ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [**] starting..."
sleep 2
if systemctl is-active --quiet blocker.service  2>/dev/null || systemctl is-enabled --quiet blocker.service 2>/dev/null; then
echo -e "${LN}┃${NC} [**] Blocker service already installed."
sleep 2
return
fi
echo -e "${LN}┃${NC} [**] Download Netguard Core.."
setup_core_file
sleep 2
echo -e "${LN}┃${NC} [**] Download Netguard systemd.."
systemd_blocker
echo -e "${LN}┃${NC} [**] Torrent + Ads blocking installed."
sleep 2
echo -e "${LN}┃${NC} [**] Netguard installed Successfully."
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
netguard_menu
}
netguard_menu() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  NETGUARD MENU                 ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
if systemctl is-enabled --quiet blocker.service 2>/dev/null; then
echo -e "${LN}┃${NC} Status : ${GR}Installed${NC}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [01] • Uninstall Netguard"
else
echo -e "${LN}┃${NC} Status : ${RD}Not Installed${NC}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [01] • Install Netguard"
fi
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [00] • Back To Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
echo -ne "  Choose option: "
read opt
case $opt in
01 | 1)
if systemctl is-enabled --quiet blocker.service 2>/dev/null; then
uninstall_netguard
else
install_blocker
fi
;;
00 | 0) clear ; menu ;;
*) echo "Invalid option" && sleep 1 && netguard_menu ;;
esac
}
netguard_menu
