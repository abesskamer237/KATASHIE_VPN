import subprocess
import os
from datetime import datetime, timedelta

def get_file(path, default="NON_DEFINI"):
    try:
        with open(path, 'r') as f: return f.read().strip()
    except:
        return default

def create_zivpn_account(user, password, days, created_by_id=None):
    db_file = '/etc/zivpn/user.db'
    conf_file = '/etc/zivpn/config.json'

    if not os.path.exists(conf_file):
        return False, "❌ Fichier config ZIVPN introuvable. Le VPS est-il bien configuré ?"

    # Vérification des doublons
    try:
        with open(db_file, 'r') as f:
            content = f.read()
            if user in content or password in content:
                return False, "❌ Nom d'utilisateur ou Mot de passe déjà utilisé."
    except Exception:
        pass

    days = int(days)
    exp_date = (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")

    # Injection dans le JSON ZIVPN
    with open(conf_file, 'r') as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        new_lines.append(line)
        if '"config": [' in line:
            new_lines.append(f'      "{password}",\n')

    with open(conf_file, 'w') as f:
        f.writelines(new_lines)

    # Nettoyage de la virgule finale JSON
    with open(conf_file, 'r') as f:
        raw = f.read()
    import re
    raw = re.sub(r',(\s*\])', r'\1', raw)
    with open(conf_file, 'w') as f:
        f.write(raw)

    # Ajout dans la base de données
    with open(db_file, 'a') as f:
        f.write(f"{user} {password} {exp_date}\n")

    subprocess.run("systemctl restart zivpn", shell=True)

    # Enregistrement avec createdById
    meta_dir = '/etc/katashie_bot/zivpn_accounts'
    os.makedirs(meta_dir, exist_ok=True)
    with open(f"{meta_dir}/{user}.txt", 'w') as f:
        f.write(f"username={user}\npassword={password}\nexpiry={exp_date}\ncreatedById={created_by_id}\ncreatedAt={datetime.utcnow().isoformat()}Z\nprotocol=zivpn\nstatus=active\n")

    domain = get_file('/etc/xray/domain', 'votre-domaine.com')
    myip = subprocess.getoutput("wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com")

    msg = (
        f"┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
        f"┃ <b>ZIVPN ACCOUNT DETAILS</b>\n"
        f"┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"🔑 <b>Password:</b> <code>{password}</code>\n"
        f"⏳ <b>Expiry Date:</b> {exp_date}\n"
        f"🖥️ <b>IPV4:</b> <code>{myip}</code>\n"
        f"🌐 <b>Domain:</b> <code>{domain}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )
    return True, msg

def get_zivpn_usernames():
    meta_dir = '/etc/katashie_bot/zivpn_accounts'
    if not os.path.exists(meta_dir):
        return []
    return [f.replace('.txt', '') for f in sorted(os.listdir(meta_dir)) if f.endswith('.txt')]

def get_zivpn_account_details(user):
    meta_file = f"/etc/katashie_bot/zivpn_accounts/{user}.txt"
    if not os.path.exists(meta_file):
        return False, f"❌ Compte ZIVPN <code>{user}</code> introuvable."
    data = {}
    with open(meta_file, 'r') as f:
        for line in f:
            if '=' in line:
                k, v = line.strip().split('=', 1)
                data[k] = v
    password = data.get('password', 'N/A')
    exp_date = data.get('expiry', 'N/A')
    domain = get_file('/etc/xray/domain', 'votre-domaine.com')
    myip = subprocess.getoutput("wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com")
    msg = (
        f"┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
        f"┃ <b>ZIVPN ACCOUNT DETAILS</b>\n"
        f"┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"🔑 <b>Password:</b> <code>{password}</code>\n"
        f"⏳ <b>Expiry Date:</b> {exp_date}\n"
        f"🖥️ <b>IPV4:</b> <code>{myip}</code>\n"
        f"🌐 <b>Domain:</b> <code>{domain}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )
    return True, msg

def renew_zivpn_account(user, days):
    db_file = '/etc/zivpn/user.db'
    if not os.path.exists(db_file):
        return False, "❌ Base ZIVPN introuvable."

    with open(db_file, 'r') as f:
        lines = f.readlines()

    current_exp = None
    new_lines = []
    found = False
    days = int(days)

    for line in lines:
        parts = line.strip().split()
        if len(parts) >= 3 and parts[0] == user:
            current_exp = parts[2]
            try:
                base_date = datetime.strptime(current_exp, "%Y-%m-%d")
                if base_date < datetime.now():
                    base_date = datetime.now()
            except ValueError:
                base_date = datetime.now()
            new_exp = (base_date + timedelta(days=days)).strftime("%Y-%m-%d")
            new_lines.append(f"{parts[0]} {parts[1]} {new_exp}\n")
            found = True
        else:
            new_lines.append(line)

    if not found:
        return False, f"❌ Utilisateur ZIVPN <code>{user}</code> introuvable."

    with open(db_file, 'w') as f:
        f.writelines(new_lines)

    # Update meta file
    meta_file = f"/etc/katashie_bot/zivpn_accounts/{user}.txt"
    if os.path.exists(meta_file):
        with open(meta_file, 'r') as f:
            meta_lines = f.readlines()
        with open(meta_file, 'w') as f:
            for l in meta_lines:
                f.write(f"expiry={new_exp}\n" if l.startswith("expiry=") else l)

    ok, details = get_zivpn_account_details(user)
    if ok:
        renewal_header = (
            f"✅ <b>COMPTE ZIVPN RENOUVELÉ</b>\n"
            f"📅 <b>Ancienne expiration:</b> {current_exp} → <b>{new_exp}</b>\n\n"
        )
        return True, renewal_header + details
    return True, (
        f"✅ <b>COMPTE ZIVPN RENOUVELÉ</b>\n\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"📅 <b>Ancienne expiration:</b> {current_exp}\n"
        f"➕ <b>Jours ajoutés:</b> {days}\n"
        f"📅 <b>Nouvelle expiration:</b> {new_exp}\n"
    )

def delete_zivpn_account(user):
    db_file = '/etc/zivpn/user.db'
    conf_file = '/etc/zivpn/config.json'

    if not os.path.exists(db_file):
        return False, "❌ Base ZIVPN introuvable."

    with open(db_file, 'r') as f:
        lines = f.readlines()

    password = None
    new_lines = []
    for line in lines:
        parts = line.strip().split()
        if len(parts) >= 2 and parts[0] == user:
            password = parts[1]
        else:
            new_lines.append(line)

    if password is None:
        return False, f"❌ Utilisateur ZIVPN <code>{user}</code> introuvable."

    with open(db_file, 'w') as f:
        f.writelines(new_lines)

    # Supprimer le mot de passe de la config JSON
    if os.path.exists(conf_file):
        with open(conf_file, 'r') as f:
            content = f.read()
        import re
        content = re.sub(rf'[ \t]*"{re.escape(password)}",?\n?', '', content)
        content = re.sub(r',(\s*\])', r'\1', content)
        with open(conf_file, 'w') as f:
            f.write(content)

    subprocess.run("systemctl restart zivpn", shell=True)

    meta_file = f"/etc/katashie_bot/zivpn_accounts/{user}.txt"
    if os.path.exists(meta_file):
        os.remove(meta_file)

    return True, f"🗑️ <b>Compte ZIVPN <code>{user}</code> supprimé avec succès.</b>"

def list_zivpn_accounts():
    db_file = '/etc/zivpn/user.db'
    if not os.path.exists(db_file):
        return "📋 Aucun compte ZIVPN trouvé."

    with open(db_file, 'r') as f:
        lines = f.readlines()

    if not lines:
        return "📋 Aucun compte ZIVPN trouvé."

    msg = "📋 <b>LISTE DES COMPTES ZIVPN:</b>\n\n"
    count = 0
    for line in lines:
        parts = line.strip().split()
        if len(parts) >= 3:
            msg += f"👤 <code>{parts[0]}</code> | Pass: <code>{parts[1]}</code> | Exp: <i>{parts[2]}</i>\n"
            count += 1
    msg += f"\n📊 <b>Total:</b> {count} compte(s)"
    return msg
