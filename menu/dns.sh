UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
show_current_dns() {
current_dns=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}' | xargs)
if [[ -z "$current_dns" ]]; then
current_dns="No DNS configured"
fi
echo -e "${LN}┃${NC} Current Active DNS : ${GR}${current_dns}${NC}"
echo -e "${LN}┃${NC}"
}
apply_dns() {
if systemctl is-active --quiet systemd-resolved; then
if [ -L /etc/resolv.conf ]; then
sudo unlink /etc/resolv.conf
fi
echo -e "nameserver $dns1
nameserver $dns2" | sudo tee /etc/resolv.conf > /dev/null
sudo systemctl restart systemd-resolved
else
echo -e "nameserver $dns1
nameserver $dns2" | sudo tee /etc/resolv.conf > /dev/null
fi
}
dns_menu() {
[ -f "$UI" ] && k_header "KATASHIE VPN • DNS" || clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                   DNS PANEL                    ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
show_current_dns
echo -e "${LN}┃${NC} [01] • Google DNS           [04] • Quad9 DNS"
echo -e "${LN}┃${NC} [02] • Cloudflare DNS       [05] • AdGuard Default"
echo -e "${LN}┃${NC} [03] • OpenDNS              [06] • AdGuard Family"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [99] • Custom DNS"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [00] • Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -rp " Select DNS Provider : " opt
case $opt in
1 |01) dns1="8.8.8.8"; dns2="8.8.4.4"; provider="Google DNS" ;;
2 |02) dns1="1.1.1.1"; dns2="1.0.0.1"; provider="Cloudflare DNS" ;;
3 |03) dns1="208.67.222.222"; dns2="208.67.220.220"; provider="OpenDNS" ;;
4 |04) dns1="9.9.9.9"; dns2="149.112.112.112"; provider="Quad9" ;;
5 |05) dns1="94.140.14.14"; dns2="94.140.15.15"; provider="AdGuard Default" ;;
6 |06) dns1="94.140.14.15"; dns2="94.140.15.16"; provider="AdGuard Family" ;;
99)
read -rp " Enter Primary DNS  : " dns1
read -rp " Enter Secondary DNS: " dns2
provider="Custom DNS"
;;
0 |00) clear ; menu ;;
*)
echo ""
echo -e " ${RD}[ERROR] Invalid option!${NC}"
sleep 2
dns_menu
;;
esac
apply_dns
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                   DNS PANEL                    ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} DNS has been set successfully!"
echo -e "${LN}┃${NC} Provider     : ${provider}"
echo -e "${LN}┃${NC} Primary DNS  : ${dns1}"
echo -e "${LN}┃${NC} Secondary DNS: ${dns2}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} AutoScript Xray by 🜲 DOTYWRT V1.0"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
dns_menu
}
dns_menu
