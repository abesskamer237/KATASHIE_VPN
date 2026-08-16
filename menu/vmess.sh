UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • VMESS" || clear
readonly LN='[34m'
readonly BG='[44m'
readonly NC='[0m'
readonly GR='[32m'
readonly RD='[31m'
readonly DOMAIN=$(cat /etc/xray/domain)
readonly MYIP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
function add_vmess() {
while true; do
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                ADD VMESS ACCOUNT               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
read -rp "  Enter username: " -e user
if [[ -z "$user" ]]; then
echo -e ""
echo -e " ${RD}Username cannot be empty. Please try again.${NC}"
continue
fi
if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
echo -e ""
echo -e " ${RD}Username may only contain letters, numbers, and underscores.${NC}"
continue
fi
CLIENT_EXISTS=$(grep -w "$user" /etc/xray/config.json | wc -l)
if [[ "$CLIENT_EXISTS" -gt 0 ]]; then
echo -e ""
echo -e " ${RD}This username already exists. Please choose another one.${NC}"
echo -e ""
read -n 1 -s -r -p " Press any key to try again..."
clear
continue
fi
break
done
while true; do
read -p "  Validity (days): " masaaktif
if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
echo -e ""
echo -e "${RD}Expiry days must be a positive number. Please try again.${NC}"
echo -e ""
continue
fi
break
done
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
sed -i '/#vmess$/a\### '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
sed -i '/#vmessgrpc$/a\### '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json
ws_tls=$(cat<<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${uuid}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}
EOF
)
ws_nontls=$(cat<<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"80","id":"${uuid}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"none"}
EOF
)
grpc=$(cat<<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${uuid}","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"","tls":"tls"}
EOF
)
vmesslink1="vmess://$(echo $ws_tls | base64 -w 0)"
vmesslink2="vmess://$(echo $ws_nontls | base64 -w 0)"
vmesslink3="vmess://$(echo $grpc | base64 -w 0)"
systemctl restart xray > /dev/null 2>&1
service cron restart > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              VMESS ACCOUNT DETAILS             ${NC} ${LN}┃${NC}"
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
echo -e "${LN}┃${NC} alterId     : 0"
echo -e "${LN}┃${NC} Security    : auto"
echo -e "${LN}┃${NC} Network     : ws"
echo -e "${LN}┃${NC} Path        : /vmess"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} Custom Path Info "
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} TLS         : $(grep -w "VMESS CUSTOM TLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')"
echo -e "${LN}┃${NC} NTLS        : $(grep -w "VMESS CUSTOM NTLS" /etc/xray/port_info | cut -d: -f2 | tr -d ' ')"
echo -e "${LN}┃${NC} PATH        : / OR /<anytext>"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} TLS  : "
echo -e "${LN}┃${NC} ${vmesslink1}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} NTLS : "
echo -e "${LN}┃${NC} ${vmesslink2}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} GRPC : "
echo -e "${LN}┃${NC} ${vmesslink3}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
}
function renew_vmess() {
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               RENEW VMESS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
echo -e "${RD} You have no existing clients!${NC}"
echo ""
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               RENEW VMESS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^### " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
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
vmess
return
fi
CLIENT_EXISTS=$(grep -wE "^### $user" "/etc/xray/config.json" | wc -l)
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
exp=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
uuid=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $4}' | sort -u)
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$(( exp2 + masaaktif ))
exp4=$(date -d "$exp3 days" +"%Y-%m-%d")
sed -i "/### $user/c\### $user $exp4 $uuid" /etc/xray/config.json
systemctl restart xray > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             VMESS ACCOUNT RENEWED              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username   : ${user}"
echo -e "${LN}┃${NC} Days Added : ${masaaktif}"
echo -e "${LN}┃${NC} Expired    : ${exp4}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
}
function delete_vmess() {
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             DELETE VMESS ACCOUNT             ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e " ${RD} You don't have any existing clients!${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              DELETE VMESS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^### " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
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
vmess
return
fi
exp=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
if [[ -z "$exp" ]]; then
echo -e "${RD} Username not found.${NC}"
sleep 2
vmess
return
fi
sed -i "/^### $user $exp/,/^},{/d" /etc/xray/config.json
systemctl restart xray > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             VMESS ACCOUNT DELETED              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username : ${user}"
echo -e "${LN}┃${NC} Expired  : ${exp}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
}
function vmess_login() {
echo -n > /tmp/other.txt
data=( $(grep '^####' /etc/xray/config.json | awk '{print $2}') )
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             VMESS USER LOGIN LIST              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
any_active=false
for user in "${data[@]}"; do
[[ -z "$user" ]] && continue
echo -n > /tmp/ipvmess.txt
data2=( $(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | awk '{print $5}' | cut -d: -f1 | sort -u) )
for ip in "${data2[@]}"; do
match=$(grep -w "$user" /var/log/xray/access.log | awk '{print $3}' | cut -d: -f1 | grep -w "$ip" | sort -u)
if [[ "$match" == "$ip" ]]; then
echo "$match" >> /tmp/ipvmess.txt
else
echo "$ip" >> /tmp/other.txt
fi
current=$(cat /tmp/ipvmess.txt)
sed -i "/$current/d" /tmp/other.txt > /dev/null 2>&1
done
current=$(cat /tmp/ipvmess.txt)
if [[ -n "$current" ]]; then
any_active=true
echo -e "${LN}┃${NC} User : ${user}"
nl /tmp/ipvmess.txt | while read line; do
echo -e "${LN}┃${NC}   $line"
done
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
fi
rm -rf /tmp/ipvmess.txt
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
echo -e "${LN}┃${NC} No active VMess users."
fi
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
rm -rf /tmp/other.txt
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
}
function view_config() {
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              VIEW VMESS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e " ${RD} You don't have any existing clients!${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               VIEW VMESS ACCOUNT               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^### " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
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
vmess
return
fi
exp=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
if [[ -z "$exp" ]]; then
echo -e "${RD} Username not found.${NC}"
sleep 2
vmess
return
fi
UUID=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $4}' | sort -u)
EXP=$(grep -wE "^### $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
ws_tls=$(cat<<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${UUID}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}
EOF
)
ws_nontls=$(cat<<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"80","id":"${UUID}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"none"}
EOF
)
grpc=$(cat<<EOF
{"v":"2","ps":"${user}","add":"${DOMAIN}","port":"443","id":"${UUID}","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"","tls":"tls"}
EOF
)
vmesslink1="vmess://$(echo $ws_tls | base64 -w 0)"
vmesslink2="vmess://$(echo $ws_nontls | base64 -w 0)"
vmesslink3="vmess://$(echo $grpc | base64 -w 0)"
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                 VMESS ACCOUNT                  ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username : ${user}"
echo -e "${LN}┃${NC} Expired  : ${exp}"
echo -e "${LN}┃${NC} UUID     : ${UUID}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} TLS "
echo -e "${LN}┃${NC} ${vmesslink1}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} NTLS"
echo -e "${LN}┃${NC} ${vmesslink2}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} GRPC "
echo -e "${LN}┃${NC} ${vmesslink3}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
vmess
}
function vmess_menu() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  VMESS MENU                    ${NC} ${LN}┃${NC}"
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
1 | 01) clear ; add_vmess ;;
2 | 02) clear ; renew_vmess ;;
3 | 03) clear ; delete_vmess ;;
4 | 04) clear ; view_config ;;
5 | 05) clear ; vmess_login ;;
0 | 00) clear ; menu ;;
*)
echo -e "${RD} [ERROR] Invalid selection!${NC}"
sleep 1
vmess_menu
;;
esac
}
vmess_menu
