UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • DOMAIN" || clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
export DOMAIN=$(cat /etc/xray/domain)
export MYIP=$(wget -qO- ipv4.icanhazip.com)
function add_domain() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo
while true; do
read -rp " Hostname / Domain: " host
if [[ -z "$host" ]]; then
echo -e " ${RD}Domain cannot be empty. Please try again.${NC}"
continue
fi
domain_ip=$(getent ahosts "$host" | awk '{print $1; exit}')
if [[ "$domain_ip" == "$MYIP" ]]; then
break
else
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${RD}✘ Domain does not point to this VPS!${NC}"
echo -e "${LN}┃${NC} ${RD}Domain resolves to: $domain_ip ${NC}"
echo -e "${LN}┃${NC} ${RD}VPS public IP is : $MYIP ${NC}"
echo -e "${LN}┃${NC} ${RD}Please fix your DNS settings and try again.${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
domain
return
fi
done
echo "$host" > /root/domain
echo "$host" > /etc/xray/domain
if [[ -f /root/domain ]]; then
domain=$(cat /root/domain)
elif [[ -f /etc/xray/domain ]]; then
domain=$(cat /etc/xray/domain)
else
echo -e "${LN}┃${NC} Domain file not found!"
exit 1
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Domain has been set successfully!"
echo -e "${LN}┃${NC} Current Domain: ${domain}"
echo -e "${LN}┃${NC}                                                            "
echo -e "${LN}┃${NC} AutoScript Xray by 🜲 DOTYWRT V1.0"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} [01] • Change Domain   [02] • Renew Certificate"
echo -e "${LN}┃${NC} "
echo -e "${LN}┃${NC} [00] • Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -p "  Select an option : " opt
echo ""
case $opt in
1 | 01) clear ; add_domain ;;
2 | 02) clear ; renew_cert ;;
0 | 00) clear ; menu ;;
*)
echo -e "${RD} [ERROR] Invalid selection!${NC}"
sleep 1
domain
;;
esac
}
function renew_cert() {
clear
if [[ -f /root/domain ]]; then
domain=$(cat /root/domain)
elif [[ -f /etc/xray/domain ]]; then
domain=$(cat /etc/xray/domain)
else
echo -e "${LN}┃${NC} Domain file not found!"
exit 1
fi
systemctl stop nginx &> /dev/null
systemctl stop xray &> /dev/null
Cek=$(lsof -i:80 | awk 'NR==2 {print $1}')
sleep 1
systemctl stop $Cek &> /dev/null
mkdir -p /usr/bin/xray
mkdir -p /etc/xray
mkdir -p /usr/local/etc/xray
if [ ! -f "/root/.acme.sh/acme.sh" ]; then
echo -e "${LN}┃${NC} acme.sh not found, downloading...${NC}"
curl https://get.acme.sh | sh
else
echo -e "${LN}┃${NC} acme.sh found, skipping installation.${NC}"
fi
alias acme.sh=~/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d "${domain}" --standalone --keylength ec-256
/root/.acme.sh/acme.sh --install-cert -d "${domain}" --ecc \
--fullchain-file /etc/xray/xray.crt \
--key-file /etc/xray/xray.key
chown -R nobody:nogroup /etc/xray
chmod 644 /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key
systemctl start nginx &> /dev/null
systemctl start xray &> /dev/null
systemctl start $Cek &> /dev/null
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} SSL Certificate has been issued successfully!"
echo -e "${LN}┃${NC} Domain       : ${domain}"
echo -e "${LN}┃${NC} Cert File    : /etc/xray/xray.crt"
echo -e "${LN}┃${NC} Key File     : /etc/xray/xray.key"
echo -e "${LN}┃${NC}                                                            "
echo -e "${LN}┃${NC} AutoScript Xray by 🜲 DOTYWRT V1.0"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
domain
}
function domain() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [01] • Change Domain   [02] • Renew Certificate"
echo -e "${LN}┃${NC} "
echo -e "${LN}┃${NC} [00] • Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -p "  Select an option : " opt
echo ""
case $opt in
1 | 01) clear ; add_domain ;;
2 | 02) clear ; renew_cert ;;
0 | 00) clear ; menu ;;
*)
echo -e "${RD} [ERROR] Invalid selection!${NC}"
sleep 1
domain
;;
esac
}
domain
