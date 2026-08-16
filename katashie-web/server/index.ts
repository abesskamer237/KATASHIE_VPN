import express from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import path from 'path';
import fs from 'fs';
import { getDb, seedSuperAdmin } from './db';
import authRouter from './routes/auth';
import adminsRouter from './routes/admins';
import clientsRouter from './routes/clients';
import plansRouter from './routes/plans';
import logsRouter from './routes/logs';
import resellersRouter from './routes/resellers';
import settingsRouter from './routes/settings';
import { suspendSshAccount, deleteSshAccount } from './scripts';

// ─── Load configuration ────────────────────────────────────────────────────────
const CONFIG_FILE = process.env.KATASHIE_CONFIG || '/etc/katashie-vpn-web/config.json';
let config: {
  port?: number;
  admin_user?: string;
  admin_password?: string;
  jwt_secret?: string;
} = {};

if (fs.existsSync(CONFIG_FILE)) {
  try {
    config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch (e) {
    console.error('[CONFIG] Failed to parse config file:', e);
  }
}

// Override from config file (env vars take precedence)
if (config.jwt_secret && !process.env.KATASHIE_JWT_SECRET) {
  process.env.KATASHIE_JWT_SECRET = config.jwt_secret;
}

const PORT_CANDIDATES = [2087, 2096, 8787, 3001, 9090];
// Prefer explicitly configured port; fall back to candidate list
const configuredPort = config.port ?? (
  process.env.KATASHIE_PORT ? parseInt(process.env.KATASHIE_PORT, 10) : 0
);

// ─── Bootstrap super admin ────────────────────────────────────────────────────
const adminUser = config.admin_user || process.env.KATASHIE_ADMIN_USER || 'admin';
const adminPass = config.admin_password || process.env.KATASHIE_ADMIN_PASS || 'admin123';

// Initialize DB and seed super admin
getDb();
seedSuperAdmin(adminUser, adminPass);

// ─── Global error handlers — ensure Node.js exits on fatal errors ─────────────
// systemd Restart=always will relaunch the process automatically.
process.on('uncaughtException', (err: Error) => {
  console.error('[FATAL] Uncaught exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason: unknown) => {
  console.error('[FATAL] Unhandled promise rejection:', reason);
  process.exit(1);
});

// ─── Expiry scheduler ─────────────────────────────────────────────────────────
// Uses server-side SQLite time (date('now') / datetime('now')) exclusively,
// so client date/time manipulation has no effect on expiry enforcement.
const SSH_PROTOCOLS = new Set(['ssh', 'slowdns', 'udpcustom']);

function runExpiryScheduler(): void {
  try {
    const db = getDb();

    // 1. Suspend expired active client accounts (server time)
    const expiredClients = db.prepare(
      "SELECT id, username, protocol FROM clients WHERE status = 'active' AND expires_at < date('now')"
    ).all() as { id: string; username: string; protocol: string }[];

    for (const client of expiredClients) {
      if (SSH_PROTOCOLS.has(client.protocol)) {
        try { suspendSshAccount(client.username); } catch (e) {
          console.warn(`[SCHEDULER] Could not suspend SSH account '${client.username}':`, e);
        }
      }
      db.prepare(
        "UPDATE clients SET status = 'suspended', updated_at = datetime('now') WHERE id = ?"
      ).run(client.id);
      console.log(`[SCHEDULER] Client '${client.username}' (${client.protocol}) expired — suspended`);
    }

    // 2. Suspend active resellers whose expiry_date has passed (server time)
    const expiredResellers = db.prepare(
      "SELECT id, username FROM admins WHERE role = 'reseller' AND status = 'active' AND expiry_date IS NOT NULL AND expiry_date < date('now')"
    ).all() as { id: string; username: string }[];

    for (const reseller of expiredResellers) {
      // Mark reseller as suspended and record suspension timestamp
      db.prepare(
        "UPDATE admins SET status = 'suspended', suspended_at = datetime('now'), updated_at = datetime('now') WHERE id = ?"
      ).run(reseller.id);

      // Invalidate all active sessions for this reseller
      db.prepare('DELETE FROM sessions WHERE admin_id = ?').run(reseller.id);

      // Suspend all active clients created by this reseller
      const clients = db.prepare(
        "SELECT id, username, protocol FROM clients WHERE created_by = ? AND status = 'active'"
      ).all(reseller.id) as { id: string; username: string; protocol: string }[];

      for (const client of clients) {
        if (SSH_PROTOCOLS.has(client.protocol)) {
          try { suspendSshAccount(client.username); } catch {}
        }
        db.prepare(
          "UPDATE clients SET status = 'suspended', updated_at = datetime('now') WHERE id = ?"
        ).run(client.id);
      }

      console.log(`[SCHEDULER] Reseller '${reseller.username}' expired — suspended along with ${clients.length} client(s)`);
    }

    // 3. Delete resellers that have been suspended for more than 24 hours
    const toDelete = db.prepare(
      "SELECT id, username FROM admins WHERE role = 'reseller' AND status = 'suspended' AND suspended_at IS NOT NULL AND suspended_at <= datetime('now', '-24 hours')"
    ).all() as { id: string; username: string }[];

    for (const reseller of toDelete) {
      const clients = db.prepare(
        'SELECT id, username, protocol FROM clients WHERE created_by = ?'
      ).all(reseller.id) as { id: string; username: string; protocol: string }[];

      for (const client of clients) {
        if (SSH_PROTOCOLS.has(client.protocol)) {
          try { deleteSshAccount(client.username); } catch {}
        }
      }

      db.prepare('DELETE FROM clients WHERE created_by = ?').run(reseller.id);
      db.prepare('DELETE FROM sessions WHERE admin_id = ?').run(reseller.id);
      db.prepare('DELETE FROM admins WHERE id = ?').run(reseller.id);

      console.log(`[SCHEDULER] Reseller '${reseller.username}' auto-deleted after 24 h suspension (${clients.length} client(s) removed)`);
    }
  } catch (err) {
    console.error('[SCHEDULER] Error during expiry check:', err);
  }
}

// Run immediately on start, then every 60 seconds
runExpiryScheduler();
setInterval(runExpiryScheduler, 60 * 1000);

// ─── DB watchdog — exit if DB becomes unresponsive so systemd can restart ─────
let _lastDbOk = Date.now();
setInterval(() => {
  try {
    getDb().prepare('SELECT 1').get();
    _lastDbOk = Date.now();
  } catch (err) {
    const staleSec = Math.round((Date.now() - _lastDbOk) / 1000);
    console.error(`[WATCHDOG] DB unresponsive for ${staleSec}s — exiting for auto-restart:`, err);
    process.exit(1);
  }
}, 30 * 1000);

// ─── Express app ──────────────────────────────────────────────────────────────
const app = express();

app.use(cors({
  origin: (origin, callback) => {
    // Allow same-origin requests (no origin header) and localhost for dev
    if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      callback(null, true);
    } else {
      // For production: restrict to same-host access (no external cross-origin)
      callback(null, false);
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static frontend
const PUBLIC_DIR = path.join(__dirname, '..', '..', 'public');
if (fs.existsSync(PUBLIC_DIR)) {
  app.use(express.static(PUBLIC_DIR));
}

// Rate limiting — strict limit on auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,                   // max 20 login attempts per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' }
});

// General API limiter (protects all authenticated endpoints)
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 300,            // generous limit for admin operations
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please slow down.' }
});

// API routes
app.use('/api/auth', authLimiter, authRouter);
app.use('/api/admins', apiLimiter, adminsRouter);
app.use('/api/clients', apiLimiter, clientsRouter);
app.use('/api/plans', apiLimiter, plansRouter);
app.use('/api/logs', apiLimiter, logsRouter);
app.use('/api/resellers', apiLimiter, resellersRouter);
app.use('/api/settings', apiLimiter, settingsRouter);

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', service: 'katashie-vpn-web', version: '1.0.0' });
});

