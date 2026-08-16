UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
export YL='[33m'
check_ipv6_status() {
status=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)
if [[ "$status" == "0" ]]; then
ipv6_status="${GR}ENABLED${NC}"
else
ipv6_status="${RD}DISABLED${NC}"
fi
}
set_ipv6() {
if [[ "$1" == "on" ]]; then
sudo sed -i '/^net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
sudo sed -i '/^net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 0" | sudo tee -a /etc/sysctl.conf >/dev/null
echo "net.ipv6.conf.default.disable_ipv6 = 0" | sudo tee -a /etc/sysctl.conf >/dev/null
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null
elif [[ "$1" == "off" ]]; then
sudo sed -i '/^net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
sudo sed -i '/^net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf >/dev/null
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf >/dev/null
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null
fi
}
ipv6_menu() {
while true; do
check_ipv6_status
[ -f "$UI" ] && k_header "KATASHIE VPN • IPTOOLS" || clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                   IPv6 PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Current IPv6 Status : ${ipv6_status}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [01] • Enable IPv6        [02] • Disable IPv6"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [00] • Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -rp " Select Option : " opt
case $opt in
1 |01)
set_ipv6 "on"
msg="IPv6 has been ENABLED successfully!"
;;
2 |02)
set_ipv6 "off"
msg="IPv6 has been DISABLED successfully!"
;;
0 |00) clear ; menu ;;
*)
echo ""
echo -e " ${RD}[ERROR] Invalid option!${NC}"
sleep 2
continue
;;
esac
check_ipv6_status
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                   IPv6 PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${msg}"
echo -e "${LN}┃${NC} Current Status : ${ipv6_status}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} AutoScript Xray by 🜲 DOTYWRT V1.0"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to IPv6 Menu..."
done
}
ipv6_menu
