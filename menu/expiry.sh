clear
CONFIG="/etc/xray/config.json"
today=$(date +"%Y-%m-%d")
remove_expired_users() {
local marker="$1"
local proto="$2"
users=($(grep "^$marker " "$CONFIG" | awk '{print $2}' | sort -u))
for user in "${users[@]}"; do
exp=$(grep -w "^$marker $user" "$CONFIG" | awk '{print $3}' | head -n1)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$today" +%s)
days_left=$(( (d1 - d2) / 86400 ))
if [[ $days_left -le 0 ]]; then
echo "⛔ Removing expired $proto user: $user"
sed -i "/^$marker $user $exp/,/\"email\": \"$user\"/d" "$CONFIG"
fi
done
}
remove_expired_ssh() {
echo "🔎 Checking SSH accounts..."
awk -F: '$8!="" {print $1":"$8}' /etc/shadow > /tmp/expirelist.txt
while IFS=: read -r user exp_days; do
exp_ts=$(( exp_days * 86400 ))
today_ts=$(date +%s)
if (( exp_ts < today_ts )); then
echo "⛔ Removing expired SSH user: $user"
userdel --force "$user" 2>/dev/null
rm -rf /home/$user
fi
done < /tmp/expirelist.txt
}
remove_expired_zivpn() {
echo "🔎 Checking ZIVPN accounts..."
[[ ! -f "$ZIVPN_DB" ]] && return
while read -r line; do
user=$(echo "$line" | awk '{print $1}')
pass=$(echo "$line" | awk '{print $2}')
exp=$(echo "$line" | awk '{print $3}')
[[ -z "$user" || -z "$exp" ]] && continue
d1=$(date -d "$exp" +%s)
d2=$(date -d "$today" +%s)
if (( d1 < d2 )); then
echo "⛔ Removing expired ZIVPN user: $user"
sed -i "/\"$pass\"/d" "$ZIVPN_CFG"
sed -i "/^$user /d" "$ZIVPN_DB"
fi
done < "$ZIVPN_DB"
systemctl restart zivpn
}
remove_expired_users "###" "VMess"
remove_expired_users "#&"  "VLESS"
remove_expired_users "#!"  "Trojan"
remove_expired_users "#@"  "SOCKS"
remove_expired_ssh
remove_expired_zivpn
systemctl restart xray
echo "✅ Expired users cleaned (Xray + SSH). Xray restarted."
