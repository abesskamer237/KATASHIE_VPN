# Fichier : utils/qr_generator.py
import qrcode
import os

def generate_vpn_qr(config_link, username):
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(config_link)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    filepath = f"/root/doty_bot/{username}_qr.png"
    img.save(filepath)
    
    return filepath
  
