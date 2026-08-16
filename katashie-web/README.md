# KATASHIE VPN Web

Interface web d'administration pour **KATASHIE VPN** (KATASHIE_VPN).  
Gestion complète des comptes VPN (SSH, SlowDNS, UDP Custom, ZipVPN, Xray) depuis un panel web moderne.

---

## 🚀 Installation

### Via le menu (recommandé)
```bash
menu          # Lancer le menu principal
# Sélectionner [18] KATASHIE TUNNEL WEB
# Sélectionner [1] Installer KATASHIE VPN Web
```

### Directement depuis le dossier source
```bash
cd /path/to/KATASHIE_VPN/katashie-web
bash install.sh
```

L'installateur va :
1. Demander le **username** et **password** admin (utilisés pour se connecter au site)
2. Détecter un port libre (2087 par défaut — liste : 2087, 2096, 8787, 3001, 9090)
3. Installer Node.js 18+ si absent
4. Compiler le TypeScript
5. Créer le service systemd `katashie-web`
6. Démarrer le panel

---

## 🌐 Accès au panel

```
http://<IP-VPS>:<PORT>
```
Le port utilisé est affiché à la fin de l'installation et stocké dans `/etc/katashie-vpn-web/config.json`.

---

## ⚙️ Configuration

**Fichier :** `/etc/katashie-vpn-web/config.json`

```json
{
  "port": 2087,
  "admin_user": "admin",
  "admin_password": "votre_mot_de_passe",
  "jwt_secret": "secret_généré_automatiquement",
  "scripts_dir": "/usr/local/sbin",
  "db_dir": "/etc/katashie-vpn-web"
}
```

| Paramètre        | Description                                      |
|-----------------|--------------------------------------------------|
| `port`          | Port d'écoute du panel web                       |
| `admin_user`    | Username du super admin initial                  |
| `admin_password`| Mot de passe du super admin initial              |
| `jwt_secret`    | Clé secrète JWT (générée automatiquement)        |
| `scripts_dir`   | Dossier des scripts KATASHIE (`/usr/local/sbin`)    |
| `db_dir`        | Dossier de la base de données SQLite             |

---

## 📋 Menu 18 — KATASHIE VPN Web

Accès depuis le menu principal (`menu` → option `18`) :

| Option | Description |
|--------|-------------|
| **1** | Modifier identifiants admin (username/password) |
| **2** | Manager Admin — créer, modifier, suspendre, promouvoir |
| **3** | Manager Client — créer, renouveler, suspendre, supprimer |
| **4** | Manager Plans/Produits — créer et gérer les offres |
| **5** | Logs & Audit — historique des actions |
| **6** | Statut & Contrôle du service (démarrer/arrêter/redémarrer) |
| **7** | Mettre à jour KATASHIE VPN Web |
| **8** | Désinstaller KATASHIE VPN Web |
| **0** | Retour |

---

## 🔌 Protocoles supportés

| Protocole   | Description                         | Mécanisme               |
|-------------|-------------------------------------|-------------------------|
| `ssh`       | SSH over WebSocket (Dropbear/OpenSSH)| `useradd` + `chage`    |
| `slowdns`   | SlowDNS (partage compte SSH)        | `useradd` + creds SlowDNS|
| `udpcustom` | UDP Custom                          | `useradd` + lien UDP   |
| `vmess`     | VMess Xray                          | Modification xray config|
| `vless`     | VLESS Xray                          | Modification xray config|
| `trojan`    | Trojan Xray                         | Modification xray config|
| `zipvpn`    | ZipVPN                              | `/etc/zivpn/users.db`  |

---

## 🏗️ Architecture

```
katashie-web/
├── server/
│   ├── index.ts          # Serveur Express principal
│   ├── db.ts             # SQLite (better-sqlite3) + schéma
│   ├── scripts.ts        # Ponts vers les scripts shell
│   ├── middleware/
│   │   └── auth.ts       # JWT + RBAC (super_admin / admin)
│   └── routes/
│       ├── auth.ts       # /api/auth/*
│       ├── admins.ts     # /api/admins/*
│       ├── clients.ts    # /api/clients/*
│       ├── plans.ts      # /api/plans/*
│       └── logs.ts       # /api/logs/*
├── public/
│   └── index.html        # SPA frontend (vanilla JS)
├── package.json
├── tsconfig.json
├── install.sh            # Script d'installation
├── katashie-web.service     # Unité systemd
└── README.md
```

---

## 🔐 Sécurité

- Mots de passe hashés avec **bcrypt** (coût 12)
- Sessions **JWT** avec expiration 24h
- **RBAC** : `super_admin` (accès total) vs `admin` (gestion clients/plans)
- Permissions fichier config : `chmod 600`
- Validation stricte des entrées côté API

---

## 🛠️ Gestion du service

```bash
systemctl status katashie-web      # Statut
systemctl restart katashie-web     # Redémarrer
systemctl stop katashie-web        # Arrêter
journalctl -u katashie-web -f      # Logs en temps réel
```

---

## 🗄️ Base de données

**SQLite** → `/etc/katashie-vpn-web/katashie.db`

Tables : `admins`, `clients`, `plans`, `audit_logs`, `sessions`

---

## ❌ Désinstallation

```bash
menu → [18] → [8] Désinstaller KATASHIE VPN Web
```
Ou manuellement :
```bash
systemctl stop katashie-web
systemctl disable katashie-web
rm -rf /opt/katashie-vpn-web
rm -rf /etc/katashie-vpn-web  # Si vous voulez supprimer les données
rm /etc/systemd/system/katashie-web.service
systemctl daemon-reload
```

---

## 📡 API Reference

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/login` | Connexion |
| POST | `/api/auth/logout` | Déconnexion |
| GET | `/api/auth/me` | Info session courante |
| POST | `/api/auth/change-password` | Changer identifiants |
| GET | `/api/admins` | Lister admins (super_admin) |
| POST | `/api/admins` | Créer admin |
| PUT | `/api/admins/:id` | Modifier admin |
| POST | `/api/admins/:id/suspend` | Suspendre admin |
| POST | `/api/admins/:id/promote` | Promouvoir en super_admin |
| DELETE | `/api/admins/:id` | Supprimer admin |
| GET | `/api/clients` | Lister clients |
| POST | `/api/clients` | Créer client + compte système |
| POST | `/api/clients/:id/renew` | Renouveler |
| POST | `/api/clients/:id/suspend` | Suspendre |
| DELETE | `/api/clients/:id` | Supprimer |
| GET | `/api/plans` | Lister plans |
| POST | `/api/plans` | Créer plan |
| PUT | `/api/plans/:id` | Modifier plan |
| DELETE | `/api/plans/:id` | Supprimer plan |
| GET | `/api/logs` | Logs d'audit |
| GET | `/api/logs/stats` | Statistiques tableau de bord |
| GET | `/api/health` | Health check |
