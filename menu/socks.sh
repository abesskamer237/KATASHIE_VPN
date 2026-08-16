UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • SOCKS" || clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
export DOMAIN=$(cat /etc/xray/domain)
export MYIP=$(wget -qO- ipv4.icanhazip.com)
function add_socks() {
while true; do
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             ADD SHADOWSOCKS ACCOUNT              ${NC} ${LN}┃${NC}"
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
cipher="aes-128-gcm"
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")
sed -i '/#ssws$/a\#@ '"$user $exp $uuid"'\
},{"password": "'""$uuid""'","method": "'""$cipher""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#ssgrpc$/a\#@ '"$user $exp $uuid"'\
},{"password": "'""$uuid""'","method": "'""$cipher""'","email": "'""$user""'"' /etc/xray/config.json
echo -n "$cipher:$uuid" | base64 -w 0 > /tmp/ss-raw
shadowsocks_base64=$(cat /tmp/ss-raw)
ss_tls="ss://${shadowsocks_base64}@${DOMAIN}:${tls}?path=ss-ws&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}"
ss_nontls="ss://${shadowsocks_base64}@${DOMAIN}:${ntls}?path=ss-ws&security=none&host=${DOMAIN}&type=ws#${user}"
ss_grpc="ss://${shadowsocks_base64}@${DOMAIN}:${tls}?mode=gun&security=tls&type=grpc&serviceName=ss-grpc&sni=${DOMAIN}#${user}"
systemctl restart xray > /dev/null 2>&1
service cron restart > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}           SHADOWSOCKS ACCOUNT DETAILS            ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username    : ${user}"
echo -e "${LN}┃${NC} Expiry Date : ${exp}"
echo -e "${LN}┃${NC} UUID        : ${uuid}"
echo -e "${LN}┃${NC} Cipher      : ${cipher}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} Domain      : ${DOMAIN}"
echo -e "${LN}┃${NC} Port TLS    : ${tls}"
echo -e "${LN}┃${NC} Port NonTLS : ${ntls}"
echo -e "${LN}┃${NC} Port gRPC   : ${tls}"
echo -e "${LN}┃${NC} Network     : ws / grpc"
echo -e "${LN}┃${NC} Path        : /ss-ws"
echo -e "${LN}┃${NC} ServiceName : ss-grpc"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} TLS  :"
echo -e "${LN}┃${NC} ${ss_tls}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} NTLS :"
echo -e "${LN}┃${NC} ${ss_nontls}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} GRPC :"
echo -e "${LN}┃${NC} ${ss_grpc}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
}
function delete_socks() {
NUMBER_OF_CLIENTS=$(grep -c -E "^#@ " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}           DELETE SHADOWSOCKS ACCOUNT           ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e " ${RD} You don't have any existing clients!${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}            DELETE SHADOWSOCKS ACCOUNT           ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^#@ " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
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
socks
return
fi
exp=$(grep -wE "^#@ $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
if [[ -z "$exp" ]]; then
echo -e "${RD} Username not found.${NC}"
sleep 2
socks
return
fi
sed -i "/^#@ $user $exp/,/^},{/d" /etc/xray/config.json
systemctl restart xray > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}          SHADOWSOCKS ACCOUNT DELETED           ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username : ${user}"
echo -e "${LN}┃${NC} Expired  : ${exp}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
}
function view_socks() {
NUMBER_OF_CLIENTS=$(grep -c -E "^#@ " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             VIEW SHADOWSOCKS ACCOUNT           ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e " ${RD} You don't have any existing clients!${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              VIEW SHADOWSOCKS ACCOUNT           ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^#@ " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
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
socks
return
fi
exp=$(grep -wE "^#@ $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
if [[ -z "$exp" ]]; then
echo -e "${RD} Username not found.${NC}"
sleep 2
socks
return
fi
UUID=$(grep -wE "^#@ $user" "/etc/xray/config.json" | awk '{print $4}' | sort -u)
CIPHER="aes-128-gcm"
raw_ss=$(echo -n "$CIPHER:$UUID" | base64 -w 0)
ss_tls="ss://${raw_ss}@${DOMAIN}:${tls}?path=ss-ws&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}"
ss_nontls="ss://${raw_ss}@${DOMAIN}:${ntls}?path=ss-ws&security=none&host=${DOMAIN}&type=ws#${user}"
ss_grpc="ss://${raw_ss}@${DOMAIN}:${tls}?mode=gun&security=tls&type=grpc&serviceName=ss-grpc&sni=${DOMAIN}#${user}"
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                SHADOWSOCKS ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username : ${user}"
echo -e "${LN}┃${NC} Expired  : ${exp}"
echo -e "${LN}┃${NC} UUID     : ${UUID}"
echo -e "${LN}┃${NC} Cipher   : ${CIPHER}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} TLS"
echo -e "${LN}┃${NC} ${ss_tls}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} NTLS"
echo -e "${LN}┃${NC} ${ss_nontls}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} GRPC"
echo -e "${LN}┃${NC} ${ss_grpc}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
}
function socks_login() {
echo -n > /tmp/other.txt
data=( $(grep '^#@' /etc/xray/config.json | awk '{print $2}') )
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              SOCKS USER LOGIN LIST             ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
any_active=false
for user in "${data[@]}"; do
[[ -z "$user" ]] && continue
echo -n > /tmp/ipsocks.txt
data2=( $(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | awk '{print $5}' | cut -d: -f1 | sort -u) )
for ip in "${data2[@]}"; do
match=$(grep -w "$user" /var/log/xray/access.log | awk '{print $3}' | cut -d: -f1 | grep -w "$ip" | sort -u)
if [[ "$match" == "$ip" ]]; then
echo "$match" >> /tmp/ipsocks.txt
else
echo "$ip" >> /tmp/other.txt
fi
current=$(cat /tmp/ipsocks.txt)
sed -i "/$current/d" /tmp/other.txt > /dev/null 2>&1
done
current=$(cat /tmp/ipsocks.txt)
if [[ -n "$current" ]]; then
any_active=true
echo -e "${LN}┃${NC} User : ${user}"
nl /tmp/ipsocks.txt | while read line; do
echo -e "${LN}┃${NC}   $line"
done
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
fi
rm -rf /tmp/ipsocks.txt
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
echo -e "${LN}┃${NC} No active Shadowsocks users."
fi
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
rm -rf /tmp/other.txt
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
}
renew_socks() {
MYIP=$(wget -qO- ipv4.icanhazip.com)
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#@ " "/etc/xray/config.json")
if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}           RENEW SHADOWSOCKS ACCOUNT            ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
echo -e "${RD} You have no existing clients!${NC}"
echo ""
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
return
fi
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}           RENEW SHADOWSOCKS ACCOUNT            ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username        Expiry Date"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
grep -E "^#@ " "/etc/xray/config.json" | awk '{print $2, $3}' | sort -u | while read -r user exp; do
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
socks
return
fi
CLIENT_EXISTS=$(grep -wE "^#@ $user" "/etc/xray/config.json" | wc -l)
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
exp=$(grep -wE "^#@ $user" "/etc/xray/config.json" | awk '{print $3}' | sort -u)
uuid=$(grep -wE "^#@ $user" "/etc/xray/config.json" | awk '{print $4}' | sort -u)
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$(( exp2 + masaaktif ))
exp4=$(date -d "$exp3 days" +"%Y-%m-%d")
sed -i "/#@ $user/c\#@ $user $exp4 $uuid" /etc/xray/config.json
systemctl restart xray > /dev/null 2>&1
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}          SHADOWSOCKS ACCOUNT RENEWED           ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username   : ${user}"
echo -e "${LN}┃${NC} Days Added : ${masaaktif}"
echo -e "${LN}┃${NC} Expired    : ${exp4}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
socks
}
function socks_menu() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  SOCKS MENU                    ${NC} ${LN}┃${NC}"
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
1 | 01) clear ; add_socks ;;
2 | 02) clear ; renew_socks ;;
3 | 03) clear ; delete_socks ;;
4 | 04) clear ; view_socks ;;
5 | 05) clear ; socks_login ;;
0 | 00) clear ; menu ;;
*)
echo -e "${RD} [ERROR] Invalid selection!${NC}"
sleep 1
socks_menu
;;
esac
}
socks_menu
