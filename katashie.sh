#!/bin/bash
clear
export LN='\033[34m'
export BG='\033[44m'
export NC='\033[0m'
export GR='\033[32m'
export RD='\033[31m'
export MYIP=$(wget -qO- ipv4.icanhazip.com)
UI_LOCAL="/usr/local/lib/katashie-ui.sh"
if [ -f "$UI_LOCAL" ]; then source "$UI_LOCAL"; fi

# --- CONFIGURATION DU DÉPÔT CENTRAL (CORRIGÉ) ---
readonly SERVER_HOST="https://raw.githubusercontent.com/abesskamer237/KATASHIE_VPN/main"
readonly TIMEZONE="Africa/Douala"

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            return 0  
        else
            echo "Unsupported OS: $ID. Exiting."
            exit 1
        fi
    else
        echo "Cannot detect OS. Exiting."
        exit 1
    fi
}

check_root_virt() {
    [ "$EUID" -ne 0 ] && { echo "Run as root"; exit 1; }
    [ "$(systemd-detect-virt)" = "openvz" ] && { echo "OpenVZ is not supported"; exit 1; }
}

setup_host_time() {
    local localip hst host_entry
    localip=$(hostname -I | awk '{print $1}')
    hst=$(hostname)
    host_entry=$(awk '{print $2}' /etc/hosts | grep -w "$hst" || true)
    [ "$hst" != "$host_entry" ] && echo "$localip $hst" >> /etc/hosts
    ln -fs "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
}

prepare_ui() {
    mkdir -p /usr/local/lib
    wget -q -O /usr/local/lib/katashie-ui.sh "${SERVER_HOST}/module/katashie-ui.sh" 2>/dev/null || cp "$(dirname "$0")/module/katashie-ui.sh" /usr/local/lib/katashie-ui.sh 2>/dev/null || true
    chmod 644 /usr/local/lib/katashie-ui.sh 2>/dev/null || true
    [ -f /usr/local/lib/katashie-ui.sh ] && source /usr/local/lib/katashie-ui.sh
}

prepare_env() {
    mkdir -p /etc/xray
    touch /etc/xray/domain
}

