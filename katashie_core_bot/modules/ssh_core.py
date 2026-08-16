import subprocess
import os
from datetime import datetime, timedelta

def get_file(path, default="NON_DEFINI"):
    try:
        with open(path, 'r') as f: return f.read().strip()
    except:
        return default

def _server_info():
    domain = get_file('/etc/xray/domain', 'votre-domaine.com')
    pub_key = get_file('/etc/slowdns/server.pub', 'PUB_KEY_NOT_FOUND')
    ns_domain = get_file('/etc/slowdns/nsdomain', 'NS_DOMAIN_NOT_FOUND')
    myip = subprocess.getoutput("wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com")
    return domain, pub_key, ns_domain, myip

def create_ssh_account(user, password, days, created_by_id=None):
    cmd = f"useradd -e $(date -d '{days} days' +'%Y-%m-%d') -s /bin/false -M {user} && echo '{user}:{password}' | chpasswd"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    if res.returncode == 0:
        exp_date = (datetime.now() + timedelta(days=int(days))).strftime("%Y-%m-%d")
        domain, pub_key, ns_domain, myip = _server_info()

        # Enregistrement du compte avec createdById
        db_dir = '/etc/katashie_bot/ssh_accounts'
        os.makedirs(db_dir, exist_ok=True)
        with open(f"{db_dir}/{user}.txt", 'w') as f:
            f.write(f"username={user}\npassword={password}\nexpiry={exp_date}\ncreatedById={created_by_id}\ncreatedAt={datetime.utcnow().isoformat()}Z\nprotocol=ssh\nstatus=active\n")

        msg = (
            f"┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
            f"┃ <b>SSH ACCOUNT DETAILS</b>\n"
            f"┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
            f"👤 <b>Username:</b> <code>{user}</code>\n"
            f"🔑 <b>Password:</b> <code>{password}</code>\n"
            f"⏳ <b>Expiry Date:</b> {exp_date}\n"
            f"🖥️ <b>Host/IP:</b> <code>{myip}</code>\n"
            f"🌐 <b>Domain:</b> <code>{domain}</code>\n"
            f"📛 <b>NS Domain:</b> <code>{ns_domain}</code>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"🔌 <b>Ports:</b>\n"
            f"  OpenSSH(22), Dropbear(109,143)\n"
            f"  Stunnel(447,777), WS(80,443)\n"
            f"  UDPGW(7100-7900), Squid(3128,8880)\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"🚀 <b>UDP Custom:</b>\n"
            f"<code>{myip}:1-65535@{user}:{password}</code>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"🐌 <b>Slow DNS PUB:</b>\n"
            f"<code>{pub_key}</code>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"📦 <b>Payload WS:</b>\n"
            f"<code>GET / HTTP/1.1[crlf]Host: {domain}[crlf]Upgrade: websocket[crlf][crlf]</code>\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"📥 <b>OpenVPN:</b> https://{domain}:2081\n"
        )
        return True, msg
    return False, f"❌ Échec de la création:\n<code>{res.stderr}</code>"

def get_ssh_usernames():
    db_dir = '/etc/katashie_bot/ssh_accounts'
    if not os.path.exists(db_dir):
        return []
    return [f.replace('.txt', '') for f in sorted(os.listdir(db_dir)) if f.endswith('.txt')]

def get_ssh_account_details(user):
    db_file = f"/etc/katashie_bot/ssh_accounts/{user}.txt"
    if not os.path.exists(db_file):
        return False, f"❌ Compte SSH <code>{user}</code> introuvable."
    data = {}
    with open(db_file, 'r') as f:
        for line in f:
            if '=' in line:
                k, v = line.strip().split('=', 1)
                data[k] = v
    password = data.get('password', 'N/A')
    exp_date = data.get('expiry', 'N/A')
    domain, pub_key, ns_domain, myip = _server_info()
    msg = (
        f"┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
        f"┃ <b>SSH ACCOUNT DETAILS</b>\n"
        f"┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"🔑 <b>Password:</b> <code>{password}</code>\n"
        f"⏳ <b>Expiry Date:</b> {exp_date}\n"
        f"🖥️ <b>Host/IP:</b> <code>{myip}</code>\n"
        f"🌐 <b>Domain:</b> <code>{domain}</code>\n"
        f"📛 <b>NS Domain:</b> <code>{ns_domain}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🔌 <b>Ports:</b>\n"
        f"  OpenSSH(22), Dropbear(109,143)\n"
        f"  Stunnel(447,777), WS(80,443)\n"
        f"  UDPGW(7100-7900), Squid(3128,8880)\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🚀 <b>UDP Custom:</b>\n"
        f"<code>{myip}:1-65535@{user}:{password}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🐌 <b>Slow DNS PUB:</b>\n"
        f"<code>{pub_key}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📦 <b>Payload WS:</b>\n"
        f"<code>GET / HTTP/1.1[crlf]Host: {domain}[crlf]Upgrade: websocket[crlf][crlf]</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📥 <b>OpenVPN:</b> https://{domain}:2081\n"
    )
    return True, msg

