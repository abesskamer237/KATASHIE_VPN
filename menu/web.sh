#!/bin/bash
# ============================================================
#  Menu 18 — Nexus Tunnel Web
#  Manages the Nexus Tunnel Web panel from terminal.
# ============================================================

LN='\e[36m'
NC='\e[0m'
BG='\e[44m'
RD='\e[31m'
GR='\e[32m'
YL='\e[33m'

NEXUS_WEB_DIR="/opt/katashie-tunnel-web"
CONFIG_DIR="/etc/katashie-tunnel-web"
CONFIG_FILE="$CONFIG_DIR/config.json"
SERVICE="nexus-web"
INSTALL_SH="$NEXUS_WEB_DIR/install.sh"
NEXUS_REPO_URL="https://github.com/RootNexTPro/nexTPro-ScriptAll.git"
TMP_WEB_SRC="/tmp/nexus-web-src-$$"

# ─── Helpers ──────────────────────────────────────────────────────────────────

get_config_value() {
  local key="$1"
  if [ -f "$CONFIG_FILE" ]; then
    python3 -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('$key',''))" 2>/dev/null || \
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$CONFIG_FILE" | head -1 | sed 's/.*: *"//;s/"//'
  fi
}

set_config_value() {
  local key="$1" value="$2"
  if [ -f "$CONFIG_FILE" ]; then
    python3 - "$CONFIG_FILE" "$key" "$value" <<'PYEOF'
import json, sys
path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f: d = json.load(f)
# Try to cast value to int/float if appropriate
try: value = int(value)
except ValueError:
    try: value = float(value)
    except ValueError: pass
d[key] = value
with open(path, 'w') as f: json.dump(d, f, indent=2)
PYEOF
  fi
}

web_is_installed() {
  [ -f "$NEXUS_WEB_DIR/dist/server/index.js" ]
}

web_is_running() {
  systemctl is-active --quiet "$SERVICE" 2>/dev/null
}

get_web_port() {
  get_config_value "port" || echo "2087"
}

