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
import monitoringRouter from './routes/monitoring';
import serversRouter from './routes/servers';
import exportRouter from './routes/export';
import paymentRouter from './routes/payment';
import qrcodeRouter from './routes/qrcode';
import auditLogsRouter from './routes/auditlogs';
import { suspendSshAccount, deleteSshAccount } from './scripts';
import { ensureAuditTable } from './middleware/auditLog';
import { scheduleDailyBackup } from './jobs/backupCron';
import { initNotifier, runExpiryNotifier, runCpuAlert } from './jobs/notifyExpiry';
import { swaggerSpec } from './swagger';

// ─── Load configuration ────────────────────────────────────────────────────────
const CONFIG_FILE = process.env.KATASHIE_CONFIG || process.env.NEXUS_CONFIG || '/etc/katashie-tunnel-web/config.json';
let config: {
  port?: number;
  admin_user?: string;
  admin_password?: string;
  jwt_secret?: string;
  telegram_bot_token?: string;
  telegram_admin_chat?: string;
} = {};

if (fs.existsSync(CONFIG_FILE)) {
  try {
    config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch (e) {
    console.error('[CONFIG] Failed to parse config file:', e);
  }
}

if (config.jwt_secret && !process.env.NEXUS_JWT_SECRET) {
  process.env.NEXUS_JWT_SECRET = config.jwt_secret;
}

const PORT_CANDIDATES = [2087, 2096, 8787, 3001, 9090];
const configuredPort = config.port ?? (
  process.env.NEXUS_PORT ? parseInt(process.env.NEXUS_PORT, 10) : 0
);

// ─── Bootstrap super admin ────────────────────────────────────────────────────
const adminUser = config.admin_user || process.env.NEXUS_ADMIN_USER || 'admin';
const adminPass = config.admin_password || process.env.NEXUS_ADMIN_PASS || 'admin123';

getDb();
seedSuperAdmin(adminUser, adminPass);

// ─── Ensure extra DB tables ───────────────────────────────────────────────────
ensureAuditTable();

// ─── Init Telegram notifier ───────────────────────────────────────────────────
const tgToken = config.telegram_bot_token || process.env.TELEGRAM_BOT_TOKEN || '';
const tgChat  = config.telegram_admin_chat || process.env.TELEGRAM_ADMIN_CHAT || '';
if (tgToken && tgChat) {
  initNotifier(tgToken, tgChat);
  setInterval(() => runExpiryNotifier().catch(console.error), 60 * 60 * 1000); // every hour
  console.log('[NOTIFY] Telegram notifier enabled');
}

// ─── Schedule daily backup ────────────────────────────────────────────────────
scheduleDailyBackup();

// ─── Global error handlers ────────────────────────────────────────────────────
process.on('uncaughtException', (err: Error) => {
  console.error('[FATAL] Uncaught exception:', err);
  process.exit(1);
});
process.on('unhandledRejection', (reason: unknown) => {
  console.error('[FATAL] Unhandled promise rejection:', reason);
  process.exit(1);
});

// ─── Expiry scheduler ─────────────────────────────────────────────────────────
const SSH_PROTOCOLS = new Set(['ssh', 'slowdns', 'udpcustom']);

function runExpiryScheduler(): void {
  try {
    const db = getDb();
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

    const expiredResellers = db.prepare(
      "SELECT id, username FROM admins WHERE role = 'reseller' AND status = 'active' AND expiry_date IS NOT NULL AND expiry_date < date('now')"
    ).all() as { id: string; username: string }[];

    for (const reseller of expiredResellers) {
      db.prepare(
        "UPDATE admins SET status = 'suspended', suspended_at = datetime('now'), updated_at = datetime('now') WHERE id = ?"
      ).run(reseller.id);
      db.prepare('DELETE FROM sessions WHERE admin_id = ?').run(reseller.id);
      const clients = db.prepare(
        "SELECT id, username, protocol FROM clients WHERE created_by = ? AND status = 'active'"
      ).all(reseller.id) as { id: string; username: string; protocol: string }[];
      for (const client of clients) {
        if (SSH_PROTOCOLS.has(client.protocol)) {
          try { suspendSshAccount(client.username); } catch {}
        }
        db.prepare("UPDATE clients SET status = 'suspended', updated_at = datetime('now') WHERE id = ?").run(client.id);
      }
      console.log(`[SCHEDULER] Reseller '${reseller.username}' expired — suspended (${clients.length} clients)`);
    }

    const toDelete = db.prepare(
      "SELECT id, username FROM admins WHERE role = 'reseller' AND status = 'suspended' AND suspended_at IS NOT NULL AND suspended_at <= datetime('now', '-24 hours')"
    ).all() as { id: string; username: string }[];

    for (const reseller of toDelete) {
      const clients = db.prepare('SELECT id, username, protocol FROM clients WHERE created_by = ?').all(reseller.id) as any[];
      for (const client of clients) {
        if (SSH_PROTOCOLS.has(client.protocol)) { try { deleteSshAccount(client.username); } catch {} }
      }
      db.prepare('DELETE FROM clients WHERE created_by = ?').run(reseller.id);
      db.prepare('DELETE FROM sessions WHERE admin_id = ?').run(reseller.id);
      db.prepare('DELETE FROM admins WHERE id = ?').run(reseller.id);
      console.log(`[SCHEDULER] Reseller '${reseller.username}' auto-deleted (${clients.length} clients removed)`);
    }
  } catch (err) {
    console.error('[SCHEDULER] Error during expiry check:', err);
  }
}

runExpiryScheduler();
setInterval(runExpiryScheduler, 60 * 1000);

// ─── DB watchdog ──────────────────────────────────────────────────────────────
let _lastDbOk = Date.now();
setInterval(() => {
  try {
    getDb().prepare('SELECT 1').get();
    _lastDbOk = Date.now();
  } catch (err) {
    const staleSec = Math.round((Date.now() - _lastDbOk) / 1000);
    console.error(`[WATCHDOG] DB unresponsive for ${staleSec}s — exiting:`, err);
    process.exit(1);
  }
}, 30 * 1000);

// ─── Express app ──────────────────────────────────────────────────────────────
const app = express();

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      callback(null, true);
    } else {
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

// ─── Rate limiters ───────────────────────────────────────────────────────────
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 20,
  standardHeaders: true, legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' }
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000, max: 300,
  standardHeaders: true, legacyHeaders: false,
  message: { error: 'Too many requests, please slow down.' }
});

