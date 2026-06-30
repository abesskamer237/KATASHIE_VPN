#!/bin/bash
# ============================================================
#   KATASHIE VPN — Menu SSH/WS
# ============================================================
RED='\033[0;31m'; BLUE='\033[0;34m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; WHITE='\033[0;37m'; BG_BLUE='\033[44m'; NC='\033[0m'
export LN="${BLUE}"; export BG="${BG_BLUE}"; export GR="${GREEN}"; export RD="${RED}"
export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
export PUB=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "N/A")
export DNS=$(cat /etc/slowdns/nsdomain 2>/dev/null || echo "N/A")
export MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s4 https://ipv4.icanhazip.com)

function create_ssh_account() {
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}          CRÉER UN COMPTE SSH — KATASHIE VPN     ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  read -p "  Nom d'utilisateur       : " Login
  if [[ -z "$Login" ]]; then
    echo -e "${RED}  [ERREUR] Le nom d'utilisateur ne peut pas être vide!${NC}"
    sleep 2; ssh; return
  fi
  if id "$Login" &>/dev/null; then
    echo -e "${RED}  [ERREUR] L'utilisateur '${Login}' existe déjà!${NC}"
    sleep 2; ssh; return
  fi
  read -p "  Mot de passe            : " Pass
  if [[ -z "$Pass" ]]; then
    echo -e "${RED}  [ERREUR] Le mot de passe ne peut pas être vide!${NC}"
    sleep 2; ssh; return
  fi
  read -p "  Validité (jours)        : " DaysActive
  if [[ -z "$DaysActive" || ! "$DaysActive" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}  [ERREUR] Veuillez entrer un nombre de jours valide!${NC}"
    sleep 2; ssh; return
  fi
  useradd -e "$(date -d "$DaysActive days" +"%Y-%m-%d")" -s /bin/false -M "$Login"
  exp="$(chage -l "$Login" | grep "Account expires" | awk -F": " '{print $2}')"
  echo -e "$Pass\n$Pass" | passwd "$Login" &>/dev/null
  clear
  echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${GREEN}┃${NC} ${BG_BLUE}           DÉTAILS DU COMPTE SSH CRÉÉ           ${NC} ${GREEN}┃${NC}"
  echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${GREEN}✔${NC} Utilisateur : $Login"
  echo -e "${BLUE}┃${NC} ${GREEN}✔${NC} Mot de passe: $Pass"
  echo -e "${BLUE}┃${NC} ${GREEN}✔${NC} Expiration  : $exp"
  echo -e "${BLUE}┃${NC} ${WHITE}   Host/IP    : $MYIP"
  echo -e "${BLUE}┃${NC} ${WHITE}   Domaine    : $DOMAIN"
  echo -e "${BLUE}┃${NC} ${WHITE}   NS Domaine : $DNS"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${CYAN}OpenSSH${NC}   : 22"
  echo -e "${BLUE}┃${NC} ${CYAN}Dropbear${NC}  : 109, 143"
  echo -e "${BLUE}┃${NC} ${CYAN}Stunnel${NC}   : 447, 777"
  echo -e "${BLUE}┃${NC} ${CYAN}WS NTLS${NC}   : 80, 8880"
  echo -e "${BLUE}┃${NC} ${CYAN}WS TLS${NC}    : 443"
  echo -e "${BLUE}┃${NC} ${CYAN}UDPGW${NC}     : 7100–7900"
  echo -e "${BLUE}┃${NC} ${CYAN}Squid${NC}     : 3128, 8880"
  echo -e "${BLUE}┃${NC} ${CYAN}OpenVPN${NC}   : TCP 1194, SSL 2200, OHP 8000"
  echo -e "${BLUE}┃${NC} ${CYAN}Slow DNS${NC}  : 22,53,5300,80,443"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${YELLOW}UDP Custom${NC}"
  echo -e "${BLUE}┃${NC} $DOMAIN:1-65535@$Login:$Pass"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${YELLOW}Slow DNS PUB Key${NC}"
  echo -e "${BLUE}┃${NC} $PUB"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${YELLOW}OpenVPN Download${NC}"
  echo -e "${BLUE}┃${NC} https://$DOMAIN:2081"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${YELLOW}Payload WebSocket${NC}"
  echo -e "${BLUE}┃${NC} GET / HTTP/1.1[crlf]Host: $DOMAIN[crlf]Upgrade: websocket[crlf][crlf]"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo ""; read -n 1 -s -r -p "  Appuyez sur une touche pour revenir au menu..."
  ssh
}

function renew_ssh_account() {
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}         RENOUVELER UN COMPTE SSH               ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Comptes SSH existants (Utilisateur — Expiration)${NC}"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  while IFS=: read -r user _ uid _; do
    if [[ $uid -ge 1000 && "$user" != "nobody" ]]; then
      exp="$(chage -l "$user" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
      printf "${BLUE}┃${NC} ${GREEN}•${NC} %-15s ${YELLOW}%s${NC}\n" "$user" "$exp"
    fi
  done < /etc/passwd
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  read -p "  Nom d'utilisateur : " User
  if [[ -z "$User" ]]; then echo -e "${RED}  [ERREUR] Vide!${NC}"; sleep 2; ssh; return; fi
  if ! id "$User" &>/dev/null; then
    echo -e "${RED}  [ERREUR] L'utilisateur '$User' n'existe pas!${NC}"; sleep 2; ssh; return
  fi
  read -p "  Prolonger de (jours)  : " Days
  if [[ -z "$Days" || ! "$Days" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}  [ERREUR] Nombre de jours invalide!${NC}"; sleep 2; ssh; return
  fi
  current_exp=$(chage -l "$User" | grep "Account expires" | awk -F": " '{print $2}')
  if [[ "$current_exp" == "never" ]]; then old_date=$(date +%s); else old_date=$(date -d "$current_exp +1 day" +%s); fi
  new_expire=$(( old_date + Days * 86400 ))
  Expiration=$(date --date="1970-01-01 $new_expire sec" +%Y-%m-%d)
  Expiration_Display=$(date --date="1970-01-01 $new_expire sec" '+%d %b %Y')
  passwd -u "$User" &>/dev/null
  usermod -e "$Expiration" "$User" &>/dev/null
  clear
  echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${GREEN}┃${NC} ${BG_BLUE}          COMPTE SSH RENOUVELÉ                  ${NC} ${GREEN}┃${NC}"
  echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Utilisateur  :${NC} $User"
  echo -e "${BLUE}┃${NC} ${WHITE}Ancienne exp.:${NC} $current_exp"
  echo -e "${BLUE}┃${NC} ${WHITE}Jours ajoutés:${NC} $Days jour(s)"
  echo -e "${BLUE}┃${NC} ${GREEN}Nouvelle exp.:${NC} $Expiration_Display"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""; read -n 1 -s -r -p "  Appuyez sur une touche pour revenir..."
  ssh
}

function delete_ssh_account() {
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}         SUPPRIMER UN COMPTE SSH                ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  while IFS=: read -r user _ uid _; do
    if [[ $uid -ge 1000 && "$user" != "nobody" ]]; then
      exp="$(chage -l "$user" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
      printf "${BLUE}┃${NC} ${GREEN}•${NC} %-15s ${YELLOW}%s${NC}\n" "$user" "$exp"
    fi
  done < /etc/passwd
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  read -p "  Nom d'utilisateur : " User
  if [[ -z "$User" ]]; then echo -e "${RED}  [ERREUR] Vide!${NC}"; sleep 2; ssh; return; fi
  if ! id "$User" &>/dev/null; then
    echo -e "${RED}  [ERREUR] L'utilisateur '$User' n'existe pas!${NC}"; sleep 2; ssh; return
  fi
  pkill -u "$User" &>/dev/null
  userdel -r "$User" &>/dev/null
  clear
  echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${GREEN}┃${NC} ${BG_BLUE}          COMPTE SSH SUPPRIMÉ                    ${NC} ${GREEN}┃${NC}"
  echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Utilisateur :${NC} $User"
  echo -e "${BLUE}┃${NC} ${GREEN}Statut      :${NC} Supprimé avec succès"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""; read -n 1 -s -r -p "  Appuyez sur une touche pour revenir..."
  ssh
}

function list_ssh_members() {
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}           LISTE DES MEMBRES SSH                ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  printf "${BLUE}┃${NC} ${WHITE}%-16s %-18s %s${NC}\n" "USERNAME" "EXPIRATION" "STATUT"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  while read expired; do
    AKUN="$(echo "$expired" | cut -d: -f1)"
    ID="$(echo "$expired" | cut -d: -f3)"
    exp="$(chage -l "$AKUN" 2>/dev/null | grep "Account expires" | awk -F": " '{print $2}')"
    status="$(passwd -S "$AKUN" 2>/dev/null | awk '{print $2}')"
    if [[ $ID -ge 1000 && "$AKUN" != "nobody" ]]; then
      if [[ "$status" = "L" ]]; then
        printf "${BLUE}┃${NC} %-16s %-18s ${RED}VERROUILLÉ${NC}\n" "$AKUN" "$exp"
      else
        printf "${BLUE}┃${NC} %-16s %-18s ${GREEN}ACTIF${NC}\n" "$AKUN" "$exp"
      fi
    fi
  done < /etc/passwd
  JUMLAH="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${YELLOW}Total : $JUMLAH compte(s)${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""; read -n 1 -s -r -p "  Appuyez sur une touche pour revenir..."
  ssh
}

function menu_ssh() {
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}              MENU SSH — KATASHIE VPN            ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${GREEN}[01]${NC} • Créer un compte     ${GREEN}[04]${NC} • Lister les comptes"
  echo -e "${BLUE}┃${NC} ${GREEN}[02]${NC} • Renouveler          ${GREEN}[05]${NC} • Utilisateurs en ligne"
  echo -e "${BLUE}┃${NC} ${RED}[03]${NC} • Supprimer"
  echo -e "${BLUE}┃${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}[00]${NC} • Retour au menu principal"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo ""
  read -p "  Sélectionnez une option : " opt
  echo ""
  case $opt in
  1 | 01) clear ; create_ssh_account ;;
  2 | 02) clear ; renew_ssh_account ;;
  3 | 03) clear ; delete_ssh_account ;;
  4 | 04) clear ; list_ssh_members ;;
  0 | 00) clear ; menu ;;
  *) echo -e "${RED}  [ERREUR] Option invalide!${NC}"; sleep 1; menu_ssh ;;
  esac
}
menu_ssh
