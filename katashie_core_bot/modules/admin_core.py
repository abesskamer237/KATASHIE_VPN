# ─── Admin ────────────────────────────────────────────────────
import json
import os

CONFIG_FILE = '/etc/katashie_bot/config.json'

def load_config():
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def save_config(cfg):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(cfg, f, indent=2)

def is_super_admin(user_id):
    cfg = load_config()
    return user_id == cfg.get('super_admin')

def add_admin(user_id):
    cfg = load_config()
    admins = cfg.get('admins', [])
    if user_id in admins:
        return False, f"❌ <code>{user_id}</code> est déjà admin."
    admins.append(user_id)
    cfg['admins'] = admins
    save_config(cfg)
    return True, f"✅ Admin <code>{user_id}</code> ajouté."

def remove_admin(user_id):
    cfg = load_config()
    admins = cfg.get('admins', [])
    if user_id not in admins:
        return False, f"❌ <code>{user_id}</code> n'est pas admin."
    admins.remove(user_id)
    cfg['admins'] = admins
    save_config(cfg)
    return True, f"🗑️ Admin <code>{user_id}</code> révoqué."

def list_admins():
    cfg = load_config()
    admins = cfg.get('admins', [])
    super_admin = cfg.get('super_admin')
    lines = [f"👑 Super Admin: <code>{super_admin}</code>"]
    if admins:
        for a in admins:
            lines.append(f"🔑 Admin: <code>{a}</code>")
    else:
        lines.append("Aucun admin secondaire.")
    return "👥 <b>Gestion des Admins</b>\n\n" + "\n".join(lines)
