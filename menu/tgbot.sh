#!/bin/bash
clear
LN='\e[36m'
NC='\e[0m'
BG='\e[44m'
RD='\e[31m'
GR='\e[32m'

echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${BG}           INSTALLATION DE NEXUS BOT            ${NC} ${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e ""
echo -e " Ce module va relier votre serveur à Telegram."
echo -e " Vous deviendrez le SUPER ADMIN du système."
echo -e ""

read -p " ➔ Entrez le TOKEN du Bot (ex: 1234:ABCDef...) : " bot_token
if [[ -z "$bot_token" ]]; then echo -e "${RD}Erreur: Le Token est obligatoire.${NC}"; sleep 2; exit; fi

read -p " ➔ Entrez votre ID Telegram (ex: 123456789) : " admin_id
if [[ -z "$admin_id" ]]; then echo -e "${RD}Erreur: L'ID Admin est obligatoire.${NC}"; sleep 2; exit; fi

echo -e "\n${GR}[+] Préparation de l'environnement Python...${NC}"
apt-get install -y python3 python3-pip git >/dev/null 2>&1
pip3 install pyTelegramBotAPI psutil >/dev/null 2>&1

echo -e "${GR}[+] Création sécurisée de la base de données...${NC}"
mkdir -p /etc/katashie_bot
cat <<JSON > /etc/katashie_bot/config.json
{
  "bot_token": "$bot_token",
  "super_admin": $admin_id,
  "admins": []
}
JSON

echo -e "${GR}[+] Téléchargement complet du moteur NEXUS C2 (Fichiers + Modules)...${NC}"
cd /tmp
rm -rf repo_temp
git clone https://github.com/RootNexTPro/nexTPro-ScriptAll.git repo_temp >/dev/null 2>&1
# On copie TOUT le dossier (le routeur et les modules)
cp -r repo_temp/nexus_core_bot/* /etc/katashie_bot/
rm -rf repo_temp

echo -e "${GR}[+] Configuration et alignement du Démon système...${NC}"
# On force l'écriture d'un service parfait avec les bons chemins
cat << 'SRV' > /etc/systemd/system/katashie_bot.service
[Unit]
Description=Nexus Bot Telegram C2
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/katashie_bot
ExecStart=/usr/bin/python3 /etc/katashie_bot/katashie_bot.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SRV

systemctl daemon-reload
systemctl enable --now katashie_bot
systemctl restart katashie_bot

echo -e "\n${GR}[+] Base de données verrouillée et Bot activé.${NC}"
echo -e " Allez sur Telegram et tapez /start"
echo -e "\n Appuyez sur ENTRÉE pour retourner au menu."
read
menu
