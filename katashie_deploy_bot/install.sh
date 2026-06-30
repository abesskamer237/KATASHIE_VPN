#!/bin/bash
echo "=== Installation du Bot Deploy KATASHIE VPN ==="
pip3 install -r requirements.txt
mkdir -p /etc/katashie_deploy_bot
cp config.example.json /etc/katashie_deploy_bot/config.json
echo "Éditez /etc/katashie_deploy_bot/config.json avec votre token et votre ID Telegram"
cp deploy_bot.py /etc/katashie_deploy_bot/
cp /path/to/module/katashie-deploy-bot.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable katashie-deploy-bot
echo "Démarrez avec: systemctl start katashie-deploy-bot"
