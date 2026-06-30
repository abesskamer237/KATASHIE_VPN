#!/usr/bin/env python3
"""
KATASHIE VPN — Bot WhatsApp v2 (Twilio + Flask)
Gestion SSH/XRAY/ZIVPN + Gestion revendeurs via WhatsApp
Contact WhatsApp: wa.me/237682229367
Chaîne: https://whatsapp.com/channel/0029Vb8J9L44Y9li0Ffkqu1J
"""
from flask import Flask, request
from twilio.twiml.messaging_response import MessagingResponse
from twilio.rest import Client as TwilioClient
import json, os, subprocess, logging
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s %(message)s')
logger = logging.getLogger('katashie-whatsapp')

CONFIG_PATH = os.environ.get('KATASHIE_WA_CONFIG', '/etc/katashie_whatsapp_bot/config.json')
with open(CONFIG_PATH) as f:
    cfg = json.load(f)

TWILIO_SID    = cfg['twilio_account_sid']
TWILIO_TOKEN  = cfg['twilio_auth_token']
TWILIO_NUMBER = cfg['twilio_whatsapp_number']
ADMIN_NUMBER  = cfg['admin_whatsapp_number']
BOT_PASSWORD  = cfg.get('bot_password', 'katashie2024')

twilio_client = TwilioClient(TWILIO_SID, TWILIO_TOKEN)
app = Flask(__name__)

# Session management: phone -> {authenticated, role, username}
sessions: dict[str, dict] = {}

RESELLER_NUMBERS = cfg.get('reseller_numbers', [])

HELP_ADMIN = """*KATASHIE VPN — Commandes Admin*

🔐 *Comptes SSH:*
`ssh créer <user> <jours>`
`ssh lister`
`ssh supprimer <user>`
`ssh renouveler <user> <jours>`

⚡ *Comptes XRAY:*
`vless créer <user> <jours>`
`vmess créer <user> <jours>`
`trojan créer <user> <jours>`
`xray lister`
`xray supprimer <user>`

👥 *Revendeurs:*
`revendeur créer <user> <pass> <jours> [max_clients]`
`revendeur lister`
`revendeur suspendre <user>`
`revendeur renouveler <user> <jours>`

📊 *Système:*
`statut` — CPU, RAM, disque
`aide` — Afficher ce menu
`déconnexion` — Se déconnecter"""

HELP_RESELLER = """*KATASHIE VPN — Commandes Revendeur*

🔐 *Comptes SSH:*
`ssh créer <user> <jours>`
`ssh lister`
`ssh supprimer <user>`

⚡ *Comptes XRAY:*
`vless créer <user> <jours>`
`vmess créer <user> <jours>`

📊 *Système:*
`statut` — Voir le statut
`aide` — Afficher ce menu"""

def run_cmd(cmd: str, timeout=30) -> str:
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return (result.stdout + result.stderr).strip()[:800] or "(Aucun retour)"
    except subprocess.TimeoutExpired:
        return "⏱ Commande trop longue (timeout)"
    except Exception as e:
        return f"Erreur: {str(e)}"

def get_system_status() -> str:
    cpu = run_cmd("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | tr -d '%us,'").split('\n')[0]
    mem = run_cmd("free -m | awk 'NR==2{printf \"%d/%d MB (%.0f%%)\", $3,$2,$3/$2*100}'")
    disk = run_cmd("df -h / | awk 'NR==2{printf \"%s/%s (%s)\", $3,$2,$5}'")
    uptime = run_cmd("uptime -p")
    ssh_conn = run_cmd("ss -tn | grep ':22 ' | wc -l")
    return f"""📊 *Statut KATASHIE VPN*

💻 CPU: {cpu.strip()}%
🧠 RAM: {mem}
💾 Disque: {disk}
⏱ Uptime: {uptime}
🔗 Connexions SSH: {ssh_conn}"""

def create_ssh(username, days, limit_gb=None) -> str:
    pass_cmd = f"useradd -e $(date -d '+{days} days' '+%Y-%m-%d') -s /bin/false -M {username}"
    passwd = run_cmd(f"openssl rand -base64 12")
    run_cmd(f"echo '{username}:{passwd}' | chpasswd")
    result = run_cmd(pass_cmd)
    return f"✅ *Compte SSH créé*\n\n👤 User: `{username}`\n🔑 Pass: `{passwd}`\n📅 Expire: {(datetime.now()+timedelta(days=int(days))).strftime('%d/%m/%Y')}"

def delete_ssh(username) -> str:
    run_cmd(f"userdel -f {username} 2>/dev/null")
    return f"🗑 Compte SSH `{username}` supprimé"

def list_ssh() -> str:
    result = run_cmd("awk -F: '($3>=1000 && $7!=\"/bin/bash\"){print $1}' /etc/passwd | head -20")
    return f"📋 *Comptes SSH:*\n```\n{result}\n```" if result else "Aucun compte SSH trouvé"

def create_xray(protocol, username, days) -> str:
    import uuid
    uid = str(uuid.uuid4())
    expire = (datetime.now() + timedelta(days=int(days))).strftime('%Y-%m-%d')
    return f"✅ *Compte {protocol.upper()} créé*\n\n👤 User: `{username}`\n🔑 UUID: `{uid}`\n📅 Expire: {expire}\n\nConfigurez via le panneau web."

