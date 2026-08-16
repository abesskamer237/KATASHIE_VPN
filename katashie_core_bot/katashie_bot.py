import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import json
import os
import logging
from modules import system_core, ssh_core, admin_core, xray_core, zivpn_core

logging.basicConfig(level=logging.WARNING, format='%(asctime)s %(levelname)s %(message)s')

CONFIG_FILE = '/etc/katashie_bot/config.json'

MENU_IMAGE_URL = "https://github.com/user-attachments/assets/baf681b1-820a-428d-85cf-703c25ff498b"

def load_config():
    if not os.path.exists(CONFIG_FILE): return None
    with open(CONFIG_FILE, 'r') as f: return json.load(f)

config = load_config()
if not config: exit(1)

bot = telebot.TeleBot(config.get('bot_token'))
SUPER_ADMIN = int(config.get('super_admin'))

def is_admin(user_id):
    cfg = load_config()
    return user_id == SUPER_ADMIN or user_id in cfg.get('admins', [])

# --- MENU PRINCIPAL ---
def main_menu_keyboard():
    markup = InlineKeyboardMarkup(row_width=2)
    markup.add(
        InlineKeyboardButton("🔑 SSH/WS", callback_data="menu_ssh"),
        InlineKeyboardButton("🔰 VMESS", callback_data="menu_vmess"),
        InlineKeyboardButton("🔰 VLESS", callback_data="menu_vless"),
        InlineKeyboardButton("🔰 TROJAN", callback_data="menu_trojan"),
        InlineKeyboardButton("🔌 SOCKS", callback_data="menu_socks"),
        InlineKeyboardButton("📱 ZIVPN", callback_data="menu_zivpn"),
        InlineKeyboardButton("📊 VPS STATUS", callback_data="menu_status"),
        InlineKeyboardButton("🧹 CLEAN LOGS", callback_data="menu_log"),
        InlineKeyboardButton("👑 ADMINS", callback_data="menu_admins"),
        InlineKeyboardButton("🔄 REBOOT VPS", callback_data="action_reboot")
    )
    return markup

def protocol_menu_keyboard(proto):
    """Builds a full CRUD sub-menu for any protocol."""
    markup = InlineKeyboardMarkup(row_width=1)
    markup.add(
        InlineKeyboardButton(f"➕ Créer compte {proto.upper()}", callback_data=f"add_{proto}"),
        InlineKeyboardButton(f"🔄 Renouveler compte {proto.upper()}", callback_data=f"renew_{proto}"),
        InlineKeyboardButton(f"🗑️ Supprimer compte {proto.upper()}", callback_data=f"del_{proto}"),
        InlineKeyboardButton(f"📋 Liste des comptes {proto.upper()}", callback_data=f"list_{proto}"),
    )
    if proto == 'ssh':
        markup.add(
            InlineKeyboardButton("🔒 Verrouiller un compte", callback_data="lock_ssh"),
            InlineKeyboardButton("🔓 Déverrouiller un compte", callback_data="unlock_ssh"),
        )
    markup.add(InlineKeyboardButton("🔙 Retour Accueil", callback_data="action_home"))
    return markup

def _show_submenu(call, text, markup):
    """Helper: shows a submenu, handling both photo and text message origins."""
    if call.message.content_type == 'photo':
        try:
            bot.delete_message(call.message.chat.id, call.message.message_id)
        except Exception:
            pass
        bot.send_message(call.message.chat.id, text, parse_mode="HTML", reply_markup=markup)
    else:
        bot.edit_message_text(text, chat_id=call.message.chat.id, message_id=call.message.message_id,
                              parse_mode="HTML", reply_markup=markup)

@bot.message_handler(commands=['start'])
def send_welcome(message):
    if not is_admin(message.from_user.id):
        bot.reply_to(message, "⛔ Accès refusé.")
        return
    bot.send_photo(
        message.chat.id,
        MENU_IMAGE_URL,
        caption="<b>🟢 KATASHIE VPN - C2 SERVER</b>\nSélectionnez un module :",
        parse_mode="HTML",
        reply_markup=main_menu_keyboard()
    )

