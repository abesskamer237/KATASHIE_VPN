# ─── ZIVPN ────────────────────────────────────────────────────
import subprocess
import re

ZIVPN_DB = '/etc/zivpn/users.db'

def _run(cmd):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return (r.stdout + r.stderr).strip()
    except Exception as e:
        return str(e)

def create_zivpn_account(username, password, days, created_by_id=None):
    if not re.match(r'^[a-zA-Z0-9_]{1,32}$', username):
        return False, "❌ Nom d'utilisateur invalide."
    if not str(days).isdigit():
        return False, "❌ Nombre de jours invalide."
    exp = _run(f"date -d '+{days} days' +%Y-%m-%d").strip()
    _run(f"echo '{username}:{password}:{exp}' >> {ZIVPN_DB} && systemctl restart zivpn")
    return True, (
        f"✅ <b>Compte ZIVPN Créé</b>\n\n"
        f"👤 Utilisateur : <code>{username}</code>\n"
        f"🔑 Mot de passe: <code>{password}</code>\n"
        f"📅 Expiration  : <code>{exp}</code>"
    )

def renew_zivpn_account(username, days):
    if not str(days).isdigit():
        return False, "❌ Nombre de jours invalide."
    _run(f"sed -i '/^{username}:/d' {ZIVPN_DB}")
    exp = _run(f"date -d '+{days} days' +%Y-%m-%d").strip()
    password = "renouvele"
    _run(f"echo '{username}:{password}:{exp}' >> {ZIVPN_DB} && systemctl restart zivpn")
    return True, f"🔄 Compte ZIVPN <code>{username}</code> renouvelé jusqu'au <code>{exp}</code>."

def delete_zivpn_account(username):
    _run(f"sed -i '/^{username}:/d' {ZIVPN_DB} && systemctl restart zivpn")
    return True, f"🗑️ Compte ZIVPN <code>{username}</code> supprimé."
