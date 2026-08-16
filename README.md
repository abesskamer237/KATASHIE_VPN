# KATASHIE VPN ⚡

> **Premium VPS VPN automation • multi-protocol • terminal control • web panel**
>
> **KATASHIE VPN** is an adapted deployment of the supplied reference project, keeping its protocol/install logic while replacing the project identity, repository endpoints and presentation with the KATASHIE VPN identity.

<div align="center">

```text
██╗  ██╗ █████╗ ████████╗ █████╗ ███████╗██╗  ██╗██╗███████╗
██║ ██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██║  ██║██║██╔════╝
█████╔╝ ███████║   ██║   ███████║███████╗███████║██║█████╗
██╔═██╗ ██╔══██║   ██║   ██╔══██║╚════██║██╔══██║██║██╔══╝
██║  ██╗██║  ██║   ██║   ██║  ██║███████║██║  ██║██║███████╗
╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝

             KATASHIE VPN • PREMIUM SERVER CONTROL
```

![Version](https://img.shields.io/badge/KATASHIE_VPN-1.3.0-00d084?style=for-the-badge)
![Shell](https://img.shields.io/badge/SHELL-BASH-111827?style=for-the-badge)
![Ubuntu](https://img.shields.io/badge/UBUNTU-20%2F22%2F24-111827?style=for-the-badge)
![Debian](https://img.shields.io/badge/DEBIAN-10%2F11%2F12-111827?style=for-the-badge)

</div>

## 🚀 Installation en une commande

```bash
curl -fsSL https://raw.githubusercontent.com/abesskamer237/KATASHIE_VPN/main/autoinstall.sh | sudo bash
```

Alternative :

```bash
wget -qO /tmp/katashie-install.sh https://raw.githubusercontent.com/abesskamer237/KATASHIE_VPN/main/autoinstall.sh && sudo bash /tmp/katashie-install.sh
```

> **Conseil :** exécutez l'installation sur un VPS propre. Le script référence les composants du dépôt KATASHIE VPN et prépare les services nécessaires.

## 🎨 Interface terminal

Le menu reprend le style terminal de référence :

- cadre vert haute visibilité ;
- barre de titre rouge ;
- séparateurs cyan / magenta / jaune ;
- signature ASCII **KATASHIE** animée à l'entrée ;
- indicateurs de services `ON/OFF` ;
- animations de chargement et de progression ;
- menus numérotés compatibles avec les commandes existantes.

## 🧩 Protocoles / composants

Le projet fourni conserve les modules de référence pour :

- SSH / WebSocket / SSL WebSocket
- Xray
- VMess
- VLESS
- Trojan
- SOCKS
- OpenVPN TCP/UDP
- Squid
- OHP
- ZIVPN
- SlowDNS / DNSTT
- UDP Custom
- BadVPN UDP Gateway
- Nginx
- BBR
- Bot Telegram
- Panneau Web KATASHIE VPN

Les versions et dépendances externes utilisées par les modules restent celles du projet source fourni ; elles ne sont pas remplacées arbitrairement.

## 🖥️ Commandes principales

| Commande | Fonction |
|---|---|
| `menu` | Ouvre le panneau KATASHIE VPN |
| `update` | Met à jour les modules depuis le dépôt KATASHIE |
| `uninstall` | Désinstallation complète |
| `status` | État des services |
| `domain` | Configuration du domaine |
| `port` | Informations des ports |
| `log` | Gestion des journaux |
| `web` | Panneau Web |

## 🔄 Mise à jour

Le dépôt officiel du projet adapté est :

`https://github.com/abesskamer237/KATASHIE_VPN.git`

Le module `update` recharge les scripts du menu depuis le même dépôt. Le principe est volontairement **in-place** : une mise à jour remplace les fichiers de code sans demander une désinstallation complète.

## 🧪 Vérification avant production

Après installation :

```bash
systemctl --failed
ss -lntup
systemctl status nginx --no-pager
systemctl status xray --no-pager
systemctl status ws-stunnel --no-pager
```

Pour vérifier les erreurs :

```bash
journalctl -p err -b --no-pager
```

## 📁 Architecture

```text
KATASHIE_VPN/
├── autoinstall.sh
├── katashie.sh
├── core/
│   ├── sshws.sh
│   ├── xray.sh
│   ├── vpn.sh
│   ├── websocket.sh
│   ├── setup_zivpn.sh
│   ├── setup_dns.sh
│   └── setup_udp.sh
├── menu/
├── module/
│   ├── nginx.conf
│   ├── config.json
│   ├── proxy3.js
│   └── katashie-ui.sh
├── katashie-web/
└── katashie_core_bot/
```

## ⚠️ Important

Ce dépôt doit être utilisé conformément aux lois applicables et aux conditions de votre hébergeur. Les modules réseau peuvent modifier des services système, le pare-feu, Nginx et les ports du VPS.

**KATASHIE VPN • KATASHIE TEAM**


## Correctifs d'installation — 2026-08-16

- L'installation lancée avec `curl ... | sudo bash` conserve désormais l'entrée interactive via `/dev/tty`.
- Le choix des conditions `01/02` ne reçoit plus EOF depuis le pipe.
- Le champ **NS Domain** de SlowDNS lit également directement le terminal.
- Xray est préparé avant SSH/WebSocket afin que les certificats TLS existent avant la configuration Nginx.
- La configuration Nginx est validée avec `nginx -t` avant démarrage et le domaine est injecté automatiquement.
- Les étapes longues affichent maintenant une animation de progression sans déverser les logs normaux dans le terminal.
- Les journaux détaillés restent disponibles uniquement lorsqu'une étape échoue.
