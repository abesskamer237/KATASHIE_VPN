#!/bin/bash
clear
LN='\e[34m'
NC='\e[0m'
GR='\e[32m'
RD='\e[31m'
SERVER_HOST="https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main"

echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${GR}       MISE À JOUR OTA (OVER-THE-AIR)             ${NC}${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo -e "\n [*] Connexion au dépôt GitHub central..."
echo -e " [*] Déploiement des modules..."

MODULES=(dns zivpn expiry domain iptools menu socks ssh status trojan vless vmess netguard port log tgbot uninstall update fastdns)

for script in "${MODULES[@]}"; do
    wget -q -O "/usr/local/sbin/$script" "${SERVER_HOST}/menu/${script}.sh"
    chmod +x "/usr/local/sbin/$script"
    echo -e "  -> Module $script [OK]"
done

echo -e "\n${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${LN}┃${NC} ${GR}         MISE À JOUR KATASHIE VPN WEB            ${NC}${LN}┃${NC}"
echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

NEXUS_WEB_DIR="/opt/katashie-tunnel-web"
NEXUS_REPO_URL="https://github.com/RootNexTPro/nexTPro-ScriptAll.git"
NTW_TMP="$(mktemp -d)"

if [ -d "$NEXUS_WEB_DIR" ] && [ -f "$NEXUS_WEB_DIR/dist/server/index.js" ]; then
  echo -e "  -> Panel Nexus Web détecté, mise à jour en cours..."
  if git clone --depth 1 "$NEXUS_REPO_URL" "$NTW_TMP" >/dev/null 2>&1; then
    if [ -d "$NTW_TMP/nexus-web" ]; then
      cp -rf "$NTW_TMP/nexus-web"/. "$NEXUS_WEB_DIR/"
      sed -i "s|const PUBLIC_DIR = .*|const PUBLIC_DIR = '/opt/katashie-tunnel-web/public';|g" \
          "$NEXUS_WEB_DIR/server/index.ts" 2>/dev/null || true
      sed -i 's/callback(null, false);/callback(null, true);/g' \
          "$NEXUS_WEB_DIR/server/index.ts" 2>/dev/null || true
      if [ -d "$NEXUS_WEB_DIR/frontend" ]; then
        cd "$NEXUS_WEB_DIR/frontend" && npm install --quiet >/dev/null 2>&1 && npm run build >/dev/null 2>&1
      fi
      cd "$NEXUS_WEB_DIR" && npm install --production=false --quiet >/dev/null 2>&1 && npm run build >/dev/null 2>&1
      systemctl restart nexus-web 2>/dev/null || true
      echo -e "  -> Nexus Tunnel Web [OK]"
    fi
    rm -rf "$NTW_TMP"
  else
    echo -e "  -> ${RD}[WARN] Impossible de mettre à jour Nexus Web (pas de connexion GitHub)${NC}"
  fi
else
  echo -e "  -> Nexus Tunnel Web non installé, ignoré."
fi

echo -e "\n ${GR}[+] Mise à jour OTA terminée avec succès !${NC}"
sleep 2
menu