get_web_url() {
  local ip
  ip=$(curl -s4 ipv4.icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
  local port
  port=$(get_web_port)
  echo "http://$ip:$port"
}

wait_key() {
  echo ""
  read -n 1 -s -r -p "  Press any key to continue..."
  echo ""
}

log_info() {
  echo -e "${YL}[INFO]${NC} $*"
}

resolve_web_source_dir() {
  local base src
  base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # 1) bundled next to menu dir in repository clone
  src="$base/../nexus-web"
  if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
    echo "$src"
    return 0
  fi

  # 2) already copied on server where menu expects it
  src="/usr/local/sbin/nexus-web"
  if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
    echo "$src"
    return 0
  fi

  # 3) already installed app source
  src="/opt/katashie-tunnel-web"
  if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
    echo "$src"
    return 0
  fi

  # 4) fallback: shallow clone repository in /tmp and use nexus-web folder
  rm -rf "$TMP_WEB_SRC"
  if git clone --depth 1 "$NEXUS_REPO_URL" "$TMP_WEB_SRC" >/dev/null 2>&1; then
    src="$TMP_WEB_SRC/nexus-web"
    if [ -d "$src" ] && [ -f "$src/install.sh" ]; then
      echo "$src"
      return 0
    fi
  fi

  return 1
}

# ─── API Helper ───────────────────────────────────────────────────────────────
api_login() {
  local user="$1" pass="$2"
  local port
  port=$(get_web_port)
  curl -s -X POST "http://localhost:$port/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$user\",\"password\":\"$pass\"}" 2>/dev/null
}

api_call() {
  local method="$1" path="$2" token="$3" body="${4:-}"
  local port
  port=$(get_web_port)
  local url="http://localhost:$port/api$path"
  if [ -n "$body" ]; then
    curl -s -X "$method" "$url" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $token" \
      -d "$body" 2>/dev/null
  else
    curl -s -X "$method" "$url" \
      -H "Authorization: Bearer $token" 2>/dev/null
  fi
}

# ─── MAIN MENU ────────────────────────────────────────────────────────────────
function nexus_web_menu() {
  clear
  local status_str
  if web_is_running; then
    status_str="${GR}RUNNING${NC}"
  else
    status_str="${RD}STOPPED${NC}"
  fi

  local url
  url=$(get_web_url 2>/dev/null || echo "http://localhost:2087")

  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}           KATASHIE VPN WEB — MENU 18           ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC}  Status  : ${status_str}"
  echo -e "${LN}┃${NC}  URL     : ${GR}${url}${NC}"
  echo -e "${LN}┃${NC}  Admin   : $(get_config_value admin_user 2>/dev/null || echo 'N/A')"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"

  if ! web_is_installed; then
    echo -e "${LN}┃${NC} ${YL}  Nexus Tunnel Web is NOT installed.${NC}"
    echo -e "${LN}┃${NC}"
    echo -e "${LN}┃${NC} ${GR}[1]${NC} • Install Nexus Tunnel Web"
    echo -e "${LN}┃${NC} ${GR}[0]${NC} • Return to main menu"
    echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo ""
    read -rp "  Select option : " opt
    case "$opt" in
      1) ntw_install ;;
      0|00) menu ;;
      *) nexus_web_menu ;;
    esac
    return
  fi

  echo -e "${LN}┃${NC} ${BG}              SITE ADMINISTRATION               ${NC} ${LN}┃${NC}"
  echo -e "${LN}┃${NC}"
  echo -e "${LN}┃${NC} [1] • Modifier identifiants admin"
  echo -e "${LN}┃${NC} [2] • Manager Admin"
  echo -e "${LN}┃${NC} [3] • Manager Client"
  echo -e "${LN}┃${NC} [4] • Manager Plans / Produits"
  echo -e "${LN}┃${NC} [5] • Logs & Audit"
  echo -e "${LN}┃${NC} [6] • Statut & Contrôle du service"
  echo -e "${LN}┃${NC} [7] • Mettre à jour Nexus Tunnel Web"
  echo -e "${LN}┃${NC} [8] • Désinstaller Nexus Tunnel Web"
  echo -e "${LN}┃${NC} [0] • Retour"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${LN}●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●${NC}"
  echo ""
  read -rp "  Select option : " opt
  echo ""

  case "$opt" in
    1) ntw_change_credentials ;;
    2) ntw_manager_admin ;;
    3) ntw_manager_client ;;
    4) ntw_manager_plans ;;
    5) ntw_view_logs ;;
    6) ntw_service_control ;;
    7) ntw_update ;;
    8) ntw_uninstall ;;
    0|00) menu ;;
    *) nexus_web_menu ;;
  esac
}

# ─── INSTALL ──────────────────────────────────────────────────────────────────
function ntw_install() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}         INSTALLATION — KATASHIE VPN WEB         ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  echo -e "  Ce script va installer l'interface web Nexus Tunnel."
  echo -e "  Vous aurez besoin de définir un identifiant admin."
  echo ""

  local src_dir
  if src_dir="$(resolve_web_source_dir)"; then
    bash "$src_dir/install.sh"
  elif [ -f /opt/katashie-tunnel-web/install.sh ]; then
    bash /opt/katashie-tunnel-web/install.sh
  else
    echo -e "${RD}  [ERROR] Source install script not found.${NC}"
    echo -e "  Expected one of:"
    echo -e "    - /usr/local/sbin/nexus-web/install.sh"
    echo -e "    - /opt/katashie-tunnel-web/install.sh"
    echo -e "    - <repo>/nexus-web/install.sh"
    echo -e "  Tip: check internet access if auto-fetch failed."
    wait_key
    nexus_web_menu
    return
  fi

  rm -rf "$TMP_WEB_SRC" 2>/dev/null || true
  wait_key
  nexus_web_menu
}

