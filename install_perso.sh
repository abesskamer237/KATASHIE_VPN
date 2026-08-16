#!/bin/bash
GITHUB_RAW="https://raw.githubusercontent.com/abesskamer237/KATASHIE_VPN/main"

echo "--- Nettoyage et arrêt des services conflictuels ---"
systemctl stop nginx stunnel5 badvpn@7100 badvpn@7200 badvpn@7300 xray ssh 2>/dev/null

echo "--- Téléchargement des protocoles d'installation ---"
wget -q -O /usr/bin/setup_zivpn $GITHUB_RAW/core/setup_zivpn.sh
wget -q -O /usr/bin/setup_udp $GITHUB_RAW/core/setup_udp.sh
wget -q -O /usr/bin/setup_xray $GITHUB_RAW/core/xray.sh
wget -q -O /usr/bin/setup_ssh $GITHUB_RAW/core/sshws.sh

chmod +x /usr/bin/setup_*

echo "--- Téléchargement de l'écosystème complet du Menu ---"
# Téléchargement du binaire principal
wget -q -O /usr/bin/menu $GITHUB_RAW/menu/menu.sh
chmod +x /usr/bin/menu

# Téléchargement de tous les sous-menus nécessaires à l'exécutable
FILES=("zivpn.sh" "vmess.sh" "vless.sh" "update.sh" "trojan.sh" "status.sh" "ssh.sh" "socks.sh" "port.sh" "netguard.sh" "log.sh" "iptools.sh" "expiry.sh" "domain.sh" "dns.sh" "tgbot.sh")

for file in "${FILES[@]}"; do
    # Retirer l'extension .sh pour le nom de la commande (ex: vless.sh devient vless)
    cmd_name=$(echo "$file" | sed 's/\.sh//')
    wget -q -O "/usr/bin/$cmd_name" "$GITHUB_RAW/menu/$file"
    chmod +x "/usr/bin/$cmd_name"
done

echo "--- Exécution des configurations ---"
/usr/bin/setup_xray
/usr/bin/setup_ssh
/usr/bin/setup_zivpn
/usr/bin/setup_udp

# Rafraîchir les chemins du terminal
hash -r

echo "Installation V2 terminée ! Tapez 'menu' pour lancer."
