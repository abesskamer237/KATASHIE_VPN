#!/bin/bash
echo "=== Installation du Bot WhatsApp KATASHIE VPN ==="
pip3 install -r requirements.txt
mkdir -p /etc/katashie_whatsapp_bot
cp config.example.json /etc/katashie_whatsapp_bot/config.json
echo "Éditez /etc/katashie_whatsapp_bot/config.json avec vos credentials Twilio"
echo "Configurez le webhook Twilio sur: https://VOTRE_DOMAINE:5001/whatsapp"
cp whatsapp_bot.py /etc/katashie_whatsapp_bot/
cp /path/to/module/katashie-whatsapp-bot.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable katashie-whatsapp-bot
echo "Démarrez avec: systemctl start katashie-whatsapp-bot"