# ─── CHANGE CREDENTIALS ───────────────────────────────────────────────────────
function ntw_change_credentials() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}           MODIFIER IDENTIFIANTS ADMIN           ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""

  local current_user
  current_user=$(get_config_value admin_user)

  read -rp "  Username actuel : " curr_pass_user
  read -srp "  Mot de passe actuel : " curr_pass; echo ""
  echo ""

  # Get token via API
  local resp token_val
  resp=$(api_login "$curr_pass_user" "$curr_pass")
  token_val=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)

  if [ -z "$token_val" ]; then
    echo -e "${RD}  [ERROR] Identifiants incorrects.${NC}"
    wait_key
    nexus_web_menu
    return
  fi

  echo -e "  ${GR}Authentification réussie!${NC}"
  echo ""
  read -rp "  Nouveau username (laisser vide pour ne pas changer) : " new_user
  read -srp "  Nouveau mot de passe (laisser vide pour ne pas changer) : " new_pass; echo ""
  read -srp "  Confirmer nouveau mot de passe : " new_pass2; echo ""

  if [ -n "$new_pass" ] && [ "$new_pass" != "$new_pass2" ]; then
    echo -e "${RD}  [ERROR] Les mots de passe ne correspondent pas.${NC}"
    wait_key
    nexus_web_menu
    return
  fi

  local body='{'
  body+="\"current_password\":\"$curr_pass\""
  [ -n "$new_user" ] && body+=",\"new_username\":\"$new_user\""
  [ -n "$new_pass" ] && body+=",\"new_password\":\"$new_pass\""
  body+='}'

  local result
  result=$(api_call "POST" "/auth/change-password" "$token_val" "$body")
  local msg
  msg=$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('message',d.get('error','')))" 2>/dev/null)

  if echo "$result" | grep -q '"message"'; then
    # Update config file
    [ -n "$new_user" ] && { set_config_value admin_user "$new_user"; systemctl restart "$SERVICE" 2>/dev/null; }
    [ -n "$new_pass" ] && { set_config_value admin_password "$new_pass"; systemctl restart "$SERVICE" 2>/dev/null; }
    echo -e "  ${GR}[OK] $msg${NC}"
  else
    echo -e "  ${RD}[ERROR] $msg${NC}"
  fi

  wait_key
  nexus_web_menu
}

# ─── MANAGER ADMIN ────────────────────────────────────────────────────────────
function ntw_manager_admin() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}                MANAGER ADMIN                   ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} [1] • Créer un compte admin"
  echo -e "${LN}┃${NC} [2] • Voir les informations des admins"
  echo -e "${LN}┃${NC} [3] • Modifier les informations d'un admin"
  echo -e "${LN}┃${NC} [4] • Suspendre un admin"
  echo -e "${LN}┃${NC} [5] • Promouvoir un admin en super admin"
  echo -e "${LN}┃${NC} [0] • Retour"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  read -rp "  Sélectionner : " opt
  echo ""

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  case "$opt" in
    1) ntw_create_admin "$token" ;;
    2) ntw_list_admins "$token" ;;
    3) ntw_edit_admin "$token" ;;
    4) ntw_suspend_admin "$token" ;;
    5) ntw_promote_admin "$token" ;;
    0|00) nexus_web_menu ;;
    *) ntw_manager_admin ;;
  esac
}

function ntw_get_token() {
  local admin_user admin_pass token resp
  admin_user=$(get_config_value admin_user)
  admin_pass=$(get_config_value admin_password)

  resp=$(api_login "$admin_user" "$admin_pass")
  token=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)

  if [ -z "$token" ]; then
    echo -e "${RD}  [ERROR] Impossible de s'authentifier. Vérifiez que le service est actif.${NC}" >&2
    wait_key >&2
    return 1
  fi
  echo "$token"
}

