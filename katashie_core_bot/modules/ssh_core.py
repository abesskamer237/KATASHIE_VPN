# ─── SSH/WS ──────────────────────────────────────────────────
import subprocess
import re

def _run(cmd):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        return (r.stdout + r.stderr).strip()
    except Exception as e:
        return str(e)

def create_ssh_account(username, password, days, created_by_id=None):
    if not re.match(r'^[a-zA-Z0-9_]{1,32}$', username):
        return False, "❌ Nom d'utilisateur invalide. Lettres, chiffres, underscore uniquement."
    if not str(days).isdigit():
        return False, "❌ Nombre de jours invalide."

    check = subprocess.run(['id', username], capture_output=True)
    if check.returncode == 0:
        return False, f"❌ L'utilisateur <code>{username}</code> existe déjà."

    exp_date = _run(f"date -d '+{days} days' +%Y-%m-%d")
    r = subprocess.run(['useradd', '-e', exp_date, '-s', '/bin/false', '-M', username], capture_output=True)
    if r.returncode != 0:
        return False, f"❌ Erreur useradd: {r.stderr.decode()}"
    subprocess.run(['chpasswd'], input=f"{username}:{password}", text=True, capture_output=True)

    domain = _run("cat /etc/xray/domain 2>/dev/null || echo 'N/A'")
    ip = _run("curl -s4 https://ipv4.icanhazip.com 2>/dev/null || echo 'N/A'")
    dns = _run("cat /etc/slowdns/nsdomain 2>/dev/null || echo 'N/A'")
    pub = _run("cat /etc/slowdns/server.pub 2>/dev/null || echo 'N/A'")

    return True, (
        f"✅ <b>Compte SSH Créé</b>\n\n"
        f"👤 Utilisateur : <code>{username}</code>\n"
        f"🔑 Mot de passe: <code>{password}</code>\n"
        f"📅 Expiration  : <code>{exp_date}</code>\n"
        f"🌐 Domaine     : <code>{domain}</code>\n"
        f"📡 IP          : <code>{ip}</code>\n"
        f"🔗 NS Domaine  : <code>{dns}</code>\n\n"
        f"<b>Ports:</b>\n"
        f"• OpenSSH: 22\n"
        f"• Dropbear: 109, 143\n"
        f"• Stunnel: 447, 777\n"
        f"• WS TLS: 443 / NTLS: 80, 8880\n"
        f"• UDPGW: 7100–7900\n\n"
        f"<b>UDP Custom:</b>\n<code>{domain}:1-65535@{username}:{password}</code>\n\n"
        f"<b>Slow DNS PUB:</b>\n<code>{pub}</code>"
    )

def renew_ssh_account(username, days):
    if not subprocess.run(['id', username], capture_output=True).returncode == 0:
        return False, f"❌ L'utilisateur <code>{username}</code> n'existe pas."
    if not str(days).isdigit():
        return False, "❌ Nombre de jours invalide."

    current_exp = _run(f"chage -l {username} | grep 'Account expires' | awk -F': ' '{{print $2}}'")
    if current_exp == 'never':
        old = _run("date +%s")
    else:
        old = _run(f"date -d '{current_exp} +1 day' +%s")

    new_ts = int(old) + int(days) * 86400
    new_exp = _run(f"date --date='1970-01-01 {new_ts} sec' +%Y-%m-%d")
    _run(f"usermod -e {new_exp} {username}")
    _run(f"passwd -u {username}")

    return True, (
        f"🔄 <b>Compte SSH Renouvelé</b>\n\n"
        f"👤 Utilisateur      : <code>{username}</code>\n"
        f"📅 Ancienne exp.    : <code>{current_exp}</code>\n"
        f"➕ Jours ajoutés   : {days}\n"
        f"📅 Nouvelle exp.    : <code>{new_exp}</code>"
    )

def delete_ssh_account(username):
    _run(f"pkill -u {username}")
    r = subprocess.run(['userdel', '-r', username], capture_output=True)
    if r.returncode == 0:
        return True, f"🗑️ <b>Compte SSH supprimé:</b> <code>{username}</code>"
    return False, f"❌ Erreur: {r.stderr.decode()}"

def lock_ssh_account(username):
    _run(f"passwd -l {username}")
    return True, f"🔒 Compte SSH <code>{username}</code> verrouillé."

def unlock_ssh_account(username):
    _run(f"passwd -u {username}")
    return True, f"🔓 Compte SSH <code>{username}</code> déverrouillé."

def get_ssh_usernames():
    out = _run("awk -F: '$3>=1000 && $1!=\"nobody\" {print $1}' /etc/passwd")
    return [u for u in out.splitlines() if u.strip()] if out else []

def get_ssh_account_details(username):
    exp = _run(f"chage -l {username} | grep 'Account expires' | awk -F': ' '{{print $2}}'")
    status = _run(f"passwd -S {username} | awk '{{print $2}}'")
    ip = _run("curl -s4 https://ipv4.icanhazip.com 2>/dev/null || echo 'N/A'")
    domain = _run("cat /etc/xray/domain 2>/dev/null || echo 'N/A'")
    st = "🔒 Verrouillé" if status == 'L' else "🔓 Actif"
    return True, (
        f"👤 <b>Détails SSH: {username}</b>\n\n"
        f"📅 Expiration: <code>{exp}</code>\n"
        f"🔐 Statut: {st}\n"
        f"🌐 IP: <code>{ip}</code>\n"
        f"🔗 Domaine: <code>{domain}</code>"
    )
