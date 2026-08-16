import json

CONFIG_FILE = '/etc/katashie_bot/config.json'

def get_config():
    with open(CONFIG_FILE, 'r') as f: return json.load(f)

def save_config(cfg):
    with open(CONFIG_FILE, 'w') as f: json.dump(cfg, f, indent=4)

def list_admins():
    cfg = get_config()
    admins = cfg.get('admins', [])
    super_admin = cfg.get('super_admin')
    super_admins = cfg.get('super_admins', [])

    msg = "👑 <b>SUPER ADMINS :</b>\n"
    msg += f"<code>{super_admin}</code>\n"
    for sa in super_admins:
        if sa != super_admin:
            msg += f"<code>{sa}</code>\n"
    msg += "\n👮‍♂️ <b>ADMINISTRATEURS DÉLÉGUÉS :</b>\n"
    if not admins:
        msg += "<i>Aucun administrateur secondaire.</i>"
    else:
        for a in admins: msg += f"▪️ <code>{a}</code>\n"
    return msg

def is_super_admin(user_id):
    cfg = get_config()
    return user_id == cfg.get('super_admin') or user_id in cfg.get('super_admins', [])

def approve_new_admin(admin_id):
    cfg = get_config()
    admin_id = int(admin_id)
    if admin_id in cfg.get('admins', []) or admin_id == cfg.get('super_admin') or admin_id in cfg.get('super_admins', []):
        return False, "Déjà administrateur."
    cfg.setdefault('admins', []).append(admin_id)
    save_config(cfg)
    return True, "Approuvé."

def promote_admin_to_supreme(admin_id):
    cfg = get_config()
    admin_id = int(admin_id)
    if admin_id == cfg.get('super_admin') or admin_id in cfg.get('super_admins', []):
        return False, "Déjà Super Admin."
    if admin_id not in cfg.get('admins', []):
        return False, "ID introuvable dans la liste des admins."
    cfg['admins'].remove(admin_id)
    cfg.setdefault('super_admins', [])
    cfg['super_admins'].append(admin_id)
    save_config(cfg)
    return True, f"Admin <code>{admin_id}</code> promu Super Admin avec succès."

def remove_admin(admin_id):
    cfg = get_config()
    admin_id = int(admin_id)
    if admin_id == cfg.get('super_admin'):
        return False, "Le Super Admin ne peut pas être supprimé."
    if admin_id in cfg.get('admins', []):
        cfg['admins'].remove(admin_id)
        save_config(cfg)
        return True, "Administrateur révoqué."
    return False, "ID introuvable."
