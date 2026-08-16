#!/bin/bash
UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • UNINSTALL" || clear
printf '%b\n' "${K_RED}╭────────────────────────────────────────────────────────────────╮"
printf '%b\n' "│  DÉSINSTALLATION COMPLÈTE — KATASHIE VPN                     │"
printf '%b\n' "╰────────────────────────────────────────────────────────────────╯${K_RESET}"
printf '%b\n' "${K_YELLOW}⚠ Cette opération supprime les composants installés par KATASHIE.${K_RESET}"
printf '%b\n' "${K_YELLOW}⚠ Elle ne supprime pas OpenSSH ni les fichiers personnels non liés.${K_RESET}"
printf '%b\n' "${K_YELLOW}⚠ Les comptes VPN et données KATASHIE seront perdus.${K_RESET}"
read -r -p " Confirmer la purge complète ? (y/N) : " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { k_info "Désinstallation annulée."; exit 0; }

mkdir -p /var/log/katashie
exec > >(tee -a /var/log/katashie/uninstall.log) 2>&1

stop_disable(){
  local s
  for s in "$@"; do systemctl stop "$s" 2>/dev/null || true; systemctl disable "$s" 2>/dev/null || true; done
}

k_spinner "Arrêt des services KATASHIE" 8
stop_disable xray zivpn katashie_bot katashie-web dropbear stunnel5 ws-dropbear ws-stunnel sshws sshwsssl hysteria-server tuic-server dnstt udp-custom ohp squid nginx

pkill -f '/usr/local/sbin/proxy3.js' 2>/dev/null || true
pkill -f 'proxy3.js' 2>/dev/null || true
tmux kill-session -t sshws 2>/dev/null || true
tmux kill-session -t sshwsssl 2>/dev/null || true

k_spinner "Suppression des unités systemd et tâches automatiques" 8
rm -f /etc/systemd/system/katashie* /etc/systemd/system/xray* /etc/systemd/system/tuic-server.service /etc/systemd/system/hysteria-server.service /etc/systemd/system/dnstt.service
rm -f /etc/systemd/system/ws-dropbear.service /etc/systemd/system/ws-stunnel.service /etc/systemd/system/stunnel5.service /etc/systemd/system/udp-custom.service
rm -f /etc/cron.d/katashie* /etc/cron.d/katashie-web-watchdog
rm -f /usr/local/bin/katashie-web-watchdog.sh /usr/local/sbin/katashie* /usr/local/sbin/proxy3.js
systemctl daemon-reload
systemctl reset-failed

k_spinner "Suppression des données KATASHIE" 8
rm -rf /etc/katashie /etc/katashie_bot /etc/katashie-vpn-web /etc/xray /etc/zivpn /etc/slowdns /etc/tuic /etc/hysteria
rm -rf /opt/katashie /opt/KATASHIE /opt/katashie-vpn-web /root/katashie_core_bot /root/katashie_bot_engine
rm -f /root/katashie.sh /root/domain
rm -rf /root/.acme.sh
rm -f /etc/systemd/system/multi-user.target.wants/katashie_bot.service

k_spinner "Nettoyage Nginx / certificats KATASHIE" 8
rm -f /etc/nginx/sites-enabled/katashie /etc/nginx/sites-available/katashie
rm -f /etc/nginx/conf.d/katashie.conf
rm -rf /etc/letsencrypt
nginx -t >/dev/null 2>&1 || true

k_spinner "Nettoyage des fichiers temporaires" 6
rm -f /tmp/katashie-* /tmp/KATASHIE-* /tmp/katashie-update.*
rm -rf /usr/local/lib/katashie-core /usr/local/lib/katashie-ui.sh

k_ok "Désinstallation KATASHIE VPN terminée."
printf '%b\n' "${K_GREEN}Ports 80/443 restitués aux services restants du VPS.${K_RESET}"
printf '%b\n' "${K_CYAN}Journal de cette purge : /var/log/katashie/uninstall.log${K_RESET}"
rm -f /usr/local/sbin/menu /usr/local/sbin/update /usr/local/sbin/uninstall
exit 0
