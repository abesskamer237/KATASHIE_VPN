#!/bin/bash
echo "=== Installation du Bot Telegram Principal KATASHIE VPN ==="
pip3 install -r requirements.txt
mkdir -p /etc/katashie_bot
cp config.example.json /etc/katashie_bot/config.json
echo "Éditez /etc/katashie_bot/config.json avec votre token et votre ID Telegram"
cp katashie_bot.py /etc/katashie_bot/
cp -r modules/ /etc/katashie_bot/
cp /path/to/module/katashie-core-bot.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable katashie-core-bot
echo "Démarrez avec: systemctl start katashie-core-bot"
