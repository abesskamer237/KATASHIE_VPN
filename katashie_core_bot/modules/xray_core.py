import uuid
import base64
import subprocess
from datetime import datetime, timedelta
import os
import re

XRAY_CONF = '/etc/xray/config.json'

def get_domain():
    try:
        with open('/etc/xray/domain', 'r') as f: return f.read().strip()
    except:
        return "votre-domaine.com"

def create_xray_account(protocol, user, days, created_by_id=None):
    if not os.path.exists(XRAY_CONF):
        return False, "❌ Fichier config Xray introuvable."

    days = int(days)
    exp_date = (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")
    client_id = str(uuid.uuid4())
    domain = get_domain()

    # 1. LECTURE SÉCURISÉE
    with open(XRAY_CONF, 'r') as f:
        lines = f.readlines()

    new_lines = []
    injected = False

    # 2. INJECTION CHIRURGICALE STYLE "SED"
    for line in lines:
        new_lines.append(line)
        clean_line = line.strip()

        if protocol == 'vless':
            if clean_line in ('#vless', '#vlessgrpc'):
                new_lines.append(f'#& {user} {exp_date} {client_id}\n')
                new_lines.append(f'}},{{"id": "{client_id}","email": "{user}"\n')
                injected = True

        elif protocol == 'vmess':
            if clean_line in ('#vmess', '#vmessgrpc'):
                new_lines.append(f'### {user} {exp_date} {client_id}\n')
                new_lines.append(f'}},{{"id": "{client_id}","alterId": 0,"email": "{user}"\n')
                injected = True

        elif protocol == 'trojan':
            if clean_line in ('#trojanws', '#trojangrpc'):
                new_lines.append(f'#! {user} {exp_date} {client_id}\n')
                new_lines.append(f'}},{{"password": "{client_id}","email": "{user}"\n')
                injected = True

        elif protocol == 'socks':
            if clean_line == '#socks':
                new_lines.append(f'## {user} {exp_date} {client_id}\n')
                new_lines.append(f'}},{{"user": "{user}","pass": "{client_id}"\n')
                injected = True

    if not injected:
        return False, f"❌ Balises Bash pour {protocol.upper()} introuvables."

    with open(XRAY_CONF, 'w') as f:
        f.writelines(new_lines)

    subprocess.run("systemctl restart xray", shell=True)

    # Enregistrement avec createdById
    db_dir = '/etc/katashie_bot/xray_accounts'
    os.makedirs(db_dir, exist_ok=True)
    with open(f"{db_dir}/{protocol}_{user}.txt", 'w') as f:
        f.write(f"username={user}\nuuid={client_id}\nexpiry={exp_date}\ncreatedById={created_by_id}\ncreatedAt={datetime.utcnow().isoformat()}Z\nprotocol={protocol}\nstatus=active\n")

    # 3. GÉNÉRATION DES PAYLOADS
    if protocol == 'vless':
        link_tls = f"vless://{client_id}@{domain}:443?path=/vless&security=tls&encryption=none&type=ws#{user}"
        link_ntls = f"vless://{client_id}@{domain}:80?path=/vless&encryption=none&type=ws#{user}"
        link_grpc = f"vless://{client_id}@{domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc#{user}"

    elif protocol == 'vmess':
        ws_tls = f'{{"v":"2","ps":"{user}","add":"{domain}","port":"443","id":"{client_id}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}}'
        ws_ntls = f'{{"v":"2","ps":"{user}","add":"{domain}","port":"80","id":"{client_id}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"none"}}'
        grpc = f'{{"v":"2","ps":"{user}","add":"{domain}","port":"443","id":"{client_id}","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"","tls":"tls"}}'
        link_tls = "vmess://" + base64.b64encode(ws_tls.encode('utf-8')).decode('utf-8')
        link_ntls = "vmess://" + base64.b64encode(ws_ntls.encode('utf-8')).decode('utf-8')
        link_grpc = "vmess://" + base64.b64encode(grpc.encode('utf-8')).decode('utf-8')

    elif protocol == 'trojan':
        link_tls = f"trojan://{client_id}@{domain}:443?path=/trws&security=tls&encryption=none&host={domain}&type=ws#{user}"
        link_ntls = f"trojan://{client_id}@{domain}:80?path=/trws&encryption=none&security=none&host={domain}&type=ws#{user}"
        link_grpc = f"trojan://{client_id}@{domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni={domain}#{user}"

    elif protocol == 'socks':
        link_tls = f"socks5://{user}:{client_id}@{domain}:1080"
        link_ntls = f"socks5://{user}:{client_id}@{domain}:1080"
        link_grpc = link_ntls

    # 4. FORMATAGE TELEGRAM
    msg = (
        f"┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
        f"┃ <b>{protocol.upper()} ACCOUNT DETAILS</b>\n"
        f"┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"⏳ <b>Expired:</b> <code>{exp_date}</code>\n"
        f"🔑 <b>UUID/Pass:</b> <code>{client_id}</code>\n"
        f"🌐 <b>Domain:</b> <code>{domain}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🔗 <b>TLS (443):</b>\n<code>{link_tls}</code>\n\n"
        f"🔗 <b>NTLS (80):</b>\n<code>{link_ntls}</code>\n\n"
        f"🔗 <b>GRPC (443):</b>\n<code>{link_grpc}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )
    return True, msg

def get_xray_usernames(protocol):
    db_dir = '/etc/katashie_bot/xray_accounts'
    if not os.path.exists(db_dir):
        return []
    return [f[len(protocol)+1:].replace('.txt', '') for f in sorted(os.listdir(db_dir)) if f.startswith(f"{protocol}_") and f.endswith('.txt')]

def get_xray_account_details(protocol, user):
    db_file = f"/etc/katashie_bot/xray_accounts/{protocol}_{user}.txt"
    if not os.path.exists(db_file):
        return False, f"❌ Compte {protocol.upper()} <code>{user}</code> introuvable."
    data = {}
    with open(db_file, 'r') as f:
        for line in f:
            if '=' in line:
                k, v = line.strip().split('=', 1)
                data[k] = v
    client_id = data.get('uuid', 'N/A')
    exp_date = data.get('expiry', 'N/A')
    domain = get_domain()

    if protocol == 'vless':
        link_tls = f"vless://{client_id}@{domain}:443?path=/vless&security=tls&encryption=none&type=ws#{user}"
        link_ntls = f"vless://{client_id}@{domain}:80?path=/vless&encryption=none&type=ws#{user}"
        link_grpc = f"vless://{client_id}@{domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc#{user}"
    elif protocol == 'vmess':
        ws_tls = f'{{"v":"2","ps":"{user}","add":"{domain}","port":"443","id":"{client_id}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}}'
        ws_ntls = f'{{"v":"2","ps":"{user}","add":"{domain}","port":"80","id":"{client_id}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"none"}}'
        grpc = f'{{"v":"2","ps":"{user}","add":"{domain}","port":"443","id":"{client_id}","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"","tls":"tls"}}'
        link_tls = "vmess://" + base64.b64encode(ws_tls.encode('utf-8')).decode('utf-8')
        link_ntls = "vmess://" + base64.b64encode(ws_ntls.encode('utf-8')).decode('utf-8')
        link_grpc = "vmess://" + base64.b64encode(grpc.encode('utf-8')).decode('utf-8')
    elif protocol == 'trojan':
        link_tls = f"trojan://{client_id}@{domain}:443?path=/trws&security=tls&encryption=none&host={domain}&type=ws#{user}"
        link_ntls = f"trojan://{client_id}@{domain}:80?path=/trws&encryption=none&security=none&host={domain}&type=ws#{user}"
        link_grpc = f"trojan://{client_id}@{domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni={domain}#{user}"
    elif protocol == 'socks':
        link_tls = f"socks5://{user}:{client_id}@{domain}:1080"
        link_ntls = f"socks5://{user}:{client_id}@{domain}:1080"
        link_grpc = link_ntls
    else:
        return False, f"❌ Protocole inconnu: {protocol}"

    msg = (
        f"┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
        f"┃ <b>{protocol.upper()} ACCOUNT DETAILS</b>\n"
        f"┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"⏳ <b>Expired:</b> <code>{exp_date}</code>\n"
        f"🔑 <b>UUID/Pass:</b> <code>{client_id}</code>\n"
        f"🌐 <b>Domain:</b> <code>{domain}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🔗 <b>TLS (443):</b>\n<code>{link_tls}</code>\n\n"
        f"🔗 <b>NTLS (80):</b>\n<code>{link_ntls}</code>\n\n"
        f"🔗 <b>GRPC (443):</b>\n<code>{link_grpc}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )
    return True, msg

def renew_xray_account(protocol, user, days):
    db_file = f"/etc/katashie_bot/xray_accounts/{protocol}_{user}.txt"
    if not os.path.exists(db_file):
        return False, f"❌ Compte {protocol.upper()} <code>{user}</code> introuvable dans la base."

    days = int(days)
    # Read current expiry from db
    current_exp = None
    lines_db = []
    with open(db_file, 'r') as f:
        lines_db = f.readlines()
    for l in lines_db:
        if l.startswith("expiry="):
            current_exp = l.split("=", 1)[1].strip()
            break

    try:
        base_date = datetime.strptime(current_exp, "%Y-%m-%d") if current_exp else datetime.now()
        if base_date < datetime.now():
            base_date = datetime.now()
    except (ValueError, TypeError):
        base_date = datetime.now()

    new_exp = (base_date + timedelta(days=days)).strftime("%Y-%m-%d")

    # Update xray config comment line
    if os.path.exists(XRAY_CONF):
        with open(XRAY_CONF, 'r') as f:
            content = f.read()
        # Update date in comment lines matching the user
        # Comment prefixes used: #& (vless), ### (vmess), #! (trojan), ## (socks)
        content = re.sub(
            rf'((?:#[&!]|###+)\s+{re.escape(user)}\s+)\S+(\s)',
            rf'\g<1>{new_exp}\2',
            content
        )
        with open(XRAY_CONF, 'w') as f:
            f.write(content)
        subprocess.run("systemctl restart xray", shell=True)

    # Update db file
    new_db_lines = []
    for l in lines_db:
        if l.startswith("expiry="):
            new_db_lines.append(f"expiry={new_exp}\n")
        else:
            new_db_lines.append(l)
    with open(db_file, 'w') as f:
        f.writelines(new_db_lines)

    ok, details = get_xray_account_details(protocol, user)
    if ok:
        renewal_header = (
            f"✅ <b>COMPTE {protocol.upper()} RENOUVELÉ</b>\n"
            f"📅 <b>Ancienne expiration:</b> {current_exp} → <b>{new_exp}</b>\n\n"
        )
        return True, renewal_header + details
    return True, (
        f"✅ <b>COMPTE {protocol.upper()} RENOUVELÉ</b>\n\n"
        f"👤 <b>Username:</b> <code>{user}</code>\n"
        f"📅 <b>Ancienne expiration:</b> {current_exp}\n"
        f"➕ <b>Jours ajoutés:</b> {days}\n"
        f"📅 <b>Nouvelle expiration:</b> {new_exp}\n"
    )

def delete_xray_account(protocol, user):
    if not os.path.exists(XRAY_CONF):
        return False, "❌ Fichier config Xray introuvable."

    with open(XRAY_CONF, 'r') as f:
        lines = f.readlines()

    new_lines = []
    skip_next = False
    removed = False
    for line in lines:
        clean = line.strip()
        # Detect our account comment lines: #& user, ### user, #! user, ## user
        if re.match(rf'^(?:#[&!]|###+)\s+{re.escape(user)}\s+', clean):
            skip_next = True
            removed = True
            continue
        if skip_next:
            skip_next = False
            continue
        new_lines.append(line)

    if not removed:
        return False, f"❌ Utilisateur <code>{user}</code> introuvable dans la config {protocol.upper()}."

    with open(XRAY_CONF, 'w') as f:
        f.writelines(new_lines)
    subprocess.run("systemctl restart xray", shell=True)

    db_file = f"/etc/katashie_bot/xray_accounts/{protocol}_{user}.txt"
    if os.path.exists(db_file):
        os.remove(db_file)

    return True, f"🗑️ <b>Compte {protocol.upper()} <code>{user}</code> supprimé avec succès.</b>"

def list_xray_accounts(protocol):
    db_dir = '/etc/katashie_bot/xray_accounts'
    if not os.path.exists(db_dir):
        return f"📋 Aucun compte {protocol.upper()} trouvé."

    entries = [f for f in os.listdir(db_dir) if f.startswith(f"{protocol}_")]
    if not entries:
        return f"📋 Aucun compte {protocol.upper()} trouvé."

    msg = f"📋 <b>LISTE DES COMPTES {protocol.upper()}:</b>\n\n"
    for e in entries:
        user = e[len(protocol)+1:].replace('.txt', '')
        expiry = "N/A"
        try:
            with open(f"{db_dir}/{e}") as f:
                for l in f:
                    if l.startswith("expiry="):
                        expiry = l.split("=", 1)[1].strip()
        except Exception:
            pass
        msg += f"👤 <code>{user}</code> | Exp: <i>{expiry}</i>\n"
    msg += f"\n📊 <b>Total:</b> {len(entries)} compte(s)"
    return msg
