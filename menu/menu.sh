#!/bin/bash
UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
MYIP=$(curl -sS --max-time 5 ipv4.icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
readonly SERVER_HOST="https://raw.githubusercontent.com/abesskamer237/KATASHIE_VPN/main"
domain=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
uptime="$(uptime -p | cut -d ' ' -f 2-10)"
IPV4="$MYIP"
VERSION_FILE="/etc/version"; INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "1.3.0")
LATEST_VERSION=$(curl -fsS --max-time 4 "$SERVER_HOST/version" 2>/dev/null || echo "$INSTALLED_VERSION")
UPDATE_AVAILABLE=0
version_greater(){ [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ] && [ "$1" != "$2" ]; }
version_greater "$LATEST_VERSION" "$INSTALLED_VERSION" && UPDATE_AVAILABLE=1
if [ -f /etc/os-release ]; then . /etc/os-release; OS="$NAME"; VER="$VERSION_ID"; else OS=$(uname -s); VER=$(uname -r); fi
svc(){ systemctl is-active "$1" 2>/dev/null | grep -q '^active$'; }
mark(){ if svc "$1"; then printf '%b' "${K_GREEN}● ON${K_RESET}"; else printf '%b' "${K_RED}○ OFF${K_RESET}"; fi; }

k_brand
printf '%b\n' "${K_GREEN}╭────────────────────────────────────────────────────────────────╮"
printf '%b\n' "│ ${K_WHITE}SYSTEM VPS${K_RESET} : ${K_CYAN}${OS} ${VER}${K_RESET}"
printf '%b\n' "│ ${K_WHITE}RAM SERVER${K_RESET} : ${K_CYAN}$(free -m | awk '/Mem:/ {print $3" / "$2" MB"}')${K_RESET}"
printf '%b\n' "│ ${K_WHITE}IP VPS${K_RESET}     : ${K_CYAN}${IPV4:-N/A}${K_RESET}"
printf '%b\n' "│ ${K_WHITE}DOMAIN${K_RESET}     : ${K_CYAN}${domain}${K_RESET}"
printf '%b\n' "│ ${K_WHITE}UPTIME${K_RESET}     : ${K_CYAN}${uptime}${K_RESET}"
printf '%b\n' "${K_GREEN}╰────────────────────────────────────────────────────────────────╯${K_RESET}"
k_sep K_MAGENTA
printf '%b\n' "${K_GREEN}                 >>> INFORMATION VPN <<<${K_RESET}"
printf '%b\n' "${K_CYAN}   SSH/OPENVPN/UDP : ${K_YELLOW}$(svc ssh || true) / $(svc openvpn || true)${K_RESET}"
printf '%b\n' "${K_CYAN}   VMESS/VLESS     : ${K_YELLOW}CORE X${K_RESET}"
printf '%b\n' "${K_CYAN}   XRAY            : $(mark xray)    NGINX : $(mark nginx)${K_RESET}"
k_sep K_YELLOW
printf '%b\n' "${K_GREEN}                 >>> MENU KATASHIE VPN <<<${K_RESET}"
printf '%b\n' "${K_GREEN}╭────────────────────────────────────────────────────────────────╮"
printf '%b\n' "│ ${K_CYAN}[01]${K_RESET} MENU SSH VIP      ${K_CYAN}[09]${K_RESET} AUTO REBOOT       ${K_CYAN}[17]${K_RESET} RESTART VPS       │"
printf '%b\n' "│ ${K_CYAN}[02]${K_RESET} MENU VMESS        ${K_CYAN}[10]${K_RESET} MENU PORT         ${K_CYAN}[18]${K_RESET} SET DOMAIN        │"
printf '%b\n' "│ ${K_CYAN}[03]${K_RESET} MENU VLESS        ${K_CYAN}[11]${K_RESET} SPEEDTEST         ${K_CYAN}[19]${K_RESET} CERT SSL          │"
printf '%b\n' "│ ${K_CYAN}[04]${K_RESET} MENU TROJAN       ${K_CYAN}[12]${K_RESET} RUNNING CHECK     ${K_CYAN}[20]${K_RESET} INSTALL UDP       │"
printf '%b\n' "│ ${K_CYAN}[05]${K_RESET} MENU SOCKS        ${K_CYAN}[13]${K_RESET} CLEAR LOG         ${K_CYAN}[21]${K_RESET} CLEAR CACHE       │"
printf '%b\n' "│ ${K_CYAN}[06]${K_RESET} MENU ZIVPN        ${K_CYAN}[14]${K_RESET} CREATE BACKUP     ${K_CYAN}[22]${K_RESET} CHECK BANDWIDTH   │"
printf '%b\n' "│ ${K_CYAN}[07]${K_RESET} CHECK RAM/CPU     ${K_CYAN}[15]${K_RESET} REBOOT VPS        ${K_CYAN}[23]${K_RESET} MENU BOT VIP      │"
printf '%b\n' "│ ${K_CYAN}[08]${K_RESET} DELETE ALL EXP    ${K_CYAN}[16]${K_RESET} FAST DNS          ${K_CYAN}[24]${K_RESET} WEB PANEL         │"
printf '%b\n' "│ ${K_CYAN}[25]${K_RESET} UPDATE KATASHIE   ${K_CYAN}[26]${K_RESET} UNINSTALL KATASHIE│"
printf '%b\n' "${K_GREEN}╰────────────────────────────────────────────────────────────────╯${K_RESET}"
k_sep K_MAGENTA
printf '%b\n' "${K_GREEN}Script Version : ${K_WHITE}${INSTALLED_VERSION}${K_RESET}"
printf '%b\n' "${K_GREEN}Script Status  : ${K_CYAN}ACTIVE${K_RESET}"
printf '%b\n' "${K_GREEN}Signature      : ${K_YELLOW}KATASHIE VPN${K_RESET}"
if [ "$UPDATE_AVAILABLE" -eq 1 ]; then
  printf '%b\n' "${K_RED}⚡ UPDATE AVAILABLE : v${LATEST_VERSION}${K_RESET}"
fi
k_sep K_YELLOW
k_wait; read -r opt; echo
case "$opt" in
  1|01) clear; ssh ;;
  2|02) clear; vmess ;;
  3|03) clear; vless ;;
  4|04) clear; trojan ;;
  5|05) clear; socks ;;
  6|06) clear; zivpn ;;
  7|07) clear; dns ;;
  8|08) clear; domain ;;
  9|09) clear; iptools ;;
  10) clear; status ;;
  11) clear; netguard ;;
  12) clear; port ;;
  13) clear; log ;;
  14) clear; tgbot ;;
  15) clear; uninstall ;;
  16) clear; fastdns ;;
  17|88) reboot ;;
  18) clear; web ;;
  99) clear; update ;;
  0|00) exit 0 ;;
  *) printf '%b\n' "${K_RED}Invalid option. Choose a listed number.${K_RESET}"; sleep .8 ;;
esac
exec /usr/local/sbin/menu
