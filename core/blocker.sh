UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
[ -f "$UI" ] && k_header "KATASHIE VPN • BLOCKER" || clear
export TORRENT_HOST="https://raw.githubusercontent.com/dotywrt/block-torrent/main"
export ADBLOCK_HOST="https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt"
export YT_ADBLOCK="https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"
download_trackers() {
echo "[*] Downloading torrent tracker list..."
wget -q -O /etc/trackers "${TORRENT_HOST}/domains"
}
setup_cron_job() {
echo "[*] Setting up daily cron job for blocking torrent + ads..."
cat >/usr/bin/blocker <<'EOF'
export TORRENT_HOST="https://raw.githubusercontent.com/dotywrt/block-torrent/main"
export ADBLOCK_HOST="https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt"
export YT_ADBLOCK="https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"
IFS=$'
'
L=$(/usr/bin/sort /etc/trackers | /usr/bin/uniq)
/sbin/iptables -F TORRENT 2>/dev/null
/sbin/iptables -X TORRENT 2>/dev/null
/sbin/iptables -N TORRENT
for p in {6881..6999} 6969 51413 12345; do
/sbin/iptables -A TORRENT -p tcp --dport "$p" -j DROP
/sbin/iptables -A TORRENT -p udp --dport "$p" -j DROP
done
for fn in $L; do
/sbin/iptables -A TORRENT -d "$fn" -j DROP
done
/sbin/iptables -A INPUT -j TORRENT
/sbin/iptables -A FORWARD -j TORRENT
/sbin/iptables -A OUTPUT -j TORRENT
curl -s -o /tmp/hosts_adblock "${ADBLOCK_HOST}"
curl -s -o /tmp/youtube_hosts "${YT_ADBLOCK}"
cat /tmp/hosts_adblock /tmp/youtube_hosts >> /etc/hosts
sed -i '/^#/d' /etc/hosts
sort -uf /etc/hosts > /etc/hosts.uniq && mv /etc/hosts{.uniq,}
rm -f /tmp/hosts_adblock /tmp/youtube_hosts
EOF
chmod +x /usr/bin/blocker
}
update_hosts() {
echo "[*] Updating /etc/hosts..."
curl -s -LO "${TORRENT_HOST}/Thosts"
cat Thosts >> /etc/hosts
rm -f Thosts
curl -s -o /tmp/hosts_adblock "${ADBLOCK_HOST}"
curl -s -o /tmp/youtube_hosts "${YT_ADBLOCK}"
cat /tmp/hosts_adblock /tmp/youtube_hosts >> /etc/hosts
rm -f /tmp/hosts_adblock /tmp/youtube_hosts
sed -i '/^#/d' /etc/hosts
sort -uf /etc/hosts > /etc/hosts.uniq && mv /etc/hosts{.uniq,}
}
extra_udp_block() {
echo "[*] Blocking suspicious UDP traffic (DHT, PEX, Magnet)..."
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --dport 443 -j ACCEPT    # QUIC/HTTP3
iptables -A OUTPUT -p udp -j DROP
}
cleanup() {
echo "[*] Cleaning up..."
rm -f blocker.sh
}
systemd_blocker() {
SERVICE_FILE="/etc/systemd/system/blocker.service"
cat > "$SERVICE_FILE" <<'EOF'
[Unit]
Description=Torrent + Ads + YouTube Ads Blocker
After=network.target
[Service]
Type=oneshot
ExecStart=/usr/bin/blocker
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable blocker.service
}
install_blocker() {
clear
echo "[*] Installing Torrent + Ads + YouTube Ads Blocker..."
download_trackers
setup_cron_job
update_hosts
extra_udp_block
systemd_blocker
cleanup
echo "[OK] Torrent + Ads + YouTube Ads blocking installed."
}
install_blocker