def renew_ssh_account(user, days):
    if not subprocess.run(f"id {user}", shell=True, capture_output=True).returncode == 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."

    exp_cmd = f"chage -l {user} | grep 'Account expires' | awk -F': ' '{{print $2}}'"
    current_exp = subprocess.run(exp_cmd, shell=True, capture_output=True, text=True).stdout.strip()

    try:
        if current_exp == "never" or not current_exp or current_exp == "password must be changed":
            old_date = datetime.now()
        else:
            old_date = datetime.strptime(current_exp, "%b %d, %Y")
        new_exp = (old_date + timedelta(days=int(days))).strftime("%Y-%m-%d")
    except ValueError:
        new_exp = (datetime.now() + timedelta(days=int(days))).strftime("%Y-%m-%d")

    subprocess.run(f"usermod -e {new_exp} {user}", shell=True)
    subprocess.run(f"passwd -u {user}", shell=True, capture_output=True)

    # Update stored expiry
    db_file = f"/etc/katashie_bot/ssh_accounts/{user}.txt"
    if os.path.exists(db_file):
        with open(db_file, 'r') as f:
            db_lines = f.readlines()
        with open(db_file, 'w') as f:
            for l in db_lines:
                f.write(f"expiry={new_exp}\n" if l.startswith("expiry=") else l)

    ok, details = get_ssh_account_details(user)
    if ok:
        renewal_header = (
            f"✅ <b>COMPTE SSH RENOUVELÉ</b>\n"
            f"📅 <b>Ancienne expiration:</b> {current_exp} → <b>{new_exp}</b>\n\n"
        )
        return True, renewal_header + details
    return True, (
        f"✅ <b>COMPTE SSH RENOUVELÉ</b>\n\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"📅 <b>Ancienne expiration:</b> {current_exp}\n"
        f"➕ <b>Jours ajoutés:</b> {days}\n"
        f"📅 <b>Nouvelle expiration:</b> {new_exp}\n"
    )

def delete_ssh_account(user):
    if subprocess.run(f"id {user}", shell=True, capture_output=True).returncode != 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."

    subprocess.run(f"pkill -u {user}", shell=True, capture_output=True)
    subprocess.run(f"userdel -r {user}", shell=True, capture_output=True)

    db_file = f"/etc/katashie_bot/ssh_accounts/{user}.txt"
    if os.path.exists(db_file):
        os.remove(db_file)

    return True, f"🗑️ <b>Compte SSH <code>{user}</code> supprimé avec succès.</b>"

def lock_ssh_account(user):
    if subprocess.run(f"id {user}", shell=True, capture_output=True).returncode != 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."
    subprocess.run(f"passwd -l {user}", shell=True, capture_output=True)
    return True, f"🔒 <b>Compte <code>{user}</code> verrouillé.</b>"

def unlock_ssh_account(user):
    if subprocess.run(f"id {user}", shell=True, capture_output=True).returncode != 0:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable."
    subprocess.run(f"passwd -u {user}", shell=True, capture_output=True)
    return True, f"🔓 <b>Compte <code>{user}</code> déverrouillé.</b>"

def list_ssh_accounts():
    cmd = "awk -F: '($3 >= 1000 && $1 != \"nobody\") {print $1}' /etc/passwd"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    users = [u for u in res.stdout.strip().split('\n') if u]
    if not users:
        return "📋 Aucun compte SSH trouvé."

    msg = "📋 <b>LISTE DES COMPTES SSH:</b>\n\n"
    for u in users:
        exp_cmd = f"chage -l {u} | grep 'Account expires' | awk -F': ' '{{print $2}}'"
        exp_date = subprocess.run(exp_cmd, shell=True, capture_output=True, text=True).stdout.strip()
        status_cmd = f"passwd -S {u} | awk '{{print $2}}'"
        status = subprocess.run(status_cmd, shell=True, capture_output=True, text=True).stdout.strip()
        lock_icon = "🔒" if status == "L" else "🔓"
        msg += f"{lock_icon} <code>{u}</code> | Exp: <i>{exp_date}</i>\n"
    total = len(users)
    msg += f"\n📊 <b>Total:</b> {total} compte(s)"
    return msg
