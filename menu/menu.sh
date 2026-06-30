#!/bin/bash
# ============================================================
#   KATASHIE VPN — Menu Principal
#   Remplace: menu.sh (nexus)
# ============================================================

# ─── Couleurs ────────────────────────────────────────────────
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
CYAN='\033[0;36m'
BOLD='\033[1m'
BG_BLUE='\033[44m'
NC='\033[0m'

# Compat héritage
export LN="${BLUE}"
export BG="${BG_BLUE}"
export GR="${GREEN}"
export RD="${RED}"

MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null || wget -qO- ipv4.icanhazip.com)
readonly SERVER_HOST="https://raw.githubusercontent.com/YOUR_GITHUB/katashie-vpn/main"
clear

domain=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
uptime_str="$(uptime -p 2>/dev/null | cut -d ' ' -f 2-10 || echo 'N/A')"
IPV4=$(curl -s -4 ifconfig.co 2>/dev/null || echo 'N/A')

# ─── Vérification de version ──────────────────────────────────
VERSION_FILE="/etc/katashie/version"
INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || cat /etc/version 2>/dev/null || echo "2.0.0")
LATEST_VERSION=$(curl -sS "$SERVER_HOST/version" 2>/dev/null || echo "$INSTALLED_VERSION")
UPDATE_AVAILABLE=0
version_greater() {
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ] && [ "$1" != "$2" ]
}
if version_greater "$LATEST_VERSION" "$INSTALLED_VERSION"; then
    UPDATE_AVAILABLE=1
    wget -q -O /usr/local/sbin/update "$SERVER_HOST/menu/update.sh" 2>/dev/null && chmod +x /usr/local/sbin/update
fi

# ─── Statut des services ──────────────────────────────────────
get_status() {
    local svc=$1
    if systemctl is-active "$svc" >/dev/null 2>&1; then
        echo -e "${GREEN}●RUN${NC}"
    else
        echo -e "${RED}○OFF${NC}"
    fi
}
s_nginx=$(get_status nginx)
s_xray=$(get_status xray)
s_ws=$(get_status ws-stunnel)

# ─── Infos OS ─────────────────────────────────────────────────
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$NAME $VERSION_ID"
else
    OS_NAME=$(uname -s)
fi

clear
echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC} ${BG_BLUE}                  KATASHIE VPN                  ${NC} ${BLUE}┃${NC}"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC}  ${WHITE}OS      :${NC} ${OS_NAME}"
echo -e "${BLUE}┃${NC}  ${WHITE}Uptime  :${NC} ${uptime_str}"
echo -e "${BLUE}┃${NC}  ${WHITE}IP      :${NC} ${IPV4}"
echo -e "${BLUE}┃${NC}  ${WHITE}Domaine :${NC} ${domain}"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC}   NGINX: [${s_nginx}]    XRAY: [${s_xray}]    WS: [${s_ws}]"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC} ${BG_BLUE}                  PROTOCOLES VPN                ${NC} ${BLUE}┃${NC}"
echo -e "${BLUE}┃${NC}"
echo -e "${BLUE}┃${NC} ${GREEN}[01]${NC} • SSH/WS            ${GREEN}[04]${NC} • TROJAN"
echo -e "${BLUE}┃${NC} ${GREEN}[02]${NC} • VMESS             ${GREEN}[05]${NC} • SOCKS"
echo -e "${BLUE}┃${NC} ${GREEN}[03]${NC} • VLESS             ${GREEN}[06]${NC} • ZIVPN"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC} ${BG_BLUE}                      OUTILS                    ${NC} ${BLUE}┃${NC}"
echo -e "${BLUE}┃${NC}"
echo -e "${BLUE}┃${NC} ${CYAN}[07]${NC} • DNS Panel         ${CYAN}[12]${NC} • Info Ports VPN"
echo -e "${BLUE}┃${NC} ${CYAN}[08]${NC} • Domaine Panel     ${CYAN}[13]${NC} • Nettoyer Logs"
echo -e "${BLUE}┃${NC} ${CYAN}[09]${NC} • IPv6 Panel        ${CYAN}[14]${NC} • Bot Telegram"
echo -e "${BLUE}┃${NC} ${CYAN}[10]${NC} • Statut VPS        ${CYAN}[16]${NC} • Fast DNS"
echo -e "${BLUE}┃${NC} ${CYAN}[11]${NC} • NetGuard"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC} ${BG_BLUE}                   PANNEAU WEB                  ${NC} ${BLUE}┃${NC}"
echo -e "${BLUE}┃${NC}"
echo -e "${BLUE}┃${NC} ${WHITE}[18]${NC} • KATASHIE VPN Web Panel"
echo -e "${BLUE}┃${NC}"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC} ${RED}[15]${NC} • Désinstaller      ${RED}[88]${NC} • Redémarrer VPS"
echo -e "${BLUE}┃${NC} ${WHITE}[00]${NC} • Quitter"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

if [ "$UPDATE_AVAILABLE" -eq 1 ] 2>/dev/null; then
    echo -e "${YELLOW}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${YELLOW}┃${NC} ${YELLOW}[99]${NC} • ⚡ MISE À JOUR DISPONIBLE (v${LATEST_VERSION})"
    echo -e "${YELLOW}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
fi

echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${BLUE}┃${NC} ${WHITE}Version    :${NC} ${INSTALLED_VERSION}"
echo -e "${BLUE}┃${NC} ${WHITE}Script by  :${NC} KATASHIE TEAM"
echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
echo ""
read -p "  Sélectionnez une option : " opt
echo ""
case $opt in
1 | 01) clear ; ssh ;;
2 | 02) clear ; vmess ;;
3 | 03) clear ; vless ;;
4 | 04) clear ; trojan ;;
5 | 05) clear ; socks ;;
6 | 06) clear ; zivpn ;;
7 | 07) clear ; dns ;;
8 | 08) clear ; domain ;;
9 | 09) clear ; iptools ;;
10)     clear ; status ;;
11)     clear ; netguard ;;
12)     clear ; port ;;
13)     clear ; log ;;
14)     clear ; tgbot ;;
15)     clear ; uninstall ;;
16)     clear ; fastdns ;;
18)     clear ; web ;;
88)     reboot ;;
99)     clear ; update ;;
0 | 00) exit 0 ;;
*)      clear ; menu ;;
esac
