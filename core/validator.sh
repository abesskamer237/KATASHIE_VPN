export SERVER_HOST="https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main"
CONF_DIR="/etc/nginx"
configure_nginx() {
echo "Downloading nginx xray conf..."
domain=$(cat /root/domain 2>/dev/null || cat /etc/xray/domain 2>/dev/null)
wget -q -O /etc/nginx/nginx.conf "${SERVER_HOST}/module/nginx.conf"
sleep 3
sed -i "s/server_name \*\.xxxxxx;/server_name *.$domain;/" /etc/nginx/nginx.conf
sed -i "s/server_name xxxxxx;/server_name $domain;/" /etc/nginx/nginx.conf
sed -i "s#https://xxxxxx:2081/#https://$domain:2081/#" /etc/nginx/nginx.conf
chmod 644 /etc/nginx/nginx.conf
chown root:root /etc/nginx/nginx.conf
systemctl daemon-reload
}
if [[ ! -f /etc/nginx/nginx.conf ]]; then
configure_nginx
else
echo "[*] All config files already exist. Skipping download."
fi