function ntw_create_admin() {
  local token="$1"
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}              CRÉER COMPTE ADMIN                ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""

  read -rp "  Nouveau username : " new_user
  read -srp "  Mot de passe     : " new_pass; echo ""
  echo "  Rôle : [1] admin  [2] super_admin"
  read -rp "  Choix : " role_opt
  local role="admin"
  [ "$role_opt" = "2" ] && role="super_admin"

  local result
  result=$(api_call "POST" "/admins" "$token" \
    "{\"username\":\"$new_user\",\"password\":\"$new_pass\",\"role\":\"$role\"}")

  if echo "$result" | grep -q '"id"'; then
    echo -e "  ${GR}[OK] Admin '$new_user' ($role) créé avec succès!${NC}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error','Unknown error'))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi

  wait_key
  ntw_manager_admin
}

function ntw_list_admins() {
  local token="$1"
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}             LISTE DES ADMINS                   ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""

  local result
  result=$(api_call "GET" "/admins" "$token")

  echo "$result" | python3 -c "
import json, sys
admins = json.load(sys.stdin)
if isinstance(admins, dict) and 'error' in admins:
    print(f'  [ERROR] {admins[\"error\"]}')
else:
    print(f'  {\"ID\":<36}  {\"Username\":<15}  {\"Role\":<12}  {\"Status\":<10}  Created')
    print('  ' + '-'*90)
    for a in admins:
        print(f'  {a[\"id\"]:<36}  {a[\"username\"]:<15}  {a[\"role\"]:<12}  {a[\"status\"]:<10}  {a[\"created_at\"][:10]}')
" 2>/dev/null || echo "$result"

  wait_key
  ntw_manager_admin
}

function ntw_edit_admin() {
  local token="$1"
  clear
  echo -e "${LN}┃${NC} ${BG}           MODIFIER INFO ADMIN                  ${NC} ${LN}┃${NC}"
  echo ""

  local result admins_list
  result=$(api_call "GET" "/admins" "$token")
  echo "$result" | python3 -c "
import json, sys
admins = json.load(sys.stdin)
for i, a in enumerate(admins, 1):
    print(f'  [{i}] {a[\"username\"]} ({a[\"role\"]}) — {a[\"id\"]}')
" 2>/dev/null

  echo ""
  read -rp "  Entrez l'ID de l'admin à modifier : " admin_id
  read -rp "  Nouveau username (vide=inchangé) : " nu
  read -srp "  Nouveau mot de passe (vide=inchangé) : " np; echo ""

  local body='{'
  local sep=""
  [ -n "$nu" ] && { body+="${sep}\"username\":\"$nu\""; sep=","; }
  [ -n "$np" ] && { body+="${sep}\"password\":\"$np\""; }
  body+='}'

  if [ "$body" = '{}' ]; then
    echo -e "  ${YL}Aucune modification.${NC}"
  else
    local res
    res=$(api_call "PUT" "/admins/$admin_id" "$token" "$body")
    if echo "$res" | grep -q '"message"'; then
      echo -e "  ${GR}[OK] Admin modifié.${NC}"
    else
      local err
      err=$(echo "$res" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
      echo -e "  ${RD}[ERROR] $err${NC}"
    fi
  fi

  wait_key
  ntw_manager_admin
}

function ntw_suspend_admin() {
  local token="$1"
  clear
  read -rp "  ID de l'admin à suspendre : " admin_id
  local res
  res=$(api_call "POST" "/admins/$admin_id/suspend" "$token")
  if echo "$res" | grep -q '"message"'; then
    echo -e "  ${GR}[OK] Admin suspendu.${NC}"
  else
    local err
    err=$(echo "$res" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi
  wait_key
  ntw_manager_admin
}

function ntw_promote_admin() {
  local token="$1"
  clear
  read -rp "  ID de l'admin à promouvoir : " admin_id
  local res
  res=$(api_call "POST" "/admins/$admin_id/promote" "$token")
  if echo "$res" | grep -q '"message"'; then
    echo -e "  ${GR}[OK] Admin promu en super_admin!${NC}"
  else
    local err
    err=$(echo "$res" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi
  wait_key
  ntw_manager_admin
}

# ─── MANAGER CLIENT ───────────────────────────────────────────────────────────
function ntw_manager_client() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}               MANAGER CLIENT                   ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC}  Les clients sont gérés via l'interface web."
  echo -e "${LN}┃${NC}  Accédez au site pour créer/modifier/supprimer."
  echo -e "${LN}┃${NC}"
  echo -e "${LN}┃${NC}  URL : ${GR}$(get_web_url 2>/dev/null)${NC}"
  echo -e "${LN}┃${NC}"
  echo -e "${LN}┃${NC} [1] • Voir la liste des clients"
  echo -e "${LN}┃${NC} [2] • Créer un client (via API)"
  echo -e "${LN}┃${NC} [3] • Renouveler un client (via API)"
  echo -e "${LN}┃${NC} [4] • Suspendre un client (via API)"
  echo -e "${LN}┃${NC} [5] • Supprimer un client (via API)"
  echo -e "${LN}┃${NC} [0] • Retour"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  read -rp "  Sélectionner : " opt
  echo ""

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  case "$opt" in
    1) ntw_list_clients "$token" ;;
    2) ntw_create_client "$token" ;;
    3) ntw_renew_client "$token" ;;
    4) ntw_suspend_client "$token" ;;
    5) ntw_delete_client "$token" ;;
    0|00) nexus_web_menu ;;
    *) ntw_manager_client ;;
  esac
}

