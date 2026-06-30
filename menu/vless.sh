#!/bin/bash
# ============================================================
#   KATASHIE VPN — Menu VLESS
# ============================================================
RED='\033[0;31m'; BLUE='\033[0;34m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; WHITE='\033[0;37m'; BG_BLUE='\033[44m'; NC='\033[0m'
export LN="${BLUE}"; export BG="${BG_BLUE}"; export GR="${GREEN}"; export RD="${RED}"
export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
export MYIP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || curl -s4 https://ipv4.icanhazip.com)
XRAY_CONFIG="/etc/xray/config.json"

function add_vless() {
  clear
  while true; do
    echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BLUE}┃${NC} ${BG_BLUE}        CRÉER UN COMPTE VLESS — KATASHIE VPN     ${NC} ${BLUE}┃${NC}"
    echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo ""
    read -rp "  Nom d'utilisateur : " user
    if [[ -z "$user" ]]; then echo -e " ${RED}Le nom d'utilisateur ne peut pas être vide.${NC}"; continue; fi
    if [[ ! "$user" =~ ^[a-zA-Z0-9_]+$ ]]; then
      echo -e " ${RED}Caractères autorisés: lettres, chiffres, underscore.${NC}"; continue
    fi
    CLIENT_EXISTS=$(grep -w "$user" "$XRAY_CONFIG" 2>/dev/null | wc -l)
    if [[ "$CLIENT_EXISTS" -gt 0 ]]; then
      echo -e " ${RED}Ce nom d'utilisateur existe déjà.${NC}"
      read -n 1 -s -r -p " Appuyez sur une touche pour réessayer..."; clear; continue
    fi
    break
  done
  while true; do
    read -rp "  Validité (jours) : " masaaktif
    if [[ -z "$masaaktif" || ! "$masaaktif" =~ ^[0-9]+$ || "$masaaktif" -le 0 ]]; then
      echo -e " ${RED}Entrez un nombre de jours valide (entier positif).${NC}"; continue
    fi
    break
  done
  uuid=$(cat /proc/sys/kernel/random/uuid)
  exp=$(date -d "+$masaaktif days" +"%Y-%m-%d")
  sed -i "/#vless$/a\\#& $user $exp $uuid\\n},{\"id\": \"$uuid\",\"email\": \"$user\"" "$XRAY_CONFIG"
  sed -i "/#vlessgrpc$/a\\#& $user $exp $uuid\\n},{\"id\": \"$uuid\",\"email\": \"$user\"" "$XRAY_CONFIG"
  systemctl restart xray 2>/dev/null
  vlesslink1="vless://${uuid}@${DOMAIN}:443?path=/vless&security=tls&encryption=none&type=ws#${user}"
  vlesslink2="vless://${uuid}@${DOMAIN}:80?path=/vless&encryption=none&type=ws#${user}"
  vlesslink3="vless://${uuid}@${DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc#${user}"
  clear
  echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${GREEN}┃${NC} ${BG_BLUE}          DÉTAILS DU COMPTE VLESS CRÉÉ           ${NC} ${GREEN}┃${NC}"
  echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${GREEN}✔${NC} Utilisateur : ${user}"
  echo -e "${BLUE}┃${NC} ${GREEN}✔${NC} Expiration  : ${exp}"
  echo -e "${BLUE}┃${NC} ${GREEN}✔${NC} UUID        : ${uuid}"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Domaine   : ${DOMAIN}${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Port TLS  : 443"
  echo -e "${BLUE}┃${NC} ${WHITE}Port NTLS : 80"
  echo -e "${BLUE}┃${NC} ${WHITE}Port gRPC : 443"
  echo -e "${BLUE}┃${NC} ${WHITE}Réseau    : ws"
  echo -e "${BLUE}┃${NC} ${WHITE}Path      : /vless"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${CYAN}TLS (443) :${NC}"
  echo -e "${BLUE}┃${NC} ${vlesslink1}"
  echo -e "${BLUE}┃${NC}"
  echo -e "${BLUE}┃${NC} ${CYAN}NTLS (80) :${NC}"
  echo -e "${BLUE}┃${NC} ${vlesslink2}"
  echo -e "${BLUE}┃${NC}"
  echo -e "${BLUE}┃${NC} ${CYAN}gRPC (443):${NC}"
  echo -e "${BLUE}┃${NC} ${vlesslink3}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo ""; read -n 1 -s -r -p " Appuyez sur une touche pour revenir au menu..."
  vless_menu
}

function renew_vless() {
  NUMBER_OF_CLIENTS=$(grep -c -E "^#& " "$XRAY_CONFIG" 2>/dev/null || echo 0)
  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    clear; echo -e "${RED}  Aucun client VLESS existant.${NC}"; sleep 2; vless_menu; return
  fi
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}         RENOUVELER UN COMPTE VLESS             ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  printf "${BLUE}┃${NC} ${WHITE}%-18s %s${NC}\n" "Utilisateur" "Expiration"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  grep -E "^#& " "$XRAY_CONFIG" | awk '{print $2, $3}' | sort -u | while read -r u e; do
    printf "${BLUE}┃${NC} ${GREEN}•${NC} %-16s ${YELLOW}%s${NC}\n" "$u" "$e"
  done
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  while true; do
    read -rp "  Nom d'utilisateur : " user
    if [[ -z "$user" ]]; then vless_menu; return; fi
    CLIENT_EXISTS=$(grep -wE "^#& $user" "$XRAY_CONFIG" | wc -l)
    [[ $CLIENT_EXISTS -eq 0 ]] && { echo -e "${RED} Introuvable.${NC}"; continue; }
    break
  done
  while true; do
    read -p "  Jours à ajouter : " masaaktif
    [[ "$masaaktif" =~ ^[0-9]+$ && "$masaaktif" -gt 0 ]] && break
    echo -e "${RED} Entier positif requis.${NC}"
  done
  exp=$(grep -wE "^#& $user" "$XRAY_CONFIG" | awk '{print $3}' | sort -u)
  uuid=$(grep -wE "^#& $user" "$XRAY_CONFIG" | awk '{print $4}' | grep -v '^[[:space:]]*$' | sort -u)
  now=$(date +%Y-%m-%d); d1=$(date -d "$exp" +%s); d2=$(date -d "$now" +%s)
  exp2=$(( (d1 - d2) / 86400 )); exp3=$(( exp2 + masaaktif ))
  exp4=$(date -d "$exp3 days" +"%Y-%m-%d")
  sed -i "/^#& $user /c\\#& $user $exp4 $uuid" "$XRAY_CONFIG"
  systemctl restart xray >/dev/null 2>&1
  clear
  echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${GREEN}┃${NC} ${BG_BLUE}          COMPTE VLESS RENOUVELÉ                ${NC} ${GREEN}┃${NC}"
  echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Utilisateur   :${NC} ${user}"
  echo -e "${BLUE}┃${NC} ${WHITE}Jours ajoutés :${NC} ${masaaktif}"
  echo -e "${BLUE}┃${NC} ${GREEN}Nouvelle exp. :${NC} ${exp4}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""; read -n 1 -s -r -p " Appuyez sur une touche..."; vless_menu
}

function delete_vless() {
  NUMBER_OF_CLIENTS=$(grep -c -E "^#& " "$XRAY_CONFIG" 2>/dev/null || echo 0)
  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    clear; echo -e "${RED}  Aucun client VLESS existant.${NC}"; sleep 2; vless_menu; return
  fi
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}         SUPPRIMER UN COMPTE VLESS              ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  grep -E "^#& " "$XRAY_CONFIG" | awk '{print $2, $3}' | sort -u | while read -r u e; do
    printf "${BLUE}┃${NC} ${GREEN}•${NC} %-16s ${YELLOW}%s${NC}\n" "$u" "$e"
  done
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  read -rp " Nom d'utilisateur à supprimer : " duser
  if [[ -z "$duser" ]]; then vless_menu; return; fi
  exp=$(grep -wE "^#& $duser" "$XRAY_CONFIG" | cut -d ' ' -f 3 | sort | uniq)
  if [[ -z "$exp" ]]; then echo -e "${RED} Introuvable.${NC}"; sleep 2; vless_menu; return; fi
  sed -i -e "/^#& $duser /d" -e "/\"email\": \"$duser\"/d" "$XRAY_CONFIG"
  systemctl restart xray >/dev/null 2>&1
  clear
  echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${GREEN}┃${NC} ${BG_BLUE}          COMPTE VLESS SUPPRIMÉ                 ${NC} ${GREEN}┃${NC}"
  echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Utilisateur :${NC} ${duser}"
  echo -e "${BLUE}┃${NC} ${GREEN}Statut      :${NC} Supprimé avec succès"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""; read -n 1 -s -r -p " Appuyez sur une touche..."; vless_menu
}

function view_vless() {
  NUMBER_OF_CLIENTS=$(grep -c -E "^#& " "$XRAY_CONFIG" 2>/dev/null || echo 0)
  if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
    clear; echo -e "${RED}  Aucun client VLESS existant.${NC}"; sleep 2; vless_menu; return
  fi
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}         VOIR UN COMPTE VLESS                   ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  grep -E "^#& " "$XRAY_CONFIG" | awk '{print $2, $3}' | sort -u | while read -r u e; do
    printf "${BLUE}┃${NC} ${GREEN}•${NC} %-16s ${YELLOW}%s${NC}\n" "$u" "$e"
  done
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  read -rp " Nom d'utilisateur : " user
  if [[ -z "$user" ]]; then vless_menu; return; fi
  exp=$(grep -wE "^#& $user" "$XRAY_CONFIG" | awk '{print $3}' | sort -u)
  if [[ -z "$exp" ]]; then echo -e "${RED} Introuvable.${NC}"; sleep 2; vless_menu; return; fi
  UUID=$(grep -wE "^#& $user" "$XRAY_CONFIG" | awk '{print $4}' | sort -u)
  vlesslink1="vless://${UUID}@${DOMAIN}:443?path=/vless&security=tls&encryption=none&type=ws#${user}"
  vlesslink2="vless://${UUID}@${DOMAIN}:80?path=/vless&encryption=none&type=ws#${user}"
  vlesslink3="vless://${UUID}@${DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc#${user}"
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}              COMPTE VLESS                       ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}Utilisateur :${NC} ${user}"
  echo -e "${BLUE}┃${NC} ${WHITE}Expiration  :${NC} ${exp}"
  echo -e "${BLUE}┃${NC} ${WHITE}UUID        :${NC} ${UUID}"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo -e "${BLUE}┃${NC} ${CYAN}TLS (443):${NC} ${vlesslink1}"
  echo -e "${BLUE}┃${NC} ${CYAN}NTLS (80):${NC} ${vlesslink2}"
  echo -e "${BLUE}┃${NC} ${CYAN}gRPC (443):${NC} ${vlesslink3}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""; read -n 1 -s -r -p " Appuyez sur une touche..."; vless_menu
}

function vless_menu() {
  clear
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${BG_BLUE}             MENU VLESS — KATASHIE VPN           ${NC} ${BLUE}┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃${NC} ${GREEN}[01]${NC} • Créer un compte    ${GREEN}[04]${NC} • Voir un compte"
  echo -e "${BLUE}┃${NC} ${GREEN}[02]${NC} • Renouveler         ${GREEN}[05]${NC} • Utilisateurs actifs"
  echo -e "${BLUE}┃${NC} ${RED}[03]${NC} • Supprimer"
  echo -e "${BLUE}┃${NC}"
  echo -e "${BLUE}┃${NC} ${WHITE}[00]${NC} • Retour au menu principal"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${BLUE}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo ""
  read -p "  Sélectionnez une option : " opt
  echo ""
  case $opt in
  1 | 01) clear ; add_vless ;;
  2 | 02) clear ; renew_vless ;;
  3 | 03) clear ; delete_vless ;;
  4 | 04) clear ; view_vless ;;
  0 | 00) clear ; menu ;;
  *) echo -e "${RED}  [ERREUR] Option invalide!${NC}"; sleep 1; vless_menu ;;
  esac
}
vless_menu
