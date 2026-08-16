UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • ZIVPN" || clear
export LN='[34m'
export BG='[44m'
export NC='[0m'
export GR='[32m'
export RD='[31m'
export DOMAIN=$(cat /etc/xray/domain)
export MYIP=$(wget -qO- ipv4.icanhazip.com)
add_zivpn() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}               ADD ZIVPN ACCOUNT                ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
while true; do
read -rp "  Enter username: " user
if [[ -z "$user" ]]; then
echo -e "  ${RD}Username cannot be empty.${NC}"
continue
fi
if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
echo -e "  ${RD}Invalid username (letters, numbers, underscore only).${NC}"
continue
fi
if grep -qw "$user" /etc/zivpn/user.db; then
echo -e "  ${RD}Username already exists.${NC}"
continue
fi
break
done
while true; do
read -rp "  Enter password: " pass
if [[ -z "$pass" ]]; then
echo -e "  ${RD}Password cannot be empty.${NC}"
continue
fi
if grep -qw "$pass" /etc/zivpn/user.db || grep -qw "\"$pass\"" /etc/zivpn/config.json; then
echo -e "  ${RD}Password already in use.${NC}"
continue
fi
break
done
while true; do
read -rp "  Validity (days): " days
if [[ -z "$days" || ! "$days" =~ ^[0-9]+$ || "$days" -le 0 ]]; then
echo -e "  ${RD}Expiry days must be a positive number.${NC}"
continue
fi
break
done
exp=$(date -d "+$days days" +"%Y-%m-%d")
sed -i '/"config": \[/a\      "'"$pass"'",' /etc/zivpn/config.json
sed -i ':a;N;$!ba;s/,
[ 	]*]/
    ]/' /etc/zivpn/config.json
sed -i "1i$user $pass $exp" /etc/zivpn/user.db
systemctl restart zivpn
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  ZIVPN ACCOUNT                 ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC}  ${GREEN}User $user added successfully!${NC}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC}  IPV4      : $MYIP"
echo -e "${LN}┃${NC}  Domain    : $DOMAIN"
echo -e "${LN}┃${NC}  Password  : $pass"
echo -e "${LN}┃${NC}  Expiry    : $exp"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p " Press any key to return to menu..."
menu_zivpn
}
del_zivpn() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              DELETE ZIVPN ACCOUNT              ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
if [[ ! -s /etc/zivpn/user.db ]]; then
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [**] ${RD}No users found.${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p "  Press any key to return..."
menu_zivpn
fi
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
printf "${LN}┃ %-5s %-15s %-15s %-10s ${NC}
" "No." "Username" "Password" "Expiry"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
i=1
while read -r line; do
username=$(echo "$line" | awk '{print $1}')
password=$(echo "$line" | awk '{print $2}')
expiry=$(echo "$line" | awk '{print $3}' | tr -d '
')
printf "${LN}┃ %-5s %-15s %-15s %-10s ${NC}
" "$i" "$username" "$password" "$expiry"
((i++))
done < /etc/zivpn/user.db
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -rp "  Enter username to delete: " user
if [[ -z "$user" ]]; then
echo -e "  [**] ${RD}Username cannot be empty.${NC}"
menu_zivpn
fi
line=$(awk -v u="$user" '$1==u {print; exit}' /etc/zivpn/user.db)
if [[ -z "$line" ]]; then
echo -e "  [**] ${RD}Username '$user' not found.${NC}"
read -n 1 -s -r -p "  Press any key..."
menu_zivpn
fi
pass=$(echo "$line" | awk '{print $2}')
sed -i "/\"$pass\"/d" /etc/zivpn/config.json
sed -i "/^$user /d" /etc/zivpn/user.db
systemctl restart zivpn
echo -e "  [**] ${GREEN}User $user deleted successfully.${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p "  Press any key to return to menu..."
menu_zivpn
}
renew_zivpn() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}              RENEW ZIVPN ACCOUNT               ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
if [[ ! -s /etc/zivpn/user.db ]]; then
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [**] ${RD}No users found.${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p "  Press any key to return..."
menu_zivpn
fi
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
printf "${LN}┃ %-5s %-15s %-15s %-10s ${NC}
" "No." "Username" "Password" "Expiry"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
i=1
while read -r line; do
username=$(echo "$line" | awk '{print $1}')
password=$(echo "$line" | awk '{print $2}')
expiry=$(echo "$line" | awk '{print $3}' | tr -d '
')
printf "${LN}┃ %-5s %-15s %-15s %-10s ${NC}
" "$i" "$username" "$password" "$expiry"
((i++))
done < /etc/zivpn/user.db
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo ""
read -rp "  Enter username to renew: " user
if [[ -z "$user" ]]; then
echo -e "  ${RD}Username cannot be empty.${NC}"
menu_zivpn
fi
line=$(awk -v u="$user" '$1==u {print; exit}' /etc/zivpn/user.db)
if [[ -z "$line" ]]; then
echo -e "  ${RD}Username '$user' not found.${NC}"
read -n 1 -s -r -p "  Press any key..."
menu_zivpn
fi
current_exp=$(echo "$line" | awk '{print $3}' | tr -d '
')
read -rp "  Enter additional days: " add_days
if [[ -z "$add_days" || ! "$add_days" =~ ^[0-9]+$ || "$add_days" -le 0 ]]; then
echo -e "  ${RD}Invalid number of days.${NC}"
menu_zivpn
fi
new_exp=$(date -d "$current_exp +$add_days days" +"%Y-%m-%d")
password=$(echo "$line" | awk '{print $2}')
sed -i "/^$user /c\$user $password $new_exp" /etc/zivpn/user.db
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  ZIVPN MENU                    ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${GREEN}User $user renewed successfully!${NC}"
echo -e "${LN}┃${NC}"
echo -e "${LN}┃${NC} Username   : $user"
echo -e "${LN}┃${NC} Old expiry : $current_exp"
echo -e "${LN}┃${NC} New expiry : $new_exp"
echo -e "${LN}┃${NC} Day Added  : $add_days"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p "   Press any key to return to menu..."
menu_zivpn
}
list_zivpn() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  ZIVPN MENU                    ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
if [[ ! -s /etc/zivpn/user.db ]]; then
echo -e "${LN}┃${NC} [**] No users found."
else
printf "${LN}┃ %-5s %-15s %-15s %-10s ${NC}
" "No." "Username" "Password" "Expiry"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
i=1
while read -r line; do
user=$(echo "$line" | awk '{print $1}')
pass=$(echo "$line" | awk '{print $2}')
exp=$(echo "$line" | awk '{print $3}')
printf "${LN}┃ %-5s %-15s %-15s %-10s ${NC}
" "$i" "$user" "$pass" "$exp"
((i++))
done < /etc/zivpn/user.db
fi
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -n 1 -s -r -p "Press any key to return to menu..."
menu_zivpn
}
menu_zivpn() {
clear
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}                  ZIVPN MENU                    ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} [01] • Create Account      [03] • Delete Account"
echo -e "${LN}┃${NC} [02] • Extend Account      [04] • Account List"
echo -e "${LN}┃${NC} "
echo -e "${LN}┃${NC} [00] • Back to Main Menu"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -p "  Select menu : " opt
echo ""
case $opt in
1 | 01) clear ; add_zivpn ;;
2 | 02) clear ; renew_zivpn ;;
3 | 03) clear ; del_zivpn ;;
4 | 04) clear ; list_zivpn ;;
0 | 00) clear ; menu ;;
*)
echo -e "${RD} [ERROR] Invalid selection!${NC}"
sleep 1
menu_zivpn
;;
esac
}
menu_zivpn
