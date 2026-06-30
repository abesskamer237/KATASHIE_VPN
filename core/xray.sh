clear
export SERVER_HOST="https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main"
export DEBIAN_FRONTEND=noninteractive
log() { printf "%b
" "[INFO] $*"; }
err() { printf "%b
" "[ERROR] $*" >&2; exit 1; }
apt_install() {
packages=("$@")
if [ ! -f /var/lib/apt/periodic/update-success-stamp ]; then
apt-get update -y
fi
apt-get install -y "${packages[@]}"
}
crontab_append_root() {
local entry="$1"
( crontab -l 2>/dev/null | grep -Fv "$entry"; echo "$entry" ) | crontab -
}
setup_environment() {
log "Gathering environment info"
MYIP=$(wget -qO- --timeout=5 --tries=2 ipv4.icanhazip.com || echo "0.0.0.0")
mkdir -p /etc/xray
log "Installing minimal firewall/time utilities"
apt_install iptables iptables-persistent curl wget
}
setup_ntp_chrony() {
log "Setting date/time and enabling chrony"
apt_install ntpdate chrony
ntpdate -u pool.ntp.org 2>/dev/null
if systemctl list-units --type=service --all | grep -q -E 'chrony|chronyd'; then
if systemctl list-unit-files | grep -q '^chrony.service'; then
systemctl enable --now chrony
systemctl restart chrony
elif systemctl list-unit-files | grep -q '^chronyd.service'; then
systemctl enable --now chronyd
systemctl restart chronyd
fi
fi
timedatectl set-timezone Asia/Kuala_Lumpur
}
install_dependencies() {
log "Installing build/runtime dependencies"
apt-get update -y
apt_install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release unzip pwgen openssl netcat-openbsd cron bash-completion zip
}
install_xray() {
log "Preparing directories for Xray..."
domainSock_dir="/run/xray"
[ -d "$domainSock_dir" ] || mkdir -p "$domainSock_dir"
chown www-data:www-data "$domainSock_dir"
mkdir -p /var/log/xray /etc/xray
chown -R www-data:www-data /var/log/xray
chmod 755 /var/log/xray
for f in access.log error.log access2.log error2.log; do
[ -f "/var/log/xray/$f" ] || touch "/var/log/xray/$f"
done
chown www-data:www-data /var/log/xray/*.log
log "Installing official Xray core..."
bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" -- install -u www-data
log "Replacing official Xray with MOD v25.3.31..."
tmpzip="/tmp/Xray_core_mod.zip"
curl -sL -f "https://github.com/dotywrt/Xray-core-mod/releases/download/v25.3.31/Xray-linux-64-v25.3.31.zip" -o "$tmpzip"
unzip -oq "$tmpzip" -d /tmp || err "Failed to unzip MOD release."
mv -f /tmp/xray /usr/local/bin/xray
chmod +x /usr/local/bin/xray
rm -f "$tmpzip"
[ -x /usr/local/bin/xray ] || err "Xray binary not installed."
log "Xray installation completed."
}
install_ssl() {
if [[ -f /root/domain ]]; then
domain=$(cat /root/domain)
elif [[ -f /etc/xray/domain ]]; then
domain=$(cat /etc/xray/domain)
else
echo -e "${LN}┃${NC} Domain file not found!"
exit 1
fi
log "Stopping nginx for standalone cert issuance"
systemctl stop nginx 2>/dev/null
systemctl stop xray 2>/dev/null
mkdir /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
wget -q -O /usr/local/bin/ssl_renew.sh "${SERVER_HOST}/module/ssl_renew.sh"
chmod +x /usr/local/bin/ssl_renew.sh
crontab_append_root "15 03 */3 * * /usr/local/bin/ssl_renew.sh"
}
configure_xray() {
log "Fetching Xray configuration and systemd units..."
mkdir -p /home/vps/public_html
wget -q -O /etc/xray/config.json "${SERVER_HOST}/module/config.json"
chmod 644 /etc/xray/config.json
chown root:root /etc/xray/config.json
wget -q -O /etc/systemd/system/xray.service "${SERVER_HOST}/module/xray.service"
wget -q -O /etc/systemd/system/runn.service "${SERVER_HOST}/module/runn.service"
systemctl daemon-reload
rm -rf /etc/systemd/system/xray.service.d /etc/systemd/system/xray@.service
}
configure_nginx() {
log "Downloading nginx xray conf"
apt_install nginx
domain=$(cat /root/domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null || err "Domain file not found!")
wget -q -O /etc/nginx/nginx.conf "${SERVER_HOST}/module/nginx.conf"
sleep 3
domain=$(cat /etc/xray/domain)
sed -i "s/server_name \*\.xxxxxx;/server_name *.$domain;/" /etc/nginx/nginx.conf
sed -i "s/server_name xxxxxx;/server_name $domain;/" /etc/nginx/nginx.conf
sed -i "s#https://xxxxxx:86/#https://$domain:86/#" /etc/nginx/nginx.conf
chmod 644 /etc/nginx/nginx.conf
chown root:root /etc/nginx/nginx.conf
systemctl daemon-reload
}
restart_services() {
log "Enabling and restarting services"
systemctl daemon-reload
systemctl enable --now xray nginx runn
systemctl restart xray nginx runn
}
finalize() {
[ -f /root/domain ] && mv /root/domain /etc/xray/
rm -f xray.sh
clear
}
main() {
setup_environment
setup_ntp_chrony
install_dependencies
install_xray
install_ssl
configure_xray
configure_nginx
restart_services
log "XRAY Core Installed Successfully."
sleep 3
finalize
}
main
