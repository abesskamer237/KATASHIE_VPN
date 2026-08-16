with open("katashie_bot.py", "r") as f:
    content = f.read()

ssh_logic = """
# --- LOGIQUE DE CRÉATION SSH (STATE MACHINE) ---
@bot.callback_query_handler(func=lambda call: call.data == "add_ssh")
def add_ssh_start(call):
    if not is_admin(call.from_user.id): return
    bot.edit_message_text("⚙️ Module SSH activé.", chat_id=call.message.chat.id, message_id=call.message.message_id)
    msg = bot.send_message(call.message.chat.id, "👤 <b>Étape 1/3</b>\nEntrez le nom d'utilisateur SSH :", parse_mode="HTML")
    bot.register_next_step_handler(msg, process_ssh_user)

def process_ssh_user(message):
    user = message.text
    msg = bot.send_message(message.chat.id, "🔑 <b>Étape 2/3</b>\nEntrez le mot de passe :", parse_mode="HTML")
    bot.register_next_step_handler(msg, process_ssh_pass, user)

def process_ssh_pass(message, user):
    password = message.text
    msg = bot.send_message(message.chat.id, "⏳ <b>Étape 3/3</b>\nEntrez la durée (en jours) :", parse_mode="HTML")
    bot.register_next_step_handler(msg, process_ssh_days, user, password)

def process_ssh_days(message, user, password):
    days = message.text
    if not days.isdigit():
        bot.send_message(message.chat.id, "❌ Le nombre de jours doit être un entier. Annulation.", reply_markup=main_menu_keyboard())
        return

    bot.send_message(message.chat.id, f"⚙️ Déploiement du compte <b>{user}</b> au niveau du noyau...", parse_mode="HTML")
    
    import subprocess
    # Exécution silencieuse en contournant l'interface bash interactive
    cmd = f"useradd -e $(date -d '{days} days' +'%Y-%m-%d') -s /bin/false -M {user} && echo '{user}:{password}' | chpasswd"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if res.returncode == 0:
        success_msg = f"✅ <b>COMPTE SSH FORGÉ AVEC SUCCÈS</b>\n\n👤 Username : <code>{user}</code>\n🔑 Password : <code>{password}</code>\n⏳ Validité : {days} Jours"
        bot.send_message(message.chat.id, success_msg, parse_mode="HTML", reply_markup=main_menu_keyboard())
    else:
        bot.send_message(message.chat.id, f"❌ Échec de la création :\n<code>{res.stderr}</code>", parse_mode="HTML", reply_markup=main_menu_keyboard())

"""

# On insère la logique juste avant le lancement de la boucle principale
content = content.replace('if __name__ == "__main__":', ssh_logic + '\nif __name__ == "__main__":')

with open("katashie_bot.py", "w") as f:
    f.write(content)
