UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • VLESS" || clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
export DOMAIN=$(cat /etc/xray/domain)
export MYIP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
function add_vless() {
clear
while true; do
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                ADD VLESS ACCOUNT               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -rp "  Enter username: " -e user
if [[ -z "$user" ]]; then
echo -e " ${RD}Username cannot be empty. Please try again.${NC}"
continue
fi
if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
echo -e " ${RD}Username may only contain letters, numbers, and underscores.${NC}"
continue
fi
CLIENT_EXISTS=$(grep -w "$user" /etc/xray/config.json | wc -l)
if [[ "$CLIENT_EXISTS" -gt 0 ]]; then
echo -e " ${RD}This username already exists. Please choose another one.${NC}"
read -n 1 -s -r -p " Press any key to try again..."
clear
continue
fi
break
done
while true; do
read -rp "  Validity (days): " masaaktif
if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
echo -e " ${RD}Expiry days must be a positive number. Please try again.${NC}"
continue
fi
break
done
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
sed -i '/#vless$/a\#& '"$user $exp $uuid"'\
},{"id": "'"$uuid"'","email": "'"$user"'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#& '"$user $exp $uuid"'\
},{"id": "'"$uuid"'","email": "'"$user"'"' /etc/xray/config.json
export DOMAIN=$(cat /etc/xray/domain)
vlesslink1="vless://${uuid}@${DOMAIN}:443?path=/vless&security=tls&encryption=none&type=ws#${user}"
vlesslink2="vless://${uuid}@${DOMAIN}:80?path=/vless&encryption=none&type=ws#${user}"
vlesslink3="vless://${uuid}@${DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc#${user}"
systemctl restart xray
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              VLESS ACCOUNT DETAILS             ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username    : ${user}"
echo -e "${LN}┃${NC} Expiry Date : ${exp}"
echo -e "${LN}┃${NC} UUID        : ${uuid}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} Domain      : ${DOMAIN}"
echo -e "${LN}┃${NC} Port TLS    : 443"
echo -e "${LN}┃${NC} Port NonTLS : 80"
echo -e "${LN}┃${NC} Port gRPC   : 443"
echo -e "${LN}┃${NC} Security    : auto"
echo -e "${LN}┃${NC} Network     : ws"
echo -e "${LN}┃${NC} Path        : /vless"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} Custom Path Info "
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} TLS         : $(grep -w "VLESS CUSTOM TLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')"
echo -e "${LN}┃${NC} NTLS        : $(grep -w "VLESS CUSTOM NTLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')"
echo -e "${LN}┃${NC} PATH        : / OR /<anytext>"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} TLS  : "
echo -e "${LN}┃${NC} ${vlesslink1}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} NTLS : "
echo -e "${LN}┃${NC} ${vlesslink2}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} GRPC : "
echo -e "${LN}┃${NC} ${vlesslink3}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless_menu
}
function renew_vless() {
MYIP=$(wget -qO- ipv4.icanhazip.com)
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#& " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               RENEW VLESS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} ${RD}You have no existing clients!${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              RENEW VLESS ACCOUNT               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^#& " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
printf "${LN}┃${NC} %-18s %s
" "$user" "$exp"
done
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} Press Enter to go back"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
while true; do
read -rp "  Input Username : " user
if [[ -z "$user" ]]; then
vless
return
fi
CLIENT_EXISTS=$(grep -wE "^#& $user" "/etc/xray/config.json" | wc -l)
if [[ $CLIENT_EXISTS -eq 0 ]]; then
echo -e "${RD} Username not found. Please try again.${NC}"
continue
fi
break
done
while true; do
read -p "  Expired (days): " masaaktif
if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
echo -e "${RD} Expiry days must be a positive number.${NC}"
continue
fi
break
done
exp=$(grep -wE "^#& $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
uuid=$(grep -wE "^#& $user" /etc/xray/config.json | awk '{print $4}' | grep -v '^[[:space:]]*$' | sort -u)
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$(( exp2 + masaaktif ))
exp4=$(date -d "$exp3 days" +"%Y-%m-%d")
sed -i "/^#& $user /c\#& $user $exp4 $uuid" /etc/xray/config.json
systemctl restart xray > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              VLESS ACCOUNT RENEWED             ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username   : ${user}"
echo -e "${LN}┃${NC} UUID       : ${uuid}"
echo -e "${LN}┃${NC} Days Added : ${masaaktif}"
echo -e "${LN}┃${NC} Expired    : ${exp4}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless
}
function delete_vless() {
NUMBER_OF_CLIENTS=$(grep -c -E "^#& " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              DELETE VLESS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} ${RD}You don't have any existing clients!${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless_menu
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              DELETE VLESS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^#& " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
printf "${LN}┃${NC} %-18s %s
" "$user" "$exp"
done
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} Press Enter to go back"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
read -rp " Input Username : " duser
if [[ -z $duser ]]; then
vless_menu
return
fi
exp=$(grep -wE "^#& $duser" "/etc/xray/config.json" | cut -d ' ' -f 3 | sort | uniq)
if [[ -z "$exp" ]]; then
echo -e "${RD} Username not found.${NC}"
sleep 2
vless_menu
return
fi
uuid=$(grep -wE "^#& $duser" "/etc/xray/config.json" | cut -d ' ' -f 3 | sort | uniq)
sed -i -e "/^#& $duser /d" -e "/\"email\": \"$duser\"/d" /etc/xray/config.json
systemctl restart xray > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             VLESS ACCOUNT DELETED              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username : ${duser}"
echo -e "${LN}┃${NC} Expired  : ${exp}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless_menu
}
function view_vless() {
NUMBER_OF_CLIENTS=$(grep -c -E "^#& " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               VIEW VLESS ACCOUNT               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e " ${RD} You don't have any existing clients!${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               VIEW VLESS ACCOUNT               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^#& " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
printf "${LN}┃${NC} %-18s %s
" "$user" "$exp"
done
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} Press Enter to go back"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
read -rp " Input Username : " user
if [[ -z $user ]]; then
vless
return
fi
exp=$(grep -wE "^#& $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
if [[ -z "$exp" ]]; then
echo -e "${RD} Username not found.${NC}"
sleep 2
vless
return
fi
UUID=$(grep -wE "^#& $user" "/etc/xray/config.json" | awk '{print $4}' | sort -u)
EXP=$(grep -wE "^#& $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
vlesslink1="vless://${UUID}@${DOMAIN}:443?path=/vless&security=tls&encryption=none&type=ws#${user}"
vlesslink2="vless://${UUID}@${DOMAIN}:80?path=/vless&encryption=none&type=ws#${user}"
vlesslink3="vless://${UUID}@${DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc#${user}"
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 VLESS ACCOUNT                  ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username : ${user}"
echo -e "${LN}┃${NC} Expired  : ${exp}"
echo -e "${LN}┃${NC} UUID     : ${UUID}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} TLS (443) "
echo -e "${LN}┃${NC} ${vlesslink1}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} NTLS (80)"
echo -e "${LN}┃${NC} ${vlesslink2}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} GRPC (443)"
echo -e "${LN}┃${NC} ${vlesslink3}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless
}
function vless_login() {
echo -n > /tmp/other.txt
data=( $(grep '^#&' /etc/xray/config.json | awk '{print $2}') )
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             VLESS USER LOGIN LIST              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
any_active=false
for user in "${data[@]}"; do
[[ -z "$user" ]] && continue
echo -n > /tmp/ipvless.txt
data2=( $(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | awk '{print $5}' | cut -d: -f1 | sort -u) )
for ip in "${data2[@]}"; do
match=$(grep -w "$user" /var/log/xray/access.log | awk '{print $3}' | cut -d: -f1 | grep -w "$ip" | sort -u)
if [[ "$match" == "$ip" ]]; then
echo "$match" >> /tmp/ipvless.txt
else
echo "$ip" >> /tmp/other.txt
fi
current=$(cat /tmp/ipvless.txt)
sed -i "/$current/d" /tmp/other.txt > /dev/null 2>&1
done
current=$(cat /tmp/ipvless.txt)
if [[ -n "$current" ]]; then
any_active=true
echo -e "${LN}┃${NC} User : ${user}"
nl /tmp/ipvless.txt | while read line; do
echo -e "${LN}┃${NC}   $line"
done
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
fi
rm -rf /tmp/ipvless.txt
done
oth=$(sort -u /tmp/other.txt | nl)
if [[ -n "$oth" ]]; then
any_active=true
echo -e "${LN}┃${NC} Other Connections:"
echo "$oth" | while read line; do
echo -e "${LN}┃${NC}   $line"
done
fi
if [[ "$any_active" == false ]]; then
echo -e "${LN}┃${NC} No active VLESS users."
fi
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
rm -rf /tmp/other.txt
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vless
}
function vless_menu() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  VLESS MENU                    ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [01] • Create Account      [04] • List Accounts"
echo -e "${LN}┃${NC} [02] • Extend Account      [05] • Active Users"
echo -e "${LN}┃${NC} [03] • Delete Account"
echo -e "${LN}┃${NC} "
echo -e "${LN}┃${NC} [00] • Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -p "  Select menu : " opt
echo ""
case $opt in
1 | 01) clear ; add_vless ;;
2 | 02) clear ; renew_vless ;;
3 | 03) clear ; delete_vless ;;
4 | 04) clear ; view_vless ;;
5 | 05) clear ; vless_login ;;
0 | 00) clear ; menu ;;
*)
echo -e "${RD} [ERROR] Invalid selection!${NC}"
sleep 1
vless_menu
;;
esac
}
vless_menu