function ntw_list_clients() {
  local token="$1"
  clear
  local result
  result=$(api_call "GET" "/clients" "$token")
  echo ""
  echo -e "${LN}  LISTE DES CLIENTS${NC}"
  echo ""
  echo "$result" | python3 -c "
import json, sys
clients = json.load(sys.stdin)
if isinstance(clients, dict) and 'error' in clients:
    print(f'  [ERROR] {clients[\"error\"]}')
else:
    print(f'  {\"Username\":<20}  {\"Protocol\":<12}  {\"Status\":<10}  {\"Expires\":<12}  ID')
    print('  ' + '-'*90)
    for c in clients:
        print(f'  {c[\"username\"]:<20}  {c[\"protocol\"]:<12}  {c[\"status\"]:<10}  {c[\"expires_at\"]:<12}  {c[\"id\"]}')
" 2>/dev/null || echo "$result"
  wait_key
  ntw_manager_client
}

function ntw_create_client() {
  local token="$1"
  clear
  echo -e "${LN}┃${NC} ${BG}              CRÉER UN CLIENT                   ${NC} ${LN}┃${NC}"
  echo ""

  read -rp "  Username         : " username
  read -rp "  Mot de passe     : " password
  echo "  Protocoles : [1] SSH  [2] SlowDNS  [3] UDP Custom  [4] VMess  [5] VLESS  [6] Trojan  [7] ZipVPN"
  read -rp "  Protocole       : " proto_opt
  declare -A proto_map=([1]="ssh" [2]="slowdns" [3]="udpcustom" [4]="vmess" [5]="vless" [6]="trojan" [7]="zipvpn")
  local protocol="${proto_map[$proto_opt]:-ssh}"
  read -rp "  Durée (jours)   : " days

  local result
  result=$(api_call "POST" "/clients" "$token" \
    "{\"username\":\"$username\",\"password\":\"$password\",\"protocol\":\"$protocol\",\"days\":$days}")

  if echo "$result" | grep -q '"id"'; then
    local expires
    expires=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('expires_at',''))" 2>/dev/null)
    echo -e "  ${GR}[OK] Client '$username' créé! Expiration: $expires${NC}"
    # Show account data
    echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ad = d.get('account_data', {})
print()
print('  ╔' + '━'*50 + '╗')
print('  ║  DÉTAILS DU COMPTE')
print('  ╚' + '━'*50 + '╝')
for k, v in ad.items():
    if v:
        print(f'  {k:<20}: {v}')
