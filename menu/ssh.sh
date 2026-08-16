UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • SSH" || clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
export DOMAIN=$(cat /etc/xray/domain);
export PUB=$(cat /etc/slowdns/server.pub)
export DNS=$(cat /etc/slowdns/nsdomain)
export MYIP=$(wget -qO- ipv4.icanhazip.com);
function create_ssh_account() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}             CREATE SSH ACCOUNT                 ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
read -p "  Enter Username          : " Login
if [[ -z "$Login" ]]; then
echo -e ""
echo -e "${RD}  [ERROR] Username cannot be empty!${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to try again..."
ssh
return
fi
if id "$Login" &>/dev/null; then
echo -e ""
echo -e "${RD}  [ERROR] Username '$Login' already exists!${NC}"
echo -e "${RD}  [INFO] Please choose a different username.${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to try again..."
ssh
return
fi
read -p "  Enter Password          : " Pass
if [[ -z "$Pass" ]]; then
echo -e ""
echo -e "${RD}  [ERROR] Password cannot be empty!${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to try again..."
ssh
return
fi
read -p "  Account Validity (days) : " DaysActive
if [[ -z "$DaysActive" ]]; then
echo -e ""
echo -e "${RD}  [ERROR] Account validity period cannot be empty!${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to try again..."
ssh
return
fi
useradd -e $(date -d "$DaysActive days" +"%Y-%m-%d") -s /bin/false -M "$Login"
exp="$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')"
echo -e "$Pass
$Pass
" | passwd "$Login" &>/dev/null
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              SSH ACCOUNT DETAILS               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username    : $Login"
echo -e "${LN}┃${NC} Password    : $Pass"
echo -e "${LN}┃${NC} Expiry Date : $exp"
echo -e "${LN}┃${NC} Host/IP     : $MYIP"
echo -e "${LN}┃${NC} Domain      : $DOMAIN"
echo -e "${LN}┃${NC} NS Domain   : $DNS"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} OpenSSH      : 22"
echo -e "${LN}┃${NC} Dropbear     : 109, 143"
echo -e "${LN}┃${NC} Stunnel      : 447, 777"
echo -e "${LN}┃${NC} WS NTLS      : 80, 8880"
echo -e "${LN}┃${NC} WS TLS       : 443"
echo -e "${LN}┃${NC} UDPGW        : 7100–7900"
echo -e "${LN}┃${NC} Squid        : 3128, 8880"
echo -e "${LN}┃${NC} OpenVPN      : TCP 1194, SSL 2200, OHP 8000"
echo -e "${LN}┃${NC} Slow DNS     : 22,53,5300,80,443"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} UDP Custom"
echo -e "${LN}┃${NC} $DOMAIN:1-65535@$Login:$Pass"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} Slow DNS"
echo -e "${LN}┃${NC} PUB : ${PUB}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} OpenVPN File"
echo -e "${LN}┃${NC} Download     : https://$DOMAIN:2081"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e "${LN}┃${NC} Payload"
echo -e "${LN}┃${NC} GET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p "  Press any key to return to the menu..."
ssh
}
function renew_ssh_account() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              RENEW SSH ACCOUNT                 ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC}  Existing SSH Accounts (Username — Expiry)"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
while IFS=: read -r user _ uid _; do
if [[ $uid -ge 1000 && "$user" != "nobody" ]]; then
exp="$(chage -l "$user" | grep "Account expires" | awk -F": " '{print $2}')"
printf "${LN}┃${NC} • %-15s %s
" "$user" "$exp"
fi
done < /etc/passwd
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
read -p "  Enter Username : " User
if [[ -z "$User" ]]; then
echo -e ""
echo -e "${RD}  [ERROR] Username cannot be empty!${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to try again..."
ssh
return
fi
if ! id "$User" &>/dev/null; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               RENEW SSH ACCOUNT                ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [ERROR] Username '$User' does not exist!${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to return to the menu..."
ssh
return
fi
read -p "  Extend for how many days : " Days
if [[ -z "$Days" || ! "$Days" =~ ^[0-9]+$ ]]; then
echo -e ""
echo -e "${RD}  [ERROR] Please enter a valid number of days!${NC}"
echo -e ""
read -n 1 -s -r -p " Press any key to try again..."
ssh
return
fi
current_exp=$(chage -l "$User" | grep "Account expires" | awk -F": " '{print $2}')
if [[ "$current_exp" == "never" ]]; then
old_date=$(date +%s)
current_exp="Never"
else
old_date=$(date -d "$current_exp +1 day" +%s)
fi
extend=$(( Days * 86400 ))
new_expire=$(( old_date + extend ))
Expiration=$(date --date="1970-01-01 $new_expire sec" +%Y-%m-%d)
Expiration_Display=$(date --date="1970-01-01 $new_expire sec" '+%d %b %Y')
passwd -u "$User" &>/dev/null
usermod -e "$Expiration" "$User" &>/dev/null
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              RENEW SSH ACCOUNT                 ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} SSH account [$User] has been renewed."
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} Username     : $User"
echo -e "${LN}┃${NC} Old Expiry   : $current_exp"
echo -e "${LN}┃${NC} Days Added   : $Days day(s)"
echo -e "${LN}┃${NC} New Expiry   : $Expiration_Display"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
ssh
}
function delete_ssh_account() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              DELETE SSH ACCOUNT                ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC}  Existing SSH Accounts (Username — Expiry)"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
while IFS=: read -r user _ uid _; do
if [[ $uid -ge 1000 && "$user" != "nobody" ]]; then
exp="$(chage -l "$user" | grep "Account expires" | awk -F": " '{print $2}')"
printf "${LN}┃${NC} • %-15s %s
" "$user" "$exp"
fi
done < /etc/passwd
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
read -p "  Enter Username : " User
if [[ -z "$User" ]]; then
echo -e ""
echo -e "${RD}  [ERROR] Username cannot be empty!${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to try again..."
ssh
return
fi
if ! id "$User" &>/dev/null; then
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              DELETE SSH ACCOUNT                ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${RD}  [ERROR] Username '$User' does not exist!${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e ""
read -n 1 -s -r -p "  Press any key to return to the menu..."
ssh
return
fi
pkill -u "$User" &>/dev/null
userdel -r "$User" &>/dev/null
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              DELETE SSH ACCOUNT                ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Username     : $User"
echo -e "${LN}┃${NC} Status       : ${GR}Deleted Successfully${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p "  Press any key to return to the menu..."
ssh
}
function list_ssh_members() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               SSH MEMBER LIST                  ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} USERNAME        EXP DATE         STATUS"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
while read expired; do
AKUN="$(echo $expired | cut -d: -f1)"
ID="$(echo $expired | cut -d: -f3)"
exp="$(chage -l $AKUN | grep "Account expires" | awk -F": " '{print $2}')"
status="$(passwd -S $AKUN | awk '{print $2}' )"
if [[ $ID -ge 1000 && "$AKUN" != "nobody" ]]; then
if [[ "$status" = "L" ]]; then
printf "  %-15s %-15s ${RD}LOCKED${NC}
" "$AKUN" "$exp"
else
printf "  %-15s %-15s ${GR}UNLOCKED${NC}
" "$AKUN" "$exp"
fi
fi
done < /etc/passwd
JUMLAH="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} Total Accounts : $JUMLAH user(s)"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to the menu..."
ssh
}
active_ssh_logins() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}          ACTIVE SSH/DROPBEAR LOGINS            ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} PID     │ Username       │ IP Address"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
if [ -e "/var/log/auth.log" ]; then
LOG="/var/log/auth.log"
elif [ -e "/var/log/secure" ]; then
LOG="/var/log/secure"
else
echo -e "${RD}  [ERROR] Log file not found!${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to menu..."
ssh
return
fi
found=0
grep -i dropbear "$LOG" | grep -i "Password auth succeeded" > /tmp/login-db.txt
for PID in $(ps aux | grep -i dropbear | awk '{print $2}'); do
grep "dropbear\[$PID\]" /tmp/login-db.txt > /tmp/login-db-pid.txt
if [ -s /tmp/login-db-pid.txt ]; then
USER=$(awk '{print $10}' /tmp/login-db-pid.txt)
IP=$(awk '{print $12}' /tmp/login-db-pid.txt)
printf "  %-7s │ %-13s │ %s
" "$PID" "$USER" "$IP"
found=1
fi
done
grep -i sshd "$LOG" | grep -i "Accepted password for" > /tmp/login-db.txt
for PID in $(ps aux | grep "\[priv\]" | awk '{print $2}'); do
grep "sshd\[$PID\]" /tmp/login-db.txt > /tmp/login-db-pid.txt
if [ -s /tmp/login-db-pid.txt ]; then
USER=$(awk '{print $9}' /tmp/login-db-pid.txt)
IP=$(awk '{print $11}' /tmp/login-db-pid.txt)
printf "  %-7s │ %-13s │ %s
" "$PID" "$USER" "$IP"
found=1
fi
done
if [[ $found -eq 0 ]]; then
echo -e "${RD}  [INFO] No active SSH/Dropbear users found.${NC}"
fi
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} End of Active Session List"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
rm -f /tmp/login-db-pid.txt /tmp/login-db.txt
read -n 1 -s -r -p " Press any key to return to the menu..."
ssh
}
function menu_ssh () {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  SSH MENU                      ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [01] • Create Account     [04] • List Accounts"
echo -e "${LN}┃${NC} [02] • Renew Account      [05] • Online Users"
echo -e "${LN}┃${NC} [03] • Delete Account"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} [00] • Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo -e   ""
read -p " Select an option:  " opt
echo -e   ""
case $opt in
1 | 01) clear ; create_ssh_account ;;
2 | 02) clear ; renew_ssh_account ;;
3 | 03) clear ; delete_ssh_account ;;
4 | 04) clear ; list_ssh_members ;;
5 | 05) clear ; active_ssh_logins ;;
0 | 00) clear ; menu ;;
*)
echo -e "${RD} [ERROR] Invalid selection!${NC}"
sleep 1
menu_ssh
;;
esac
}
menu_ssh