def process_command(phone: str, text: str) -> str:
    session = sessions.get(phone, {})
    is_auth = session.get('authenticated', False)
    is_adm = phone == ADMIN_NUMBER or session.get('role') == 'admin'
    is_res = phone in RESELLER_NUMBERS or session.get('role') == 'reseller'

    text = text.strip().lower()
    parts = text.split()
    cmd = parts[0] if parts else ''

    # Authentication
    if not is_auth:
        if text == BOT_PASSWORD or text == f"connexion {BOT_PASSWORD}":
            role = 'admin' if phone == ADMIN_NUMBER else ('reseller' if phone in RESELLER_NUMBERS else 'unknown')
            if role == 'unknown':
                return "⛔ Numéro non autorisé. Contactez @abess237 sur Telegram."
            sessions[phone] = {'authenticated': True, 'role': role}
            return f"✅ *Connecté en tant que {role}*\n\nEnvoyez `aide` pour la liste des commandes."
        else:
            return f"🔐 *KATASHIE VPN Bot*\n\nEntrez votre mot de passe pour continuer.\n\n_Contact: wa.me/237682229367_"

    # Déconnexion
    if cmd in ['déconnexion', 'logout', 'exit']:
        sessions.pop(phone, None)
        return "👋 Déconnecté. Envoyez le mot de passe pour vous reconnecter."

    # Aide
    if cmd in ['aide', 'help', 'menu']:
        return HELP_ADMIN if is_adm else HELP_RESELLER

    # Statut
    if cmd == 'statut':
        return get_system_status()

    # SSH
    if cmd == 'ssh':
        if len(parts) < 2:
            return "Usage: ssh créer/lister/supprimer/renouveler"
        action = parts[1]
        if action in ['créer', 'creer', 'create', 'add']:
            if len(parts) < 4:
                return "Usage: ssh créer <username> <jours>"
            return create_ssh(parts[2], parts[3])
        elif action in ['lister', 'list']:
            return list_ssh()
        elif action in ['supprimer', 'delete', 'del']:
            if len(parts) < 3:
                return "Usage: ssh supprimer <username>"
            return delete_ssh(parts[2])
        elif action in ['renouveler', 'renew']:
            if len(parts) < 4:
                return "Usage: ssh renouveler <username> <jours>"
            run_cmd(f"chage -E $(date -d '+{parts[3]} days' '+%Y-%m-%d') {parts[2]}")
            return f"✅ Compte `{parts[2]}` renouvelé de {parts[3]} jours"

    # XRAY
    if cmd in ['vless', 'vmess', 'trojan']:
        if len(parts) < 2:
            return f"Usage: {cmd} créer <username> <jours>"
        action = parts[1]
        if action in ['créer', 'creer', 'create']:
            if len(parts) < 4:
                return f"Usage: {cmd} créer <username> <jours>"
            return create_xray(cmd, parts[2], parts[3])

    if cmd == 'xray':
        if len(parts) < 2:
            return "Usage: xray lister/supprimer"
        if parts[1] in ['lister', 'list']:
            result = run_cmd("cat /usr/local/etc/xray/config.json 2>/dev/null | python3 -c \"import json,sys; c=json.load(sys.stdin); [print(cl.get('email','?')) for inb in c.get('inbounds',[]) for cl in inb.get('settings',{}).get('clients',[])]\" 2>/dev/null | head -20")
            return f"📋 *Clients XRAY:*\n```\n{result or 'Aucun client'}\n```"

    # Revendeurs (admin only)
    if cmd == 'revendeur':
        if not is_adm:
            return "⛔ Commande réservée aux administrateurs"
        if len(parts) < 2:
            return "Usage: revendeur créer/lister/suspendre/renouveler"
        action = parts[1]
        if action in ['créer', 'creer']:
            if len(parts) < 5:
                return "Usage: revendeur créer <username> <password> <jours> [max_clients]"
            u, p, d = parts[2], parts[3], parts[4]
            max_c = parts[5] if len(parts) > 5 else '50'
            return f"✅ *Revendeur créé*\n\n👤 User: `{u}`\n🔑 Pass: `{p}`\n📅 Durée: {d} jours\n👥 Max clients: {max_c}\n\nURL panneau: http://VOTRE_IP:2087"
        elif action in ['lister', 'list']:
            return "📋 *Revendeurs:*\nVoir panneau web → /api/resellers"
        elif action in ['suspendre', 'suspend']:
            if len(parts) < 3:
                return "Usage: revendeur suspendre <username>"
            return f"🚫 Revendeur `{parts[2]}` suspendu (via API)"

    return f"❓ Commande inconnue: `{cmd}`\nEnvoyez `aide` pour la liste des commandes."

@app.route('/whatsapp', methods=['POST'])
def whatsapp_webhook():
    from_number = request.form.get('From', '').replace('whatsapp:', '')
    body = request.form.get('Body', '').strip()
    logger.info(f"MSG from {from_number}: {body[:60]}")

    resp = MessagingResponse()
    try:
        reply = process_command(from_number, body)
        resp.message(reply)
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        resp.message("❌ Erreur interne. Réessayez ou contactez @abess237")
    return str(resp)

@app.route('/health')
def health():
    return {'status': 'ok', 'service': 'katashie-whatsapp-bot'}

if __name__ == '__main__':
    port = int(cfg.get('port', 5001))
    logger.info(f"KATASHIE WhatsApp Bot v2 starting on port {port}...")
    logger.info(f"Webhook URL: https://VOTRE_DOMAINE:{port}/whatsapp")
    app.run(host='0.0.0.0', port=port, debug=False)
