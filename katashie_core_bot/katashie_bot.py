#!/usr/bin/env python3
"""
KATASHIE VPN — Bot Telegram Principal v2
Ajouts: boutons inline, notifications auto, gestion revendeurs via bot
Contact: @abess237
"""
import telebot
from telebot import types
import json, os, sys, threading, time, logging

logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s %(message)s')
logger = logging.getLogger('katashie-bot')

CONFIG_PATH = os.environ.get('KATASHIE_BOT_CONFIG', '/etc/katashie_bot/config.json')
with open(CONFIG_PATH) as f:
    cfg = json.load(f)

BOT_TOKEN   = cfg['bot_token']
ADMIN_IDS   = cfg.get('admin_ids', [])
RESELLER_IDS = cfg.get('reseller_ids', [])

bot = telebot.TeleBot(BOT_TOKEN, parse_mode='HTML')

from modules.ssh_core   import SshCore
from modules.xray_core  import XrayCore
from modules.zivpn_core import ZivpnCore
from modules.system_core import SystemCore
from modules.admin_core import AdminCore

ssh   = SshCore(cfg)
xray  = XrayCore(cfg)
zivpn = ZivpnCore(cfg)
sys_c = SystemCore(cfg)
adm   = AdminCore(cfg)

BANNER = "🛡 <b>KATASHIE VPN</b> — Panel Telegram\n📲 @abess237"

def is_admin(uid): return uid in ADMIN_IDS
def is_reseller(uid): return uid in RESELLER_IDS or is_admin(uid)
def require_admin(msg):
    if not is_admin(msg.from_user.id):
        bot.reply_to(msg, "⛔ Accès réservé aux administrateurs.")
        return False
    return True
def require_reseller(msg):
    if not is_reseller(msg.from_user.id):
        bot.reply_to(msg, "⛔ Accès réservé aux revendeurs.")
        return False
    return True

# ─── INLINE KEYBOARD MENUS ────────────────────────────────────────────────────
def main_menu_keyboard(is_adm=False):
    kb = types.InlineKeyboardMarkup(row_width=2)
    kb.add(
        types.InlineKeyboardButton("👤 SSH", callback_data="menu_ssh"),
        types.InlineKeyboardButton("⚡ XRAY", callback_data="menu_xray"),
        types.InlineKeyboardButton("🌐 ZIVPN", callback_data="menu_zivpn"),
        types.InlineKeyboardButton("📊 Statut", callback_data="menu_status"),
    )
    if is_adm:
        kb.add(
            types.InlineKeyboardButton("👥 Revendeurs", callback_data="menu_resellers"),
            types.InlineKeyboardButton("🔧 Système", callback_data="menu_system"),
        )
    return kb

def ssh_menu_keyboard():
    kb = types.InlineKeyboardMarkup(row_width=2)
    kb.add(
        types.InlineKeyboardButton("➕ Créer", callback_data="ssh_create"),
        types.InlineKeyboardButton("📋 Lister", callback_data="ssh_list"),
        types.InlineKeyboardButton("🗑 Supprimer", callback_data="ssh_delete"),
        types.InlineKeyboardButton("🔄 Renouveler", callback_data="ssh_renew"),
        types.InlineKeyboardButton("◀ Retour", callback_data="main_menu"),
    )
    return kb

def xray_menu_keyboard():
    kb = types.InlineKeyboardMarkup(row_width=2)
    kb.add(
        types.InlineKeyboardButton("➕ VLESS", callback_data="xray_create_vless"),
        types.InlineKeyboardButton("➕ VMESS", callback_data="xray_create_vmess"),
        types.InlineKeyboardButton("➕ Trojan", callback_data="xray_create_trojan"),
        types.InlineKeyboardButton("📋 Lister", callback_data="xray_list"),
        types.InlineKeyboardButton("🗑 Supprimer", callback_data="xray_delete"),
        types.InlineKeyboardButton("◀ Retour", callback_data="main_menu"),
    )
    return kb

def reseller_menu_keyboard():
    kb = types.InlineKeyboardMarkup(row_width=2)
    kb.add(
        types.InlineKeyboardButton("➕ Créer revendeur", callback_data="reseller_create"),
        types.InlineKeyboardButton("📋 Lister revendeurs", callback_data="reseller_list"),
        types.InlineKeyboardButton("🔄 Renouveler", callback_data="reseller_renew"),
        types.InlineKeyboardButton("🗑 Suspendre", callback_data="reseller_suspend"),
        types.InlineKeyboardButton("◀ Retour", callback_data="main_menu"),
    )
    return kb

