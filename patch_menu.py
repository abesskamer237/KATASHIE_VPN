import os
path = "menu/menu.sh"
with open(path, "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if "[14] • KATASHIE BOT PANEL" in line:
        # On remplace la ligne Tools pour inclure 14 et 15 proprement
        new_lines.append('echo -e "${LN}┃${NC} [07] • DNS PANEL          [11] • NETGUARD PANEL"\n')
        new_lines.append('echo -e "${LN}┃${NC} [08] • DOMAIN PANEL       [12] • VPN PORT INFO"\n')
        new_lines.append('echo -e "${LN}┃${NC} [09] • IPV6 PANEL         [13] • CLEAN VPS LOGS"\n')
        new_lines.append('echo -e "${LN}┃${NC} [10] • VPS STATUS         [14] • KATASHIE BOT PANEL"\n')
        new_lines.append('echo -e "${LN}┃${NC} [15] • UNINSTALL KATASHIE"\n')
    elif "14) clear ; tgbot ;;" in line:
        new_lines.append(line)
        new_lines.append("15) clear ; uninstall ;;\n")
    elif "[11] • NETGUARD PANEL" in line or "[12] • VPN PORT INFO" in line or "[13] • CLEAN VPS LOGS" in line or "[10] • VPS STATUS" in line:
        continue # On saute les anciennes lignes pour éviter les doublons
    else:
        new_lines.append(line)

with open(path, "w") as f:
    f.writelines(new_lines)
