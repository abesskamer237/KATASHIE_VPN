import { Router, Request, Response } from 'express';
import { getDb } from '../db';
import { requireAuth, requireAdmin } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

function ensureServersTable() {
  const db = getDb();
  db.prepare(`
    CREATE TABLE IF NOT EXISTS servers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      host TEXT NOT NULL,
      port INTEGER NOT NULL DEFAULT 22,
      ssh_user TEXT NOT NULL DEFAULT 'root',
      ssh_password TEXT,
      ssh_key TEXT,
      location TEXT,
      status TEXT NOT NULL DEFAULT 'unknown',
      last_check TEXT,
      cpu_usage REAL DEFAULT 0,
      memory_usage REAL DEFAULT 0,
      active_users INTEGER DEFAULT 0,
      created_by TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  `).run();
}

// List all servers
router.get('/', requireAuth, requireAdmin, (_req: Request, res: Response) => {
  ensureServersTable();
  const db = getDb();
  const servers = db.prepare('SELECT id, name, host, port, ssh_user, location, status, last_check, cpu_usage, memory_usage, active_users, created_at FROM servers ORDER BY created_at DESC').all();
  res.json(servers);
});

// Get single server
router.get('/:id', requireAuth, requireAdmin, (req: Request, res: Response) => {
  ensureServersTable();
  const db = getDb();
  const server = db.prepare('SELECT id, name, host, port, ssh_user, location, status, last_check, cpu_usage, memory_usage, active_users, created_at FROM servers WHERE id = ?').get(req.params.id);
  if (!server) return res.status(404).json({ error: 'Server not found' });
  res.json(server);
});

// Add server
router.post('/', requireAuth, requireAdmin, (req: Request, res: Response) => {
  ensureServersTable();
  const { name, host, port = 22, ssh_user = 'root', ssh_password, ssh_key, location } = req.body;
  if (!name || !host) return res.status(400).json({ error: 'name and host are required' });
  const db = getDb();
  const admin = (req as any).admin;
  const id = uuidv4();
  db.prepare(`
    INSERT INTO servers (id, name, host, port, ssh_user, ssh_password, ssh_key, location, created_by)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, name, host, port, ssh_user, ssh_password || null, ssh_key || null, location || null, admin.id);
  res.status(201).json({ id, name, host, port, ssh_user, location, status: 'unknown' });
});

// Update server
router.put('/:id', requireAuth, requireAdmin, (req: Request, res: Response) => {
  ensureServersTable();
  const { name, host, port, ssh_user, ssh_password, ssh_key, location } = req.body;
  const db = getDb();
  db.prepare(`
    UPDATE servers SET name = COALESCE(?, name), host = COALESCE(?, host), port = COALESCE(?, port),
    ssh_user = COALESCE(?, ssh_user), ssh_password = COALESCE(?, ssh_password),
    ssh_key = COALESCE(?, ssh_key), location = COALESCE(?, location), updated_at = datetime('now')
    WHERE id = ?
  `).run(name, host, port, ssh_user, ssh_password, ssh_key, location, req.params.id);
  res.json({ success: true });
});

// Delete server
router.delete('/:id', requireAuth, requireAdmin, (req: Request, res: Response) => {
  ensureServersTable();
  const db = getDb();
  db.prepare('DELETE FROM servers WHERE id = ?').run(req.params.id);
  res.json({ success: true });
});

// Update server status (called by monitoring jobs)
router.post('/:id/status', requireAuth, requireAdmin, (req: Request, res: Response) => {
  ensureServersTable();
  const { status, cpu_usage, memory_usage, active_users } = req.body;
  const db = getDb();
  db.prepare(`
    UPDATE servers SET status = ?, cpu_usage = ?, memory_usage = ?, active_users = ?,
    last_check = datetime('now'), updated_at = datetime('now') WHERE id = ?
  `).run(status || 'unknown', cpu_usage || 0, memory_usage || 0, active_users || 0, req.params.id);
  res.json({ success: true });
});

export default router;
