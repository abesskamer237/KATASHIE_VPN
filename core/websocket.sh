clear
set -e
echo "[INFO] Checking for tmux..."
if ! command -v tmux >/dev/null 2>&1; then
echo "[WARN] tmux not found, installing..."
apt update -y
apt install -y tmux
else
echo "[INFO] tmux is already installed."
fi
PROXY_JS="/usr/local/sbin/proxy3.js"
if [[ ! -f "$PROXY_JS" ]]; then
echo "[ERROR] $PROXY_JS not found. Downloading..."
wget -q -O "$PROXY_JS" "https://raw.githubusercontent.com/RootNexTPro/nexTPro-ScriptAll/main/module/proxy3.js"
chmod 644 "$PROXY_JS"
else
echo "[INFO] PROXY_JS already installed."
fi
tmux kill-session -t sshws >/dev/null 2>&1 || true
tmux kill-session -t sshwsssl >/dev/null 2>&1 || true
echo "[INFO] Starting tmux session for SSH WS..."
tmux new-session -d -s sshws "node $PROXY_JS -dport 109 -mport 80 -o /root/sshws.log"
echo "[INFO] Starting tmux session for SSH SSL WS..."
tmux new-session -d -s sshwsssl "node $PROXY_JS -dport 109 -mport 700 -o /root/sshwsssl.log"