" 2>/dev/null
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error','Unknown'))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi

  wait_key
  ntw_manager_client
}

function ntw_renew_client() {
  local token="$1"
  clear
  read -rp "  ID du client : " client_id
  read -rp "  Jours de renouvellement : " days

  local result
  result=$(api_call "POST" "/clients/$client_id/renew" "$token" "{\"days\":$days}")
  if echo "$result" | grep -q '"expires_at"'; then
    local expires
    expires=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('expires_at',''))" 2>/dev/null)
    echo -e "  ${GR}[OK] Renouvelé! Nouvelle expiration: $expires${NC}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi
  wait_key
  ntw_manager_client
}

function ntw_suspend_client() {
  local token="$1"
  clear
  read -rp "  ID du client : " client_id
  local result
  result=$(api_call "POST" "/clients/$client_id/suspend" "$token")
  if echo "$result" | grep -q '"message"'; then
    echo -e "  ${GR}[OK] Client suspendu.${NC}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi
  wait_key
  ntw_manager_client
}

function ntw_delete_client() {
  local token="$1"
  clear
  read -rp "  ID du client à supprimer : " client_id
  read -rp "  Confirmer suppression? (oui/non) : " confirm
  if [[ "$confirm" != "oui" ]]; then
    echo -e "  ${YL}Annulé.${NC}"
    wait_key
    ntw_manager_client
    return
  fi
  local result
  result=$(api_call "DELETE" "/clients/$client_id" "$token")
  if echo "$result" | grep -q '"message"'; then
    echo -e "  ${GR}[OK] Client supprimé.${NC}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi
  wait_key
  ntw_manager_client
}

# ─── MANAGER PLANS ────────────────────────────────────────────────────────────
function ntw_manager_plans() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}           MANAGER PLANS / PRODUITS              ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  local result
  result=$(api_call "GET" "/plans" "$token")
  echo ""
  echo "$result" | python3 -c "
import json, sys
plans = json.load(sys.stdin)
if isinstance(plans, dict) and 'error' in plans:
    print(f'  [ERROR] {plans[\"error\"]}')
elif not plans:
    print('  Aucun plan créé.')
else:
    print(f'  {\"Nom\":<20}  {\"Durée\":<8}  {\"Prix\":<8}  {\"Conns\":<6}  {\"Statut\"}')
    print('  ' + '-'*60)
    for p in plans:
        print(f'  {p[\"name\"]:<20}  {str(p[\"duration_days\"]) + \"j\":<8}  \${p[\"price\"]:<7}  {p[\"max_connections\"]:<6}  {p[\"status\"]}')
" 2>/dev/null

  echo ""
  echo -e "  ${LN}[1]${NC} Créer un plan  ${LN}[0]${NC} Retour"
  read -rp "  Choix : " opt

  case "$opt" in
    1) ntw_create_plan "$token" ;;
    0) nexus_web_menu ;;
    *) ntw_manager_plans ;;
  esac
}

function ntw_create_plan() {
  local token="$1"
  clear
  echo -e "${LN}┃${NC} ${BG}               CRÉER UN PLAN                    ${NC} ${LN}┃${NC}"
  echo ""
  read -rp "  Nom du plan          : " name
  read -rp "  Description          : " desc
  read -rp "  Durée (jours)        : " days
  read -rp "  Prix ($, 0=gratuit)  : " price
  read -rp "  Protocoles (ssh,vmess,...) : " protos
  read -rp "  Max connexions       : " conns

  # Build protocols array
  local protos_json
  protos_json=$(python3 -c "import json; print(json.dumps([p.strip() for p in '$protos'.split(',') if p.strip()]))" 2>/dev/null || echo '["ssh"]')

  local result
  result=$(api_call "POST" "/plans" "$token" \
    "{\"name\":\"$name\",\"description\":\"$desc\",\"duration_days\":$days,\"price\":${price:-0},\"protocols\":$protos_json,\"max_connections\":${conns:-1}}")

  if echo "$result" | grep -q '"id"'; then
    echo -e "  ${GR}[OK] Plan '$name' créé!${NC}"
  else
    local err
    err=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null)
    echo -e "  ${RD}[ERROR] $err${NC}"
  fi

  wait_key
  ntw_manager_plans
}