const paymentLimiter = rateLimit({
  windowMs: 60 * 1000, max: 10,
  standardHeaders: true, legacyHeaders: false,
  message: { error: 'Too many payment requests.' }
});

// ─── Routes ──────────────────────────────────────────────────────────────────
app.use('/api/auth',        authLimiter,    authRouter);
app.use('/api/admins',      apiLimiter,     adminsRouter);
app.use('/api/clients',     apiLimiter,     clientsRouter);
app.use('/api/plans',       apiLimiter,     plansRouter);
app.use('/api/logs',        apiLimiter,     logsRouter);
app.use('/api/resellers',   apiLimiter,     resellersRouter);
app.use('/api/settings',    apiLimiter,     settingsRouter);
app.use('/api/monitoring',  apiLimiter,     monitoringRouter);
app.use('/api/servers',     apiLimiter,     serversRouter);
app.use('/api/export',      apiLimiter,     exportRouter);
app.use('/api/payment',     paymentLimiter, paymentRouter);
app.use('/api/qrcode',      apiLimiter,     qrcodeRouter);
app.use('/api/audit-logs',  apiLimiter,     auditLogsRouter);

// ─── Swagger docs ─────────────────────────────────────────────────────────────
app.get('/api/docs', (_req, res) => {
  res.send(`<!DOCTYPE html><html><head><title>KATASHIE VPN API</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
  </head><body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>SwaggerUIBundle({url:'/api/docs/spec',dom_id:'#swagger-ui',deepLinking:true,presets:[SwaggerUIBundle.presets.apis,SwaggerUIBundle.SwaggerUIStandalonePreset]})</script>
  </body></html>`);
});
app.get('/api/docs/spec', (_req, res) => res.json(swaggerSpec));

// ─── Health & system time ─────────────────────────────────────────────────────
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', service: 'katashie-vpn-web', version: '2.0.0' });
});

app.get('/api/server-time', apiLimiter, (_req, res) => {
  const db = getDb();
  const row = db.prepare("SELECT strftime('%s','now') as unix_ts, datetime('now') as iso").get() as any;
  res.json({ unix: Number(row.unix_ts), iso: row.iso });
});

// SPA fallback
if (fs.existsSync(PUBLIC_DIR)) {
  app.get('*', (_req, res) => {
    const indexPath = path.join(PUBLIC_DIR, 'index.html');
    if (fs.existsSync(indexPath)) res.sendFile(indexPath);
    else res.status(404).json({ error: 'Frontend not found' });
  });
}

// ─── Start server ─────────────────────────────────────────────────────────────
function tryListen(portList: number[], idx: number): void {
  if (idx >= portList.length) { console.error('[ERROR] No available port found. Exiting.'); process.exit(1); }
  const port = portList[idx];
  app.listen(port)
    .on('listening', () => {
      console.log(`[KATASHIE-WEB] Server running on http://0.0.0.0:${port}`);
      console.log(`[KATASHIE-WEB] Swagger docs: http://0.0.0.0:${port}/api/docs`);
      console.log(`[KATASHIE-WEB] Admin: ${adminUser}`);
      const configDir = path.dirname(CONFIG_FILE);
      try {
        fs.mkdirSync(configDir, { recursive: true });
        const existingConfig = fs.existsSync(CONFIG_FILE) ? JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')) : {};
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