function show_tns() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}            TERMS & CONDITIONS PANEL            ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${GR}Welcome to KATASHIE VPN Services!${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} [*] Please read the terms below carefully"
    echo -e "${LN}┃${NC} [*] KATASHIE VPN is provided as-is, no warranties."
    echo -e "${LN}┃${NC} [*] Do not use this service for illegal activities."
    echo -e "${LN}┃${NC} [*] KATASHIE VPN is not liable for data loss or leaks."
    echo -e "${LN}┃${NC} [*] You must follow all applicable laws."
    echo -e "${LN}┃${NC} [*] Terms may change anytime without notice."
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo -e "${LN}┃${NC} [01] • Accept Terms"
    echo -e "${LN}┃${NC} [02] • Decline & Exit"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo
    if [ -r /dev/tty ]; then read -r -p "  Select an option : " opt </dev/tty; else read -r -p "  Select an option : " opt; fi
    echo ""
    case $opt in
    1 | 01)
        clear
        echo -e " ${GR}You have accepted the Terms & Conditions.${NC}"
        echo -e " ${GR}Loading...${NC}"
        sleep 5
        add_domain
        ;;
    2 | 02)
        clear
        echo -e " ${RD}You declined the Terms & Conditions.${NC}"
        echo -e " ${RD}Removing all /root/*.sh scripts and exiting...${NC}"
        rm -f /root/*.sh
        sleep 10
        exit 0
        ;;
    *)
        echo -e "${RD} [ERROR] Invalid selection — veuillez choisir 01 ou 02.${NC}"
        sleep 1
        show_tns
        ;;
    esac
}

function add_domain() {
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo
    while true; do
        if [ -r /dev/tty ]; then read -r -p " Hostname / Domain: " host </dev/tty; else read -r -p " Hostname / Domain: " host; fi
        if [[ -z "$host" ]]; then
            echo -e " ${RD}Domain cannot be empty. Please try again.${NC}"
            continue
        fi
        domain_ip=$(getent ahosts "$host" | awk '{print $1; exit}')
        if [[ "$domain_ip" == "$MYIP" ]]; then
            break
        else
            clear
            echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
            echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
            echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
            echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
            echo -e "${LN}┃${NC} ${RD}✘ Domain does not point to this VPS!${NC}"
            echo -e "${LN}┃${NC} ${RD}Domain resolves to: $domain_ip ${NC}"
            echo -e "${LN}┃${NC} ${RD}VPS public IP is : $MYIP ${NC}"
            echo -e "${LN}┃${NC} ${RD}Please fix your DNS settings and try again.${NC}"
            echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
            echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
            echo ""
            if [ -r /dev/tty ]; then read -n 1 -s -r -p " Press any key to return to the menu..." </dev/tty; else read -n 1 -s -r -p " Press any key to return to the menu..."; fi
            add_domain
            return
        fi
    done
    echo "$host" > /root/domain
    echo "$host" > /etc/xray/domain
    if [[ -f /root/domain ]]; then
        domain=$(cat /root/domain)
    elif [[ -f /etc/xray/domain ]]; then
        domain=$(cat /etc/xray/domain)
    else
        echo -e "${RD} [*] Domain file not found!${NC}"
        rm -f /root/*.sh
        exit 1
    fi
    clear
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}                 DOMAIN PANEL                   ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} Domain has been set successfully!"
    echo -e "${LN}┃${NC} Current Domain: ${domain}"
    echo -e "${LN}┃${NC}                                                    "
    echo -e "${LN}┃${NC} AutoScript Xray by KATASHIE TEAM"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    sleep 4
    echo " [*] Installation started...."
    sleep 3
}

update_system() {
    echo "[INFO] Updating system..."
    apt-get update -y
    apt-get upgrade -y
    apt-get dist-upgrade -y
    apt-get remove --purge -y ufw firewalld exim4 nginx* dropbear* apache2*
    apt autoremove -y
}

install_packages() {
    echo "[INFO] Installing packages..."
    apt-get install -y \
    screen curl jq bzip2 gzip vnstat coreutils rsyslog iftop zip unzip git \
    apt-transport-https build-essential wget figlet ruby-full python3 make cmake \
    net-tools nano sed gnupg gnupg1 bc shc libxml-parser-perl neofetch lsof \
    libsqlite3-dev libz-dev gcc g++ libreadline-dev zlib1g-dev libssl-dev \
    dropbear fail2ban nginx certbot iptables-persistent
    if command -v gem >/dev/null; then
        gem install lolcat >/dev/null
    fi
    if ! dpkg -s nginx >/dev/null 2>&1; then
        echo "[ERROR] nginx failed to install"
        exit 1
    fi
}

run_scripts() {
    mkdir -p /var/log/katashie
    scripts=("xray.sh" "sshws.sh" "vpn.sh" "websocket.sh" "setup_zivpn.sh" "setup_dns.sh" "setup_udp.sh" "validator.sh")
    for script in "${scripts[@]}"; do
        url="${SERVER_HOST}/core/${script}"
        log_file="/var/log/katashie/${script}.log"
        printf '%b\n' "${K_CYAN}  ◐ Téléchargement ${script}...${K_RESET}"
        if ! wget -q --timeout=30 --tries=3 "$url" -O "$script"; then
            printf '%b\n' "${K_RED}  ✘ Impossible de télécharger ${script}${K_RESET}"
            return 1
        fi
        chmod +x "$script"
        : > "$log_file"
        printf '%b' "${K_YELLOW}  ◐ Exécution ${script}...${K_RESET}"
        if [ "$script" = "setup_dns.sh" ]; then
            # SlowDNS demande volontairement le domaine et le NS Domain à l'utilisateur.
            if bash "./$script" >"$log_file" 2>/dev/tty; then rc=0; else rc=$?; fi
            printf '\r%b\n' "${K_GREEN}  ✔ ${script} terminé${K_RESET}"
        else
            # Les sorties normales restent dans le journal afin de garder le terminal propre.
            # Un spinner animé confirme toutefois que le composant travaille réellement.
            timeout --signal=TERM --kill-after=10s 30m bash "./$script" >"$log_file" 2>&1 &
            child_pid=$!
            frames=('◐' '◓' '◑' '◒')
            frame=0
            while kill -0 "$child_pid" 2>/dev/null; do
                printf '\r%b' "${K_CYAN}  ${frames[$frame]} Exécution ${script}...${K_RESET}"
                frame=$(( (frame + 1) % 4 ))
                sleep 0.25
            done
            wait "$child_pid"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf '\r%b\n' "${K_GREEN}  ✔ ${script} terminé${K_RESET}"
            else
                printf '\r%b\n' "${K_RED}  ✘ ${script} a échoué (code ${rc})${K_RESET}"
                printf '%b\n' "${K_RED}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${K_RESET}"
                printf '%b\n' "${K_RED}┃ ERREUR — détails techniques : ${script}${K_RESET}"
                printf '%b\n' "${K_RED}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${K_RESET}"
                tail -n 45 "$log_file" 2>/dev/null || true
                printf '%b\n' "${K_YELLOW}Journal complet : ${log_file}${K_RESET}"
                return "$rc"
            fi
        fi
        [ "$rc" -eq 0 ] || { tail -n 45 "$log_file" 2>/dev/null || true; return "$rc"; }
    done
}

install_menu() {
    mkdir -p /usr/local/sbin
    for script in dns zivpn expiry domain iptools menu socks ssh status trojan vless vmess netguard port log tgbot uninstall update web fastdns; do
        tmp="/tmp/katashie-menu-${script}"
        if ! wget -q --timeout=30 --tries=3 -O "$tmp" "${SERVER_HOST}/menu/${script}.sh"; then
            printf '%b\n' "${K_RED}  ✘ Échec du téléchargement du module menu/${script}.sh${K_RESET}"
            return 1
        fi
        install -m 755 "$tmp" "/usr/local/sbin/$script"
        rm -f "$tmp"
    done
    k_ok "Modules du menu installés."
}

setup_autoreboot() {
    grep -q "shutdown -r now" /etc/crontab || \
    echo "0 0 * * * root /sbin/shutdown -r now" >> /etc/crontab
}

setup_autolog() {
    grep -q "/usr/local/sbin/log" /etc/crontab || \
    echo "*/30 * * * * root /usr/local/sbin/log" >> /etc/crontab
}