# ─── LOGS & AUDIT ─────────────────────────────────────────────────────────────
function ntw_view_logs() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}               LOGS & AUDIT                     ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""

  local token
  token=$(ntw_get_token) || { nexus_web_menu; return; }

  local result
  result=$(api_call "GET" "/logs?limit=30" "$token")

  echo "$result" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'error' in data:
    print(f'  [ERROR] {data[\"error\"]}')
else:
    logs = data.get('logs', [])
    print(f'  Total: {data.get(\"total\", 0)} entrées — Affichage des 30 dernières')
    print()
    print(f'  {\"Date\":<20}  {\"Admin\":<15}  {\"Action\":<25}  {\"Cible\"}')
    print('  ' + '-'*80)
    for l in logs:
        dt = l[\"created_at\"][:19].replace(\"T\", \" \")
        print(f'  {dt:<20}  {(l[\"admin_username\"] or \"-\"):<15}  {l[\"action\"]:<25}  {l[\"target_type\"] or \"-\"}')
" 2>/dev/null || echo "$result"

  wait_key
  nexus_web_menu
}

# ─── SERVICE CONTROL ─────────────────────────────────────────────────────────
function ntw_service_control() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}             CONTRÔLE DU SERVICE                 ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  echo -e "  Service : ${LN}$SERVICE${NC}"
  echo -e "  Statut  : $(systemctl is-active $SERVICE 2>/dev/null)"
  echo ""
  echo -e "${LN}  [1]${NC} Démarrer   ${LN}[2]${NC} Arrêter   ${LN}[3]${NC} Redémarrer"
  echo -e "${LN}  [4]${NC} Voir les logs système  ${LN}[0]${NC} Retour"
  echo ""
  read -rp "  Choix : " opt

  case "$opt" in
    1) systemctl start "$SERVICE" && echo -e "  ${GR}Service démarré.${NC}" ;;
    2) systemctl stop "$SERVICE" && echo -e "  ${YL}Service arrêté.${NC}" ;;
    3) systemctl restart "$SERVICE" && echo -e "  ${GR}Service redémarré.${NC}" ;;
    4) journalctl -u "$SERVICE" -n 50 --no-pager | less -F ;;
    0) nexus_web_menu; return ;;
    *) ;;
  esac

  wait_key
  ntw_service_control
}

