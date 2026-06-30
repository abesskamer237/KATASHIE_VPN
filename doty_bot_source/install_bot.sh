#!/bin/bash
# Fichier : install_bot.sh
# Rôle : Installation automatisée du Bot Telegram Nexus Tunnel Pro

echo -e "\e[32m[+] Démarrage de l'installation du Bot Telegram Nexus Tunnel Pro...\e[0m"

# 1. Mise à jour et dépendances
echo -e "\e[33m[*] Installation des dépendances Python et Système...\e[0m"
apt-get update -y
apt-get install python3 python3-pip unzip zip qrencode -y
pip3 install pyTelegramBotAPI psutil qrcode pillow

# 2. Création de l'arborescence
echo -e "\e[33m[*] Création des dossiers du bot...\e[0m"
mkdir -p /root/doty_bot/core
mkdir -p /root/doty_bot/utils
mkdir -p /root/doty_bot/tg_interface
cd /root/doty_bot

# 3. Configuration initiale
echo -e "\e[36m========================================\e[0m"
read -p "Entrez le Token de votre Bot Telegram : " BOT_TOKEN
read -p "Entrez votre ID Telegram (Admin Principal) : " ADMIN_ID
echo -e "\e[36m========================================\e[0m"

cat <<EOF > /root/doty_bot/config.json
{
  "BOT_TOKEN": "$BOT_TOKEN",
  "ADMINS": [$ADMIN_ID],
  "BUG_HOST": "bug.cdn.com"
}
EOF

# 4. Téléchargement des modules (REMPLACE LES LIENS PAR CEUX DE TON GITHUB RAW)
echo -e "\e[33m[*] Téléchargement des fichiers source...\e[0m"
# wget -q -O /root/doty_bot/main.py https://raw.githubusercontent.com/TON_USER/TON_REPO/main/doty_bot_source/main.py
# wget -q -O /root/doty_bot/core/xray_handler.py https://raw.githubusercontent.com/TON_USER/TON_REPO/main/doty_bot_source/core/xray_handler.py
# wget -q -O /root/doty_bot/core/ssh_handler.py https://raw.githubusercontent.com/TON_USER/TON_REPO/main/doty_bot_source/core/ssh_handler.py
# wget -q -O /root/doty_bot/utils/qr_generator.py https://raw.githubusercontent.com/TON_USER/TON_REPO/main/doty_bot_source/utils/qr_generator.py
# touch /root/doty_bot/core/__init__.py
# touch /root/doty_bot/utils/__init__.py

# 5. Création du service SystemD
echo -e "\e[33m[*] Lancement du service en arrière-plan...\e[0m"
cat <<EOF > /etc/systemd/system/dotybot.service
[Unit]
Description=Nexus Tunnel Pro Telegram Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/doty_bot/main.py
WorkingDirectory=/root/doty_bot
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dotybot
systemctl restart dotybot

echo -e "\e[32m[+] Installation terminée ! Lancez /start dans votre bot Telegram.\e[0m"
