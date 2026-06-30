# ─── XRAY (VLESS, VMESS, TROJAN, SOCKS) ─────────────────────
import subprocess
import re
import json
import base64

XRAY_CONFIG = '/etc/xray/config.json'

def _run(cmd):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return (r.stdout + r.stderr).strip()
    except Exception as e:
        return str(e)

def get_domain():
    return _run("cat /etc/xray/domain 2>/dev/null || echo 'N/A'")

def get_xray_usernames(proto):
    out = _run(f"grep '^#& ' {XRAY_CONFIG} | grep -i {proto} | awk '{{print $2}}'")
    return [u for u in out.splitlines() if u.strip()] if out else []

def create_xray_account(proto, username, days, created_by_id=None):
    if not re.match(r'^[a-zA-Z0-9_]{1,32}$', username):
        return False, "❌ Nom d'utilisateur invalide."
    if not str(days).isdigit():
        return False, "❌ Nombre de jours invalide."

    existing = _run(f"grep -w '{username}' {XRAY_CONFIG} | wc -l")
    if int(existing or 0) > 0:
        return False, f"❌ L'utilisateur <code>{username}</code> existe déjà en {proto.upper()}."

    uuid = _run("cat /proc/sys/kernel/random/uuid").strip()
    exp = _run(f"date -d '+{days} days' +%Y-%m-%d").strip()
    domain = get_domain().strip()

    _run(
        f"sed -i '/#{proto}$/a\\#& {username} {exp} {uuid}\\n"
        f",{{\"id\": \"{uuid}\",\"email\": \"{username}\"' {XRAY_CONFIG} && "
        f"systemctl restart xray"
    )

    if proto == 'vless':
        link_tls = f"vless://{uuid}@{domain}:443?path=/vless&security=tls&encryption=none&type=ws#{username}"
        link_ntls = f"vless://{uuid}@{domain}:80?path=/vless&encryption=none&type=ws#{username}"
        links = f"TLS : <code>{link_tls}</code>\n\nNTLS: <code>{link_ntls}</code>"
    elif proto == 'vmess':
        vmess_obj = json.dumps({
            "v":"2","ps":username,"add":domain,"port":"443","id":uuid,
            "aid":"0","net":"ws","type":"none","host":domain,
            "path":"/vmess","tls":"tls"
        })
        link = "vmess://" + base64.b64encode(vmess_obj.encode()).decode()
        links = f"<code>{link}</code>"
    elif proto == 'trojan':
        link_tls = f"trojan://{uuid}@{domain}:443?type=ws&host={domain}&path=/trojan#{username}"
        links = f"TLS : <code>{link_tls}</code>"
    else:
        links = f"SOCKS5 : <code>{domain}:1080</code>"

    return True, (
        f"✅ <b>Compte {proto.upper()} Créé</b>\n\n"
        f"👤 Utilisateur : <code>{username}</code>\n"
        f"🔑 UUID        : <code>{uuid}</code>\n"
        f"📅 Expiration  : <code>{exp}</code>\n"
        f"🌐 Domaine     : <code>{domain}</code>\n\n"
        f"<b>Liens de connexion:</b>\n{links}"
    )

def renew_xray_account(proto, username, days):
    if not str(days).isdigit():
        return False, "❌ Nombre de jours invalide."
    old_exp = _run(f"grep -E '^#& {username} ' {XRAY_CONFIG} | awk '{{print $3}}' | sort -u | head -1").strip()
    if not old_exp:
        return False, f"❌ Utilisateur <code>{username}</code> introuvable en {proto.upper()}."
    uuid = _run(f"grep -E '^#& {username} ' {XRAY_CONFIG} | awk '{{print $4}}' | sort -u | head -1").strip()
    today = _run("date +%Y-%m-%d").strip()
    d1 = _run(f"date -d '{old_exp}' +%s")
    d2 = _run(f"date -d '{today}' +%s")
    remaining = max(0, (int(d1) - int(d2)) // 86400)
    new_total = remaining + int(days)
    new_exp = _run(f"date -d '+{new_total} days' +%Y-%m-%d").strip()
    _run(f"sed -i '/^#& {username} /c\\#& {username} {new_exp} {uuid}' {XRAY_CONFIG} && systemctl restart xray")
    return True, (
        f"🔄 <b>{proto.upper()} Renouvelé</b>\n\n"
        f"👤 Utilisateur   : <code>{username}</code>\n"
        f"📅 Ancienne exp. : <code>{old_exp}</code>\n"
        f"➕ Jours ajoutés : {days}\n"
        f"📅 Nouvelle exp. : <code>{new_exp}</code>"
    )

def delete_xray_account(proto, username):
    _run(f"sed -i '/^#& {username} /d; /\"email\": \"{username}\"/d' {XRAY_CONFIG} && systemctl restart xray")
    return True, f"🗑️ <b>Compte {proto.upper()} supprimé:</b> <code>{username}</code>"
