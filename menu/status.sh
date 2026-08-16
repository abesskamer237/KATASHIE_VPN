UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
LN='[34m'
BG='[44m'
NC='[0m'
GR='[32m'
RD='[31m'
cek_service() {
local service=$1
if systemctl list-units --type=service | grep -q "$service"; then
if systemctl is-active --quiet "$service"; then
echo -e "${GR}Running${NC} (No Error)"
else
echo -e "${RD}Not Running${NC} (Error)"
fi
else
echo -e "${RD}Not Found${NC}"
fi
}
cek_openvpn() {
local instances
instances=$(systemctl list-units --type=service --no-legend | grep -o "openvpn@[^\ ]*")
if [ -n "$instances" ]; then
if systemctl is-active --quiet $instances; then
echo -e "${GR}Running${NC} (No Error)"
else
echo -e "${RD}Not Running${NC} (Error)"
fi
else
if systemctl is-active --quiet openvpn; then
echo -e "${GR}Running${NC} (No Error)"
else
echo -e "${RD}Not Running${NC} (Error)"
fi
fi
}
cek_service_init() {
local service=$1
if /etc/init.d/$service status 2>/dev/null | grep -q "running"; then
echo -e "${GR}Running${NC} (No Error)"
else
echo -e "${RD}Not Running${NC} (Error)"
fi
}
cek_badvpn() {
local port=$1
if ss -lnpt | grep -q ":$port "; then
echo -e "${GR}Running${NC} (No Error)"
else
echo -e "${RD}Not Running${NC} (Error)"
fi
}
restart_all_services() {
[ -f "$UI" ] && k_header "KATASHIE VPN • STATUS" || clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}            RESTARTING ALL SERVICES             ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
for svc in nginx ssh openvpn squid dropbear fail2ban cron vnstat; do
/etc/init.d/$svc restart >/dev/null 2>&1
echo -e "${LN}┃${NC} Restarted: $svc"
done
for svc in  udp-custom dnstt zivpn xray stunnel5 ohp ws-stunnel.service ws-dropbear.service; do
systemctl restart $svc >/dev/null 2>&1
echo -e "${LN}┃${NC} Restarted: $svc"
done
for port in 7100 7200 7300; do
systemctl restart badvpn@$port >/dev/null 2>&1
echo -e "${LN}┃${NC} Restarted: BadVPN UDP $port"
done
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return..."
status
}
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               SERVICE INFORMATION              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Nginx                      : $(cek_service_init nginx)"
echo -e "${LN}┃${NC} SSH / TUN                  : $(cek_service_init ssh)"
echo -e "${LN}┃${NC} OpenVPN                    : $(cek_openvpn)"
echo -e "${LN}┃${NC} OHP                        : $(cek_service ohp.service)"
echo -e "${LN}┃${NC} Squid Proxy                : $(cek_service_init squid)"
echo -e "${LN}┃${NC} Dropbear                   : $(cek_service_init dropbear)"
echo -e "${LN}┃${NC} Stunnel5                   : $(cek_service stunnel5)"
echo -e "${LN}┃${NC} Fail2Ban                   : $(cek_service_init fail2ban)"
echo -e "${LN}┃${NC} Crons                      : $(cek_service_init cron)"
echo -e "${LN}┃${NC} Vnstat                     : $(cek_service_init vnstat)"
echo -e "${LN}┃${NC} XRAYS                      : $(cek_service xray)"
echo -e "${LN}┃${NC} ZIVPN                      : $(cek_service zivpn)"
echo -e "${LN}┃${NC} UDP Custom                 : $(cek_service udp-custom)"
echo -e "${LN}┃${NC} SLOW DNS                   : $(cek_service dnstt)"
echo -e "${LN}┃${NC} WS Stunnel                 : $(cek_service ws-stunnel.service)"
echo -e "${LN}┃${NC} WS Dropbear                : $(cek_service ws-dropbear.service)"
echo -e "${LN}┃${NC} BadVPN UDP 7100            : $(cek_badvpn 7100)"
echo -e "${LN}┃${NC} BadVPN UDP 7200            : $(cek_badvpn 7200)"
echo -e "${LN}┃${NC} BadVPN UDP 7300            : $(cek_badvpn 7300)"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [01] Restart All Services"
echo -e "${LN}┃${NC} [00] Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -rp " Select option : " opt
case $opt in
01 | 1) restart_all_services ;;
00 | 0) menu ;;
*) echo " Invalid option"; sleep 1; status ;;
esac
