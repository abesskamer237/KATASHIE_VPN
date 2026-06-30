# Fichier : core/xray_handler.py
import json
import uuid
import subprocess
import os

# Ajuste ce chemin selon où ton script Nexus Tunnel Pro stocke sa config Xray
XRAY_CONFIG_PATH = "/usr/local/etc/xray/config.json" 

def create_vless_user(username, bug_host="bug.cdn.com"):
    try:
        if not os.path.exists(XRAY_CONFIG_PATH):
            return False, f"Fichier {XRAY_CONFIG_PATH} introuvable."

        user_uuid = str(uuid.uuid4())
        
        with open(XRAY_CONFIG_PATH, 'r') as f:
            config = json.load(f)
            
        new_client = {
            "id": user_uuid,
            "email": username,
            "flow": "xtls-rprx-direct"
        }
        
        # On ajoute le client dans le premier inbound (généralement VLESS 443)
        config['inbounds'][0]['settings']['clients'].append(new_client)
        
        with open(XRAY_CONFIG_PATH, 'w') as f:
            json.dump(config, f, indent=4)
            
        subprocess.run(["systemctl", "restart", "xray"], check=True)
        
        # Payload formaté pour le free surf
        vless_link = f"vless://{user_uuid}@{bug_host}:443?type=ws&security=tls&path=/vless#{username}"
        return True, vless_link
        
    except Exception as e:
        return False, str(e)
      