# ─── UPDATE ──────────────────────────────────────────────────────────────────
function ntw_update() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}          MISE À JOUR KATASHIE VPN WEB           ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  echo -e "  Cette option télécharge la dernière version depuis GitHub"
  echo -e "  et redéploie le panel en conservant vos données (DB, config)."
  read -rp "  Continuer? (oui/non) : " confirm

  if [[ "$confirm" != "oui" ]]; then
    echo -e "  ${YL}Annulé.${NC}"
    wait_key
    nexus_web_menu
    return
  fi

  # Pour la mise à jour on clone TOUJOURS depuis GitHub afin d'avoir
  # la vraie dernière version, pas la copie locale déjà installée.
  local tmp_src
  tmp_src="$(mktemp -d)"

  log_info "Téléchargement de la dernière version depuis GitHub..."
  if ! git clone --depth 1 "$NEXUS_REPO_URL" "$tmp_src" 2>&1 | tail -5; then
    echo -e "  ${RD}[ERROR] Impossible de cloner depuis GitHub. Vérifiez votre connexion.${NC}"
    rm -rf "$tmp_src"
    wait_key
    nexus_web_menu
    return
  fi

  local src_dir="$tmp_src/nexus-web"
  if [ ! -d "$src_dir" ] || [ ! -f "$src_dir/install.sh" ]; then
    echo -e "  ${RD}[ERROR] Dossier nexus-web introuvable dans le dépôt cloné.${NC}"
    rm -rf "$tmp_src"
    wait_key
    nexus_web_menu
    return
  fi

  log_info "Copie des nouveaux fichiers dans $NEXUS_WEB_DIR..."
  cp -rf "$src_dir"/. "$NEXUS_WEB_DIR/"

  # Ré-application du correctif ancrage absolu PUBLIC_DIR et CORS
  log_info "Application des correctifs (PUBLIC_DIR, CORS)..."
  sed -i "s|const PUBLIC_DIR = .*|const PUBLIC_DIR = '/opt/katashie-tunnel-web/public';|g" \
      "$NEXUS_WEB_DIR/server/index.ts" 2>/dev/null || true
  sed -i 's/callback(null, false);/callback(null, true);/g' \
      "$NEXUS_WEB_DIR/server/index.ts" 2>/dev/null || true

  log_info "Compilation de l'interface graphique (frontend)..."
  if [ -d "$NEXUS_WEB_DIR/frontend" ]; then
    cd "$NEXUS_WEB_DIR/frontend"
    npm install --quiet 2>&1 | tail -3
    npm run build 2>&1 | tail -8
  fi

  log_info "Compilation du serveur Node.js..."
  cd "$NEXUS_WEB_DIR"
  npm install --production=false --quiet 2>&1 | tail -3
  npm run build 2>&1 | tail -5

  log_info "Nettoyage et redémarrage du service..."
  rm -rf "$tmp_src"

  # Update the watchdog script (in case it changed)
  if [ -f "$NEXUS_WEB_DIR/install.sh" ]; then
    bash "$NEXUS_WEB_DIR/install.sh" --watchdog-only 2>/dev/null || true
  fi
  # Ensure watchdog cron exists
  if [ ! -f /etc/cron.d/nexus-web-watchdog ]; then
    echo "* * * * * root /usr/local/bin/nexus-web-watchdog.sh" > /etc/cron.d/nexus-web-watchdog
    chmod 644 /etc/cron.d/nexus-web-watchdog
  fi

  systemctl restart "$SERVICE"
  sleep 2

  echo -e "  ${GR}[OK] Mise à jour terminée ! Le panel est maintenant à jour.${NC}"
  wait_key
  nexus_web_menu
}

# ─── UNINSTALL ────────────────────────────────────────────────────────────────
function ntw_uninstall() {
  clear
  echo -e "${LN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${LN}┃${NC} ${BG}          DÉSINSTALLER KATASHIE VPN WEB          ${NC} ${LN}┃${NC}"
  echo -e "${LN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo ""
  echo -e "  ${RD}ATTENTION: Cette action supprimera l'interface web.${NC}"
  read -rp "  Confirmer la désinstallation? (oui/non) : " confirm

  if [[ "$confirm" != "oui" ]]; then
    echo -e "  ${YL}Annulé.${NC}"
    wait_key
    nexus_web_menu
    return
  fi

  read -rp "  Conserver les données (DB, config)? (oui/non) : " keep_data

  echo -e "  ${YL}Arrêt du service...${NC}"
  systemctl stop "$SERVICE" 2>/dev/null || true
  systemctl disable "$SERVICE" 2>/dev/null || true
  rm -f "/etc/systemd/system/$SERVICE.service"
  systemctl daemon-reload

  echo -e "  ${YL}Suppression des fichiers...${NC}"
  rm -rf "$NEXUS_WEB_DIR"

  if [[ "$keep_data" != "oui" ]]; then
    rm -rf "$CONFIG_DIR"
    echo -e "  ${YL}Données supprimées.${NC}"
  else
    echo -e "  ${GR}Données conservées dans $CONFIG_DIR${NC}"
  fi

  echo -e "  ${GR}[OK] Nexus Tunnel Web désinstallé.${NC}"
  wait_key
  menu
}

# ─── ENTRY POINT ─────────────────────────────────────────────────────────────
nexus_web_menu