setup_autoexp() {
    local cronjob="55 23 * * * root /usr/local/sbin/expiry"
    grep -q "/usr/local/sbin/expiry" /etc/crontab || echo "$cronjob" >> /etc/crontab
}

setup_profile() {
    cat > /root/.profile <<'EOF'
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
clear
menu
EOF
    echo "[*] Profile configured"
}

cleanner() {
    rm -f ./*.sh /root/*.pem 2>/dev/null
}

restart_services() {
    echo "[*] Enabling and restarting all system services..."
    SERVICES=(
        ssh
        dropbear
        stunnel5
        cron
        nginx
        vnstat
        fail2ban
        ws-dropbear
        ws-stunnel
        xray
        runn
        squid
        openvpn
        ohp
        zivpn
        dnstt
        udp-custom
    )
    for svc in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$svc.service"; then
            echo "[INFO] Restarting $svc..."
            systemctl enable "$svc" --now || echo "[WARN] Failed to enable $svc"
            systemctl restart "$svc" || echo "[WARN] Failed to restart $svc"
        fi
    done
    for port in 7100 7200 7300; do
        svc="badvpn@$port"
        if systemctl list-unit-files | grep -q "^$svc.service"; then
            echo "[INFO] Restarting $svc..."
            systemctl enable "$svc" --now || echo "[WARN] Failed to enable $svc"
            systemctl restart "$svc" || echo "[WARN] Failed to restart $svc"
        fi
    done
    echo "[INFO] All services have been enabled and restarted successfully."
}

doty_completed() {
    clear
    domain=$(cat /etc/xray/domain)
    MYIP=$(wget -qO- ipv4.icanhazip.com)
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${BG}              INSTALLATION COMPLETE               ${NC} ${LN}┃${NC}"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${LN}┃${NC} ${GR}Congratulations! KATASHIE VPN is ready.${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} Domain: ${domain}"
    echo -e "${LN}┃${NC} VPS IP: ${MYIP}"
    echo -e "${LN}┃${NC} Enjoy secure VPN services!${NC}"
    echo -e "${LN}┃${NC} AutoScript Xray by KATASHIE TEAM"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
    echo
}

set_version() {
    wget -q "$SERVER_HOST/version" -O /etc/version
    wget -q "$SERVER_HOST/port_info" -O /etc/xray/port_info
}

enable_bbr() {
    sudo sysctl -w net.core.default_qdisc=fq
    sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
    grep -q "net.core.default_qdisc" /etc/sysctl.conf || echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
    grep -q "net.ipv4.tcp_congestion_control" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

main() {
    check_root_virt
    check_os
    [ -f /usr/local/lib/katashie-ui.sh ] && k_brand || true
    setup_host_time
    prepare_ui
    prepare_env
    update_system
    install_packages
    show_tns
    run_scripts
    install_menu
    setup_profile
    setup_autoreboot
    setup_autolog
    setup_autoexp
    enable_bbr
    restart_services
    set_version
    doty_completed
    cleanner
    echo -e "${GR}Installation finished successfully.${NC}"
    echo -e "${GR}KATASHIE VPN is ready. A reboot is recommended, but it is not forced.${NC}"
}

main