# ─── COMMANDS ─────────────────────────────────────────────────────────────────
@bot.message_handler(commands=['start', 'help'])
def start(msg):
    adm_flag = is_admin(msg.from_user.id)
    res_flag = is_reseller(msg.from_user.id)
    if not adm_flag and not res_flag:
        bot.reply_to(msg, "⛔ Vous n'avez pas accès à ce bot.\nContactez @abess237")
        return
    role = "Administrateur" if adm_flag else "Revendeur"
    bot.send_message(msg.chat.id,
        f"{BANNER}\n\n👋 Bonjour <b>{msg.from_user.first_name}</b> [{role}]\n\nChoisissez une action:",
        reply_markup=main_menu_keyboard(adm_flag))

@bot.message_handler(commands=['status'])
def status_cmd(msg):
    if not require_reseller(msg): return
    status = sys_c.get_system_status()
    bot.reply_to(msg, f"📊 <b>Statut Système</b>\n\n{status}")

@bot.message_handler(commands=['ssh_create'])
def ssh_create_cmd(msg):
    if not require_reseller(msg): return
    parts = msg.text.split()
    if len(parts) < 3:
        bot.reply_to(msg, "Usage: /ssh_create &lt;username&gt; &lt;jours&gt; [limite_gb]")
        return
    username, days = parts[1], parts[2]
    limit = parts[3] if len(parts) > 3 else None
    result = ssh.create_account(username, int(days), limit)
    bot.reply_to(msg, result)

@bot.message_handler(commands=['ssh_list'])
def ssh_list_cmd(msg):
    if not require_reseller(msg): return
    result = ssh.list_accounts()
    bot.reply_to(msg, result)

@bot.message_handler(commands=['ssh_delete'])
def ssh_delete_cmd(msg):
    if not require_reseller(msg): return
    parts = msg.text.split()
    if len(parts) < 2:
        bot.reply_to(msg, "Usage: /ssh_delete &lt;username&gt;")
        return
    result = ssh.delete_account(parts[1])
    bot.reply_to(msg, result)

@bot.message_handler(commands=['vless_create', 'vmess_create', 'trojan_create'])
def xray_create_cmd(msg):
    if not require_reseller(msg): return
    cmd = msg.text.split()[0][1:]
    protocol = cmd.replace('_create', '')
    parts = msg.text.split()
    if len(parts) < 3:
        bot.reply_to(msg, f"Usage: /{cmd} &lt;username&gt; &lt;jours&gt;")
        return
    result = xray.create_client(protocol, parts[1], int(parts[2]))
    bot.reply_to(msg, result)

@bot.message_handler(commands=['reseller_create'])
def reseller_create_cmd(msg):
    if not require_admin(msg): return
    parts = msg.text.split()
    if len(parts) < 4:
        bot.reply_to(msg, "Usage: /reseller_create &lt;username&gt; &lt;password&gt; &lt;jours&gt; [max_clients]")
        return
    username, password, days = parts[1], parts[2], parts[3]
    max_clients = int(parts[4]) if len(parts) > 4 else 50
    result = adm.create_reseller(username, password, int(days), max_clients)
    bot.reply_to(msg, result)

@bot.message_handler(commands=['reseller_list'])
def reseller_list_cmd(msg):
    if not require_admin(msg): return
    result = adm.list_resellers()
    bot.reply_to(msg, result)