# --- RETOUR À L'ACCUEIL ---
@bot.callback_query_handler(func=lambda call: call.data == "action_home")
def home_callback(call):
    if not is_admin(call.from_user.id): return
    try:
        bot.delete_message(call.message.chat.id, call.message.message_id)
    except Exception:
        pass
    bot.send_photo(
        call.message.chat.id,
        MENU_IMAGE_URL,
        caption="<b>🟢 KATASHIE VPN - C2 SERVER</b>\nSélectionnez un module :",
        parse_mode="HTML",
        reply_markup=main_menu_keyboard()
    )

# --- SOUS-MENUS PROTOCOLES ---
@bot.callback_query_handler(func=lambda call: call.data in (
    "menu_ssh", "menu_vmess", "menu_vless", "menu_trojan", "menu_socks", "menu_zivpn"
))
def protocol_submenu(call):
    if not is_admin(call.from_user.id): return
    proto = call.data.split("_", 1)[1]
    _show_submenu(call, f"<b>Module {proto.upper()}</b>\nChoisissez une action :", protocol_menu_keyboard(proto))

# ═══════════════════════════════════════════════════════════
# SSH — CRÉATION
# ═══════════════════════════════════════════════════════════
@bot.callback_query_handler(func=lambda call: call.data == "add_ssh")
def add_ssh_start(call):
    if not is_admin(call.from_user.id): return
    bot.edit_message_text("⚙️ Module SSH — Création", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, "👤 <b>Étape 1/3</b>\nEntrez le nom d'utilisateur SSH :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _ssh_get_user, call.from_user.id)

def _ssh_get_user(message, creator_id):
    user = message.text.strip()
    msg = bot.send_message(message.chat.id, "🔑 <b>Étape 2/3</b>\nEntrez le mot de passe :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _ssh_get_pass, user, creator_id)

def _ssh_get_pass(message, user, creator_id):
    password = message.text.strip()
    msg = bot.send_message(message.chat.id, "⏳ <b>Étape 3/3</b>\nEntrez la durée (en jours) :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _ssh_get_days, user, password, creator_id)

def _ssh_get_days(message, user, password, creator_id):
    days = message.text.strip()
    if not days.isdigit():
        bot.send_message(message.chat.id, "❌ Le nombre de jours doit être un entier.", reply_markup=main_menu_keyboard())
        return
    bot.send_message(message.chat.id, f"⚙️ Création du compte <b>{user}</b>...", parse_mode="HTML")
    success, res = ssh_core.create_ssh_account(user, password, days, created_by_id=creator_id)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# SSH — RENOUVELLEMENT
@bot.callback_query_handler(func=lambda call: call.data == "renew_ssh")
def renew_ssh_start(call):
    if not is_admin(call.from_user.id): return
    bot.edit_message_text("🔄 Module SSH — Renouvellement", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, "👤 Entrez le nom d'utilisateur SSH à renouveler :")
    bot.register_next_step_handler(msg, _ssh_renew_get_days)

def _ssh_renew_get_days(message):
    user = message.text.strip()
    msg = bot.send_message(message.chat.id, f"⏳ Combien de jours ajouter au compte <code>{user}</code> ?", parse_mode="HTML")
    bot.register_next_step_handler(msg, _ssh_renew_execute, user)

def _ssh_renew_execute(message, user):
    days = message.text.strip()
    if not days.isdigit():
        bot.send_message(message.chat.id, "❌ Le nombre de jours doit être un entier.", reply_markup=main_menu_keyboard())
        return
    success, res = ssh_core.renew_ssh_account(user, days)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# SSH — SUPPRESSION
@bot.callback_query_handler(func=lambda call: call.data == "del_ssh")
def del_ssh_start(call):
    if not is_admin(call.from_user.id): return
    bot.edit_message_text("🗑️ Module SSH — Suppression", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, "👤 Entrez le nom d'utilisateur SSH à supprimer :")
    bot.register_next_step_handler(msg, _ssh_del_execute)

def _ssh_del_execute(message):
    user = message.text.strip()
    success, res = ssh_core.delete_ssh_account(user)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# SSH — VERROUILLAGE / DÉVERROUILLAGE
@bot.callback_query_handler(func=lambda call: call.data in ("lock_ssh", "unlock_ssh"))
def lock_unlock_ssh_start(call):
    if not is_admin(call.from_user.id): return
    action = call.data  # "lock_ssh" or "unlock_ssh"
    label = "verrouiller" if action == "lock_ssh" else "déverrouiller"
    bot.edit_message_text(f"🔒 SSH — {label.capitalize()}", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, f"👤 Entrez le nom d'utilisateur SSH à {label} :")
    bot.register_next_step_handler(msg, _ssh_lock_execute, action)

def _ssh_lock_execute(message, action):
    user = message.text.strip()
    if action == "lock_ssh":
        success, res = ssh_core.lock_ssh_account(user)
    else:
        success, res = ssh_core.unlock_ssh_account(user)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# SSH — LISTE
@bot.callback_query_handler(func=lambda call: call.data == "list_ssh")
def handle_list_ssh(call):
    if not is_admin(call.from_user.id): return
    users = ssh_core.get_ssh_usernames()
    markup = InlineKeyboardMarkup(row_width=1)
    if users:
        for u in users:
            markup.add(InlineKeyboardButton(f"👤 {u}", callback_data=f"view_ssh_{u}"))
        text = "📋 <b>LISTE DES COMPTES SSH:</b>\nSélectionnez un compte pour voir ses détails :"
    else:
        text = "📋 Aucun compte SSH trouvé."
    markup.add(InlineKeyboardButton("🔙 Retour Accueil", callback_data="action_home"))
    _show_submenu(call, text, markup)

@bot.callback_query_handler(func=lambda call: call.data.startswith("view_ssh_"))
def view_ssh_account(call):
    if not is_admin(call.from_user.id): return
    user = call.data[len("view_ssh_"):]
    ok, details = ssh_core.get_ssh_account_details(user)
    markup = InlineKeyboardMarkup(row_width=1)
    markup.add(
        InlineKeyboardButton("🔙 Retour Liste", callback_data="list_ssh"),
        InlineKeyboardButton("🏠 Retour Accueil", callback_data="action_home")
    )
    _show_submenu(call, details, markup)

# ═══════════════════════════════════════════════════════════
# XRAY — MACHINE À ÉTATS COMMUNE (VLESS / VMESS / TROJAN / SOCKS)
# ═══════════════════════════════════════════════════════════
@bot.callback_query_handler(func=lambda call: call.data in ("add_vless", "add_vmess", "add_trojan", "add_socks"))
def add_xray_start(call):
    if not is_admin(call.from_user.id): return
    proto = call.data.split("_", 1)[1]
    bot.edit_message_text(f"⚙️ Module {proto.upper()} — Création", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, f"👤 <b>Étape 1/2</b>\nEntrez le nom d'utilisateur {proto.upper()} :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _xray_get_user, proto, call.from_user.id)

def _xray_get_user(message, proto, creator_id):
    user = message.text.strip()
    msg = bot.send_message(message.chat.id, f"⏳ <b>Étape 2/2</b>\nEntrez la durée (en jours) pour {proto.upper()} :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _xray_get_days, user, proto, creator_id)

def _xray_get_days(message, user, proto, creator_id):
    days = message.text.strip()
    if not days.isdigit():
        bot.send_message(message.chat.id, "❌ Le nombre de jours doit être un entier.", reply_markup=main_menu_keyboard())
        return
    bot.send_message(message.chat.id, f"⚙️ Injection de <b>{user}</b> dans le noyau Xray ({proto.upper()})...", parse_mode="HTML")
    success, res = xray_core.create_xray_account(proto, user, days, created_by_id=creator_id)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# XRAY — RENOUVELLEMENT
@bot.callback_query_handler(func=lambda call: call.data in ("renew_vless", "renew_vmess", "renew_trojan", "renew_socks"))
def renew_xray_start(call):
    if not is_admin(call.from_user.id): return
    proto = call.data.split("_", 1)[1]
    bot.edit_message_text(f"🔄 {proto.upper()} — Renouvellement", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, f"👤 Entrez le nom d'utilisateur {proto.upper()} à renouveler :")
    bot.register_next_step_handler(msg, _xray_renew_get_days, proto)

def _xray_renew_get_days(message, proto):
    user = message.text.strip()
    msg = bot.send_message(message.chat.id, f"⏳ Combien de jours ajouter au compte <code>{user}</code> ?", parse_mode="HTML")
    bot.register_next_step_handler(msg, _xray_renew_execute, proto, user)

def _xray_renew_execute(message, proto, user):
    days = message.text.strip()
    if not days.isdigit():
        bot.send_message(message.chat.id, "❌ Le nombre de jours doit être un entier.", reply_markup=main_menu_keyboard())
        return
    success, res = xray_core.renew_xray_account(proto, user, days)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# XRAY — SUPPRESSION
@bot.callback_query_handler(func=lambda call: call.data in ("del_vless", "del_vmess", "del_trojan", "del_socks"))
def del_xray_start(call):
    if not is_admin(call.from_user.id): return
    proto = call.data.split("_", 1)[1]
    bot.edit_message_text(f"🗑️ {proto.upper()} — Suppression", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, f"👤 Entrez le nom d'utilisateur {proto.upper()} à supprimer :")
    bot.register_next_step_handler(msg, _xray_del_execute, proto)

def _xray_del_execute(message, proto):
    user = message.text.strip()
    success, res = xray_core.delete_xray_account(proto, user)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# XRAY — LISTE
@bot.callback_query_handler(func=lambda call: call.data in ("list_vless", "list_vmess", "list_trojan", "list_socks"))
def handle_list_xray(call):
    if not is_admin(call.from_user.id): return
    proto = call.data.split("_", 1)[1]
    users = xray_core.get_xray_usernames(proto)
    markup = InlineKeyboardMarkup(row_width=1)
    if users:
        for u in users:
            markup.add(InlineKeyboardButton(f"👤 {u}", callback_data=f"view_{proto}_{u}"))
        text = f"📋 <b>LISTE DES COMPTES {proto.upper()}:</b>\nSélectionnez un compte pour voir ses détails :"
    else:
        text = f"📋 Aucun compte {proto.upper()} trouvé."
    markup.add(InlineKeyboardButton("🔙 Retour Accueil", callback_data="action_home"))
    _show_submenu(call, text, markup)

@bot.callback_query_handler(func=lambda call: call.data.startswith("view_vless_") or call.data.startswith("view_vmess_") or call.data.startswith("view_trojan_") or call.data.startswith("view_socks_"))
def view_xray_account(call):
    if not is_admin(call.from_user.id): return
    parts = call.data.split("_", 2)
    proto = parts[1]
    user = parts[2]
    ok, details = xray_core.get_xray_account_details(proto, user)
    markup = InlineKeyboardMarkup(row_width=1)
    markup.add(
        InlineKeyboardButton(f"🔙 Retour Liste", callback_data=f"list_{proto}"),
        InlineKeyboardButton("🏠 Retour Accueil", callback_data="action_home")
    )
    _show_submenu(call, details, markup)

# ═══════════════════════════════════════════════════════════
# ZIVPN — CRÉATION
# ═══════════════════════════════════════════════════════════
@bot.callback_query_handler(func=lambda call: call.data == "add_zivpn")
def add_zivpn_start(call):
    if not is_admin(call.from_user.id): return
    bot.edit_message_text("⚙️ Module ZIVPN — Création", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, "👤 <b>Étape 1/3</b>\nEntrez le nom d'utilisateur ZIVPN :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _zivpn_get_user, call.from_user.id)

def _zivpn_get_user(message, creator_id):
    user = message.text.strip()
    msg = bot.send_message(message.chat.id, "🔑 <b>Étape 2/3</b>\nEntrez le mot de passe :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _zivpn_get_pass, user, creator_id)

def _zivpn_get_pass(message, user, creator_id):
    password = message.text.strip()
    msg = bot.send_message(message.chat.id, "⏳ <b>Étape 3/3</b>\nEntrez la durée (en jours) :", parse_mode="HTML")
    bot.register_next_step_handler(msg, _zivpn_get_days, user, password, creator_id)

def _zivpn_get_days(message, user, password, creator_id):
    days = message.text.strip()
    if not days.isdigit():
        bot.send_message(message.chat.id, "❌ Le nombre de jours doit être un entier.", reply_markup=main_menu_keyboard())
        return
    bot.send_message(message.chat.id, f"⚙️ Création du compte <b>{user}</b> (ZIVPN)...", parse_mode="HTML")
    success, res = zivpn_core.create_zivpn_account(user, password, days, created_by_id=creator_id)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# ZIVPN — RENOUVELLEMENT
@bot.callback_query_handler(func=lambda call: call.data == "renew_zivpn")
def renew_zivpn_start(call):
    if not is_admin(call.from_user.id): return
    bot.edit_message_text("🔄 ZIVPN — Renouvellement", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, "👤 Entrez le nom d'utilisateur ZIVPN à renouveler :")
    bot.register_next_step_handler(msg, _zivpn_renew_get_days)

def _zivpn_renew_get_days(message):
    user = message.text.strip()
    msg = bot.send_message(message.chat.id, f"⏳ Combien de jours ajouter au compte <code>{user}</code> ?", parse_mode="HTML")
    bot.register_next_step_handler(msg, _zivpn_renew_execute, user)

def _zivpn_renew_execute(message, user):
    days = message.text.strip()
    if not days.isdigit():
        bot.send_message(message.chat.id, "❌ Le nombre de jours doit être un entier.", reply_markup=main_menu_keyboard())
        return
    success, res = zivpn_core.renew_zivpn_account(user, days)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# ZIVPN — SUPPRESSION
@bot.callback_query_handler(func=lambda call: call.data == "del_zivpn")
def del_zivpn_start(call):
    if not is_admin(call.from_user.id): return
    bot.edit_message_text("🗑️ ZIVPN — Suppression", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, "👤 Entrez le nom d'utilisateur ZIVPN à supprimer :")
    bot.register_next_step_handler(msg, _zivpn_del_execute)

def _zivpn_del_execute(message):
    user = message.text.strip()
    success, res = zivpn_core.delete_zivpn_account(user)
    bot.send_message(message.chat.id, res, parse_mode="HTML", reply_markup=main_menu_keyboard())

# ZIVPN — LISTE
@bot.callback_query_handler(func=lambda call: call.data == "list_zivpn")
def handle_list_zivpn(call):
    if not is_admin(call.from_user.id): return
    users = zivpn_core.get_zivpn_usernames()
    markup = InlineKeyboardMarkup(row_width=1)
    if users:
        for u in users:
            markup.add(InlineKeyboardButton(f"👤 {u}", callback_data=f"view_zivpn_{u}"))
        text = "📋 <b>LISTE DES COMPTES ZIVPN:</b>\nSélectionnez un compte pour voir ses détails :"
    else:
        text = "📋 Aucun compte ZIVPN trouvé."
    markup.add(InlineKeyboardButton("🔙 Retour Accueil", callback_data="action_home"))
    _show_submenu(call, text, markup)

@bot.callback_query_handler(func=lambda call: call.data.startswith("view_zivpn_"))
def view_zivpn_account(call):
    if not is_admin(call.from_user.id): return
    user = call.data[len("view_zivpn_"):]
    ok, details = zivpn_core.get_zivpn_account_details(user)
    markup = InlineKeyboardMarkup(row_width=1)
    markup.add(
        InlineKeyboardButton("🔙 Retour Liste", callback_data="list_zivpn"),
        InlineKeyboardButton("🏠 Retour Accueil", callback_data="action_home")
    )
    _show_submenu(call, details, markup)

# ═══════════════════════════════════════════════════════════
# SYSTÈME
# ═══════════════════════════════════════════════════════════
@bot.callback_query_handler(func=lambda call: call.data == "menu_status")
def handle_status(call):
    if not is_admin(call.from_user.id): return
    status_text = system_core.get_vps_status()
    markup = InlineKeyboardMarkup().add(InlineKeyboardButton("🔙 Retour Accueil", callback_data="action_home"))
    _show_submenu(call, status_text, markup)

@bot.callback_query_handler(func=lambda call: call.data == "menu_log")
def handle_clean_logs(call):
    if not is_admin(call.from_user.id): return
    result = system_core.clean_system_logs()
    markup = InlineKeyboardMarkup().add(InlineKeyboardButton("🔙 Retour Accueil", callback_data="action_home"))
    _show_submenu(call, result, markup)

@bot.callback_query_handler(func=lambda call: call.data == "action_reboot")
def handle_reboot(call):
    if not admin_core.is_super_admin(call.from_user.id): return
    bot.answer_callback_query(call.id, "♻️ Reboot en cours...")
    bot.send_message(call.message.chat.id, "♻️ <b>Reboot VPS lancé.</b>", parse_mode="HTML")
    import subprocess
    subprocess.run("reboot", shell=True)

# ═══════════════════════════════════════════════════════════
# GESTION DES ADMINISTRATEURS
# ═══════════════════════════════════════════════════════════
@bot.callback_query_handler(func=lambda call: call.data == "menu_admins")
def handle_menu_admins(call):
    if not is_admin(call.from_user.id): return
    is_super = admin_core.is_super_admin(call.from_user.id)
    markup = InlineKeyboardMarkup(row_width=1)
    markup.add(
        InlineKeyboardButton("📋 Liste des admins", callback_data="list_admins"),
        InlineKeyboardButton("➕ Ajouter un admin", callback_data="req_add_admin"),
    )
    if is_super:
        markup.add(InlineKeyboardButton("👑 Promouvoir admin en suprême", callback_data="req_promote_admin"))
    markup.add(
        InlineKeyboardButton("❌ Supprimer un admin", callback_data="req_del_admin"),
        InlineKeyboardButton("🔙 Retour Accueil", callback_data="action_home")
    )
    msg = admin_core.list_admins()
    _show_submenu(call, msg, markup)

@bot.callback_query_handler(func=lambda call: call.data == "list_admins")
def handle_list_admins(call):
    if not is_admin(call.from_user.id): return
    markup = InlineKeyboardMarkup().add(InlineKeyboardButton("🔙 Retour Admins", callback_data="menu_admins"))
    _show_submenu(call, admin_core.list_admins(), markup)

@bot.callback_query_handler(func=lambda call: call.data == "req_add_admin")
def req_add_admin(call):
    if not is_admin(call.from_user.id): return
    msg = bot.send_message(call.message.chat.id, "👤 Entrez l'ID Telegram du nouvel administrateur :")
    bot.register_next_step_handler(msg, _process_add_admin, call.from_user.id)

def _process_add_admin(message, requester_id):
    target_id = message.text.strip()
    if not target_id.isdigit():
        bot.send_message(message.chat.id, "❌ L'ID doit être un nombre entier.")
        return

    if admin_core.is_super_admin(requester_id):
        success, res = admin_core.approve_new_admin(target_id)
        status = "✅" if success else "❌"
        bot.send_message(message.chat.id, f"{status} {res}", reply_markup=main_menu_keyboard())
    else:
        bot.send_message(message.chat.id, "⏳ <b>Demande envoyée au Super Admin pour approbation.</b>", parse_mode="HTML")
        super_admin_id = admin_core.get_config().get('super_admin')
        markup = InlineKeyboardMarkup(row_width=2)
        markup.add(
            InlineKeyboardButton("✅ Approuver", callback_data=f"adm:approve:{target_id}:{requester_id}"),
            InlineKeyboardButton("❌ Refuser", callback_data=f"adm:reject:{target_id}:{requester_id}")
        )
        bot.send_message(
            super_admin_id,
            f"⚠️ <b>REQUÊTE ADMIN</b>\n\nL'admin <code>{requester_id}</code> souhaite ajouter <code>{target_id}</code>.",
            parse_mode="HTML", reply_markup=markup
        )

@bot.callback_query_handler(func=lambda call: call.data.startswith("adm:approve:") or call.data.startswith("adm:reject:"))
def handle_admin_approval(call):
    if not admin_core.is_super_admin(call.from_user.id): return
    parts = call.data.split(":")
    action, target_id, requester_id = parts[1], parts[2], parts[3]

    bot.edit_message_reply_markup(call.message.chat.id, call.message.message_id, reply_markup=None)

    if action == "approve":
        success, res = admin_core.approve_new_admin(target_id)
        bot.send_message(call.message.chat.id, f"✅ Vous avez approuvé <code>{target_id}</code>.", parse_mode="HTML")
        try:
            bot.send_message(int(requester_id), f"🎉 Votre demande pour <code>{target_id}</code> a été approuvée.", parse_mode="HTML")
        except Exception as e:
            logging.warning("Could not notify requester %s: %s", requester_id, e)
    else:
        bot.send_message(call.message.chat.id, f"❌ Vous avez refusé <code>{target_id}</code>.", parse_mode="HTML")
        try:
            bot.send_message(int(requester_id), f"🚫 Le Super Admin a refusé l'ajout de <code>{target_id}</code>.", parse_mode="HTML")
        except Exception as e:
            logging.warning("Could not notify requester %s: %s", requester_id, e)

@bot.callback_query_handler(func=lambda call: call.data == "req_del_admin")
def req_del_admin(call):
    if not is_admin(call.from_user.id): return
    msg = bot.send_message(call.message.chat.id, "👤 Entrez l'ID Telegram de l'administrateur à révoquer :")
    bot.register_next_step_handler(msg, _process_del_admin, call.from_user.id)

def _process_del_admin(message, requester_id):
    target_id = message.text.strip()
    if not target_id.isdigit():
        bot.send_message(message.chat.id, "❌ L'ID doit être un nombre entier.")
        return

    if admin_core.is_super_admin(requester_id):
        success, res = admin_core.remove_admin(target_id)
        status = "✅" if success else "❌"
        bot.send_message(message.chat.id, f"{status} {res}", reply_markup=main_menu_keyboard())
    else:
        bot.send_message(message.chat.id, "⏳ <b>Demande de révocation envoyée au Super Admin.</b>", parse_mode="HTML")
        super_admin_id = admin_core.get_config().get('super_admin')
        markup = InlineKeyboardMarkup(row_width=2)
        markup.add(
            InlineKeyboardButton("✅ Révoquer", callback_data=f"adm:revoke:{target_id}:{requester_id}"),
            InlineKeyboardButton("❌ Annuler", callback_data=f"adm:cancel:{target_id}:{requester_id}")
        )
        bot.send_message(
            super_admin_id,
            f"⚠️ <b>DEMANDE RÉVOCATION ADMIN</b>\n\nL'admin <code>{requester_id}</code> demande la révocation de <code>{target_id}</code>.",
            parse_mode="HTML", reply_markup=markup
        )

@bot.callback_query_handler(func=lambda call: call.data == "req_promote_admin")
def req_promote_admin_to_supreme(call):
    if not admin_core.is_super_admin(call.from_user.id):
        bot.answer_callback_query(call.id, "⛔ Réservé aux Super Admins.")
        return
    msg = bot.send_message(call.message.chat.id, "👑 Entrez l'ID Telegram de l'administrateur à promouvoir en Super Admin :")
    bot.register_next_step_handler(msg, _process_promote_admin_to_supreme)

def _process_promote_admin_to_supreme(message):
    target_id = message.text.strip()
    if not target_id.isdigit():
        bot.send_message(message.chat.id, "❌ L'ID doit être un nombre entier.")
        return
    success, res = admin_core.promote_admin_to_supreme(int(target_id))
    status = "✅" if success else "❌"
    bot.send_message(message.chat.id, f"{status} {res}", parse_mode="HTML", reply_markup=main_menu_keyboard())

@bot.callback_query_handler(func=lambda call: call.data.startswith("adm:revoke:") or call.data.startswith("adm:cancel:"))
def handle_revoke_approval(call):
    if not admin_core.is_super_admin(call.from_user.id): return
    parts = call.data.split(":")
    action, target_id, requester_id = parts[1], parts[2], parts[3]

    bot.edit_message_reply_markup(call.message.chat.id, call.message.message_id, reply_markup=None)

    if action == "revoke":
        success, res = admin_core.remove_admin(target_id)
        bot.send_message(call.message.chat.id, f"✅ Admin <code>{target_id}</code> révoqué.", parse_mode="HTML")
        try:
            bot.send_message(int(requester_id), f"✅ La révocation de <code>{target_id}</code> a été effectuée.", parse_mode="HTML")
        except Exception as e:
            logging.warning("Could not notify requester %s: %s", requester_id, e)
    else:
        bot.send_message(call.message.chat.id, f"ℹ️ Révocation annulée pour <code>{target_id}</code>.", parse_mode="HTML")

if __name__ == "__main__":
    bot.infinity_polling()
