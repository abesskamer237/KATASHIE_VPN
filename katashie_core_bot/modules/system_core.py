import subprocess
import psutil
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton

def get_vps_status():
    try:
        # Récupération de l'uptime et OS
        uptime = subprocess.check_output("uptime -p", shell=True).decode('utf-8').strip()
        os_info = subprocess.check_output("cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | tr -d '\"'", shell=True).decode('utf-8').strip()
        
        # CPU & RAM
        cpu_usage = psutil.cpu_percent(interval=1)
        ram = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        status_msg = (
            f"📊 <b>ÉTAT DU SERVEUR KATASHIE</b>\n\n"
            f"🖥️ <b>OS:</b> <code>{os_info}</code>\n"
            f"⏱️ <b>Uptime:</b> <code>{uptime}</code>\n"
            f"⚙️ <b>CPU:</b> <code>{cpu_usage}%</code>\n"
            f"💾 <b>RAM:</b> <code>{ram.percent}%</code> ({ram.used // (1024**2)}MB / {ram.total // (1024**2)}MB)\n"
            f"💽 <b>Disque:</b> <code>{disk.percent}%</code> ({disk.used // (1024**3)}GB / {disk.total // (1024**3)}GB)\n"
        )
        return status_msg
    except Exception as e:
        return f"❌ Erreur de lecture système : {str(e)}"

def clean_system_logs():
    subprocess.run("journalctl --vacuum-time=1d && apt-get clean", shell=True)
    return "🧹 <b>Logs et Cache nettoyés avec succès.</b>"