// Server time endpoint — clients must use this to validate their clock
app.get('/api/server-time', apiLimiter, (_req, res) => {
  const db = getDb();
  const row = db.prepare("SELECT strftime('%s', 'now') as unix_ts, datetime('now') as iso").get() as { unix_ts: string; iso: string };
  res.json({ unix: Number(row.unix_ts), iso: row.iso });
});

// SPA fallback — serve index.html for non-API routes
if (fs.existsSync(PUBLIC_DIR)) {
  app.get('*', (_req, res) => {
    const indexPath = path.join(PUBLIC_DIR, 'index.html');
    if (fs.existsSync(indexPath)) {
      res.sendFile(indexPath);
    } else {
      res.status(404).json({ error: 'Frontend not found' });
    }
  });
}

// ─── Start server ─────────────────────────────────────────────────────────────
function tryListen(portList: number[], idx: number): void {
  if (idx >= portList.length) {
    console.error('[ERROR] No available port found. Exiting.');
    process.exit(1);
  }

  const port = portList[idx];
  app.listen(port)
    .on('listening', () => {
      console.log(`[KATASHIE-WEB] Server running on http://0.0.0.0:${port}`);
      console.log(`[KATASHIE-WEB] Admin: ${adminUser}`);

      // Write the actual port to config file so shell scripts can reference it
      const configDir = path.dirname(CONFIG_FILE);
      try {
        fs.mkdirSync(configDir, { recursive: true });
        const existingConfig = fs.existsSync(CONFIG_FILE)
          ? JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'))
          : {};
        existingConfig.port = port;
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(existingConfig, null, 2));
      } catch {}
    })
    .on('error', (err: NodeJS.ErrnoException) => {
      if (err.code === 'EADDRINUSE') {
        console.warn(`[KATASHIE-WEB] Port ${port} in use, trying next...`);
        tryListen(portList, idx + 1);
      } else {
        console.error('[KATASHIE-WEB] Server error:', err);
        process.exit(1);
      }
    });
}

const portList = configuredPort > 0
  ? [configuredPort, ...PORT_CANDIDATES.filter(p => p !== configuredPort)]
  : PORT_CANDIDATES;

tryListen(portList, 0);

export default app;