# ─── INLINE CALLBACKS ─────────────────────────────────────────────────────────
@bot.callback_query_handler(func=lambda c: True)
def callback_handler(call):
    uid = call.from_user.id
    adm_flag = is_admin(uid)
    res_flag = is_reseller(uid)
    if not adm_flag and not res_flag:
        bot.answer_callback_query(call.id, "⛔ Accès refusé")
        return

    bot.answer_callback_query(call.id)

    if call.data == "main_menu":
        bot.edit_message_text(
            f"{BANNER}\n\nChoisissez une action:",
            call.message.chat.id, call.message.message_id,
            reply_markup=main_menu_keyboard(adm_flag)
        )

    elif call.data == "menu_ssh":
        bot.edit_message_text(
            "👤 <b>Gestion SSH</b>",
            call.message.chat.id, call.message.message_id,
            reply_markup=ssh_menu_keyboard()
        )

    elif call.data == "menu_xray":
        bot.edit_message_text(
            "⚡ <b>Gestion XRAY (VLESS/VMESS/Trojan)</b>",
            call.message.chat.id, call.message.message_id,
            reply_markup=xray_menu_keyboard()
        )

    elif call.data == "menu_resellers" and adm_flag:
        bot.edit_message_text(
            "👥 <b>Gestion Revendeurs</b>",
            call.message.chat.id, call.message.message_id,
            reply_markup=reseller_menu_keyboard()
        )

    elif call.data == "menu_status":
        status = sys_c.get_system_status()
        kb = types.InlineKeyboardMarkup()
        kb.add(types.InlineKeyboardButton("🔄 Actualiser", callback_data="menu_status"),
               types.InlineKeyboardButton("◀ Menu", callback_data="main_menu"))
        bot.edit_message_text(
            f"📊 <b>Statut Système</b>\n\n{status}",
            call.message.chat.id, call.message.message_id,
            reply_markup=kb
        )

    elif call.data == "ssh_list":
        result = ssh.list_accounts()
        kb = types.InlineKeyboardMarkup()
        kb.add(types.InlineKeyboardButton("◀ Retour", callback_data="menu_ssh"))
        bot.edit_message_text(result, call.message.chat.id, call.message.message_id, reply_markup=kb)

    elif call.data == "xray_list":
        result = xray.list_clients()
        kb = types.InlineKeyboardMarkup()
        kb.add(types.InlineKeyboardButton("◀ Retour", callback_data="menu_xray"))
        bot.edit_message_text(result, call.message.chat.id, call.message.message_id, reply_markup=kb)

    elif call.data == "reseller_list" and adm_flag:
        result = adm.list_resellers()
        kb = types.InlineKeyboardMarkup()
        kb.add(types.InlineKeyboardButton("◀ Retour", callback_data="menu_resellers"))
        bot.edit_message_text(result, call.message.chat.id, call.message.message_id, reply_markup=kb)

    elif call.data in ["ssh_create", "ssh_delete", "ssh_renew", "xray_create_vless",
                        "xray_create_vmess", "xray_create_trojan", "xray_delete",
                        "reseller_create", "reseller_renew", "reseller_suspend"]:
        action_map = {
            "ssh_create": "Envoyer: /ssh_create &lt;username&gt; &lt;jours&gt;",
            "ssh_delete": "Envoyer: /ssh_delete &lt;username&gt;",
            "ssh_renew":  "Envoyer: /ssh_renew &lt;username&gt; &lt;jours&gt;",
            "xray_create_vless":  "Envoyer: /vless_create &lt;username&gt; &lt;jours&gt;",
            "xray_create_vmess":  "Envoyer: /vmess_create &lt;username&gt; &lt;jours&gt;",
            "xray_create_trojan": "Envoyer: /trojan_create &lt;username&gt; &lt;jours&gt;",
            "xray_delete": "Envoyer: /xray_delete &lt;username&gt;",
            "reseller_create":  "Envoyer: /reseller_create &lt;username&gt; &lt;password&gt; &lt;jours&gt;",
            "reseller_renew":   "Envoyer: /reseller_renew &lt;username&gt; &lt;jours&gt;",
            "reseller_suspend": "Envoyer: /reseller_suspend &lt;username&gt;",
        }
        hint = action_map.get(call.data, "Commande inconnue")
        bot.send_message(call.message.chat.id, f"📝 {hint}")

# ─── NOTIFICATION THREAD ─────────────────────────────────────────────────────
def notification_worker():
    """Envoie des alertes de CPU et d'expiry toutes les heures"""
    while True:
        try:
            time.sleep(3600)  # every hour
            # CPU alert
            cpu = sys_c.get_cpu_percent()
            if cpu > 80:
                for aid in ADMIN_IDS:
                    try:
                        bot.send_message(aid, f"🚨 <b>Alerte CPU</b>\n\nCPU à <b>{cpu:.1f}%</b> — vérifiez le serveur !")
                    except Exception: pass

            # Expiry alerts (24h)
            expiring = ssh.get_expiring_soon(hours=24)
            if expiring:
                msg = "⚠️ <b>Comptes expirant dans 24h</b>\n\n"
                msg += "\n".join(f"• <code>{u}</code>" for u in expiring[:15])
                for aid in ADMIN_IDS:
                    try: bot.send_message(aid, msg)
                    except Exception: pass
        except Exception as e:
            logger.error(f"Notification error: {e}")

if __name__ == '__main__':
    logger.info("KATASHIE VPN Bot v2 starting...")
    threading.Thread(target=notification_worker, daemon=True).start()
    bot.infinity_polling(timeout=30, long_polling_timeout=15)
