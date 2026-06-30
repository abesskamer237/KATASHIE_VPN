# ─── Système ─────────────────────────────────────────────────
import subprocess

def _run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return (r.stdout + r.stderr).strip()
    except subprocess.TimeoutExpired:
        return "⏱️ Délai dépassé."
    except Exception as e:
        return f"❌ Erreur: {e}"

def get_vps_status():
    uptime = _run("uptime -p")
    load = _run("cat /proc/loadavg | awk '{print $1, $2, $3}'")
    mem = _run("free -m | awk 'NR==2{printf \"%sMB / %sMB (%.1f%%)\", $3, $2, $3/$2*100}'")
    disk = _run("df -h / | awk 'NR==2{printf \"%s / %s (%s)\", $3, $2, $5}'")
    domain = _run("cat /etc/xray/domain 2>/dev/null || echo 'N/A'")
    ip = _run("curl -s4 https://ipv4.icanhazip.com 2>/dev/null || echo 'N/A'")
    services = {
        'nginx': _run("systemctl is-active nginx"),
        'xray': _run("systemctl is-active xray"),
        'dropbear': _run("systemctl is-active dropbear"),
        'openvpn': _run("systemctl is-active openvpn"),
        'zivpn': _run("systemctl is-active zivpn"),
    }
    svc_lines = "\n".join([f"  • {k}: {'🟢' if v=='active' else '🔴'} {v}" for k, v in services.items()])
    return (
        f"📊 <b>STATUT VPS — KATASHIE VPN</b>\n\n"
        f"🌐 IP: <code>{ip}</code>\n"
        f"🔗 Domaine: <code>{domain}</code>\n"
        f"⏱️ Uptime: {uptime}\n"
        f"⚙️ Load: {load}\n"
        f"🧠 RAM: {mem}\n"
        f"💾 Disque: {disk}\n\n"
        f"🔧 Services:\n{svc_lines}"
    )

def clean_system_logs():
    _run("truncate -s 0 /var/log/auth.log 2>/dev/null")
    _run("truncate -s 0 /var/log/syslog 2>/dev/null")
    _run("journalctl --rotate 2>/dev/null; journalctl --vacuum-time=1d 2>/dev/null")
    _run("truncate -s 0 /var/log/xray/access.log 2>/dev/null")
    _run("truncate -s 0 /var/log/xray/error.log 2>/dev/null")
    return "🧹 <b>Journaux nettoyés avec succès.</b>"
