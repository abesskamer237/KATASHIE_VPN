UI="/usr/local/lib/katashie-ui.sh"; [ -f "$UI" ] && source "$UI"
set -e
source /etc/os-release
kernel_version=$(uname -r)
delete_old_kernels() {
if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
old_kernels=$(dpkg -l | awk '/linux-image/ {print $2}' | grep -v "$kernel_version")
total_old=$(echo "$old_kernels" | wc -l)
if [ "$total_old" -gt 0 ]; then
echo "Detected $total_old old kernel(s), starting removal..."
for k in $old_kernels; do
echo "Removing kernel: $k ..."
apt-get purge -y "$k"
echo "Finished removing $k."
done
else
echo "No old kernels to remove."
fi
fi
}
update_grub() {
if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
echo "Updating GRUB..."
update-grub
fi
}
remove_sysctl_settings() {
local patterns=(
"net.core.default_qdisc"
"net.ipv4.tcp_congestion_control"
"fs.file-max"
"net.core.rmem_max"
"net.core.wmem_max"
"net.core.rmem_default"
"net.core.wmem_default"
"net.core.netdev_max_backlog"
"net.core.somaxconn"
"net.ipv4.tcp_syncookies"
"net.ipv4.tcp_tw_reuse"
"net.ipv4.tcp_tw_recycle"
"net.ipv4.tcp_fin_timeout"
"net.ipv4.tcp_keepalive_time"
"net.ipv4.ip_local_port_range"
"net.ipv4.tcp_max_syn_backlog"
"net.ipv4.tcp_max_tw_buckets"
"net.ipv4.tcp_rmem"
"net.ipv4.tcp_wmem"
"net.ipv4.tcp_mtu_probing"
"net.ipv4.ip_forward"
"fs.inotify.max_user_instances"
"net.ipv4.route.gc_timeout"
"net.ipv4.tcp_synack_retries"
"net.ipv4.tcp_syn_retries"
"net.ipv4.tcp_timestamps"
"net.ipv4.tcp_max_orphans"
)
for p in "${patterns[@]}"; do
sed -i "/$p/d" /etc/sysctl.conf
done
sleep 1
}
remove_sysctl_settings
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf
mkdir -p bbrplus && cd bbrplus
wget -q --no-check-certificate https://github.com/dotywrt/BBRplus/releases/download/5.15.96/Debian-Ubuntu_Optional_linux-headers-5.15.96-bbrplus_5.15.96-bbrplus-1_amd64.deb
wget -q --no-check-certificate https://github.com/dotywrt/BBRplus/releases/download/5.15.96/Debian-Ubuntu_Required_linux-image-5.15.96-bbrplus_5.15.96-bbrplus-1_amd64.deb
dpkg -i Debian-Ubuntu_Optional_linux-headers-5.15.96-bbrplus_5.15.96-bbrplus-1_amd64.deb
dpkg -i Debian-Ubuntu_Required_linux-image-5.15.96-bbrplus_5.15.96-bbrplus-1_amd64.deb
cd .. && rm -rf bbrplus
delete_old_kernels
update_grub
sysctl -p
echo "Done! BBRplus installed and old kernels removed."
