#!/bin/bash
# ============================================================
#   KATASHIE VPN — Auto Installer Bootstrap
#   Compatible: Ubuntu 22.04 / Debian 11+
#   Usage: wget -qO- https://raw.githubusercontent.com/abesskamer237/KATASHIE_VPN/main/autoinstall.sh | bash
# ============================================================

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TIMESTAMP() { date '+%Y-%m-%d %H:%M:%S'; }
log_info()    { echo -e "${BLUE}[$(TIMESTAMP)] [INFO]${NC}    $*"; }
log_success() { echo -e "${GREEN}[$(TIMESTAMP)] [SUCCESS]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[$(TIMESTAMP)] [WARN]${NC}    $*"; }
log_error()   { echo -e "${RED}[$(TIMESTAMP)] [ERROR]${NC}   $*"; }

progress_bar() {
    local duration=$1
    local label="${2:-Loading}"
    local width=40
    echo -ne "${BLUE}${label}${NC} ["
    for ((i=0; i<=width; i++)); do
        echo -ne "${BLUE}=${NC}"
        sleep $(echo "scale=4; $duration/$width" | bc)
    done
    echo -e "] ${GREEN}DONE${NC}"
}

clear
echo -e "${BLUE}"
cat << 'BANNER'
 ██╗  ██╗ █████╗ ████████╗ █████╗ ███████╗██╗  ██╗██╗███████╗
 ██║ ██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██║  ██║██║██╔════╝
 █████╔╝ ███████║   ██║   ███████║███████╗███████║██║█████╗
 ██╔═██╗ ██╔══██║   ██║   ██╔══██║╚════██║██╔══██║██║██╔══╝
 ██║  ██╗██║  ██║   ██║   ██║  ██║███████║██║  ██║██║███████╗
 ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝
                          V P N
BANNER
echo -e "${NC}"
echo -e "${WHITE}════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}   Commercial VPN Auto-Installer — KATASHIE VPN     ${NC}"
echo -e "${WHITE}════════════════════════════════════════════════════${NC}"
echo ""

# Dépôt central KATASHIE VPN (à mettre à jour avec votre repo)
SERVER_HOST="https://raw.githubusercontent.com/abesskamer237/KATASHIE_VPN/main"

log_info "Mise à jour des outils de base..."
apt-get update -y >/dev/null 2>&1
apt-get install -y wget curl bc >/dev/null 2>&1
log_success "Outils installés."

log_info "Optimisation des routes réseau (IPv4 prioritaire)..."
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf 2>/dev/null || true
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
log_success "Réseau optimisé."

log_info "Téléchargement du lanceur principal KATASHIE VPN..."
if wget -qO /root/katashie.sh "$SERVER_HOST/katashie.sh"; then
    log_success "Fichier noyau téléchargé avec succès."
    chmod +x /root/katashie.sh
    log_info "Lancement de l'installation KATASHIE VPN..."
    bash /root/katashie.sh
else
    log_error "ERREUR FATALE: Impossible d'atteindre le dépôt KATASHIE VPN."
    log_error "Vérifiez votre connexion internet et réessayez."
    exit 1
fi
