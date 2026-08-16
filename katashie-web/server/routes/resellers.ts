import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { getDb, logAction } from '../db';
import { requireAuth, requireSuperAdmin, AuthRequest } from '../middleware/auth';

const router = Router();
const ALLOWED_PROTOCOLS = new Set(['ssh', 'vmess', 'vless', 'trojan', 'socks', 'zipvpn', 'slowdns', 'udpcustom']);

function normalizeProtocol(protocol: string): string {
  const p = String(protocol || '').toLowerCase().trim();
  if (p === 'udp-custom') return 'udpcustom';
  if (p === 'zivpn') return 'zipvpn';
  return p;
}

// GET /api/resellers — list all resellers (admin or super_admin)
router.get('/', requireAuth, (req: AuthRequest, res: Response): void => {
  const admin = req.admin!;
  if (admin.role !== 'admin' && admin.role !== 'super_admin') {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const db = getDb();
  const resellers = db.prepare(
    `SELECT id, username, role, status, created_at, updated_at,
            bouquet, expiry_date, suspended_at
     FROM admins WHERE role = 'reseller'
     ORDER BY created_at DESC`
  ).all();

  res.json(resellers);
});

// POST /api/resellers — create a reseller (admin or super_admin)
router.post('/', requireAuth, async (req: AuthRequest, res: Response): Promise<void> => {
  const admin = req.admin!;
  if (admin.role !== 'admin' && admin.role !== 'super_admin') {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const { username, password, duration_days, bouquet } = req.body as {
    username?: string;
    password?: string;
    duration_days?: number;
    bouquet?: Array<{ protocolId: string; maxAccounts: number }>;
  };

  if (!username || !password) {
    res.status(400).json({ error: 'username and password required' });
    return;
  }

  if (password.length < 6) {
    res.status(400).json({ error: 'Password must be at least 6 characters' });
    return;
  }

  const days = Number.isInteger(duration_days) && (duration_days as number) > 0 ? (duration_days as number) : 30;
  if (days < 1 || days > 3650) {
    res.status(400).json({ error: 'duration_days must be between 1 and 3650' });
    return;
  }
  const db = getDb();
  const expiryDate = (db.prepare("SELECT datetime('now', ?) as d").get(`+${days} days`) as { d: string }).d;

  const normalizedBouquet = Array.isArray(bouquet) ? bouquet : [];
  const seen = new Set<string>();
  for (const b of normalizedBouquet) {
    const proto = normalizeProtocol(String(b?.protocolId || ''));
    const maxAccounts = Number(b?.maxAccounts || 0);
    if (!ALLOWED_PROTOCOLS.has(proto)) {
      res.status(400).json({ error: `Invalid protocol in bouquet: ${proto}` });
      return;
    }
    if (!Number.isInteger(maxAccounts) || maxAccounts < 1 || maxAccounts > 100000) {
      res.status(400).json({ error: `Invalid maxAccounts for protocol '${proto}'` });
      return;
    }
    if (seen.has(proto)) {
      res.status(400).json({ error: `Duplicate protocol in bouquet: ${proto}` });
      return;
    }
    seen.add(proto);
  }

  const exists = db.prepare('SELECT id FROM admins WHERE username = ?').get(username);
  if (exists) {
    res.status(409).json({ error: 'Username already exists' });
    return;
  }

  const id = uuidv4();
  const hash = await bcrypt.hash(password, 12);
  const bouquetJson = JSON.stringify(
    normalizedBouquet.map((b) => ({
      protocolId: normalizeProtocol(String(b.protocolId)),
      maxAccounts: Number(b.maxAccounts),
    }))
  );

  db.prepare(
    `INSERT INTO admins (id, username, password_hash, role, status, bouquet, expiry_date)
     VALUES (?, ?, ?, 'reseller', 'active', ?, ?)`
  ).run(id, username, hash, bouquetJson, expiryDate);

  logAction(
    admin.id, admin.username, 'CREATE_RESELLER', 'reseller', id,
    { username, duration_days: days }, req.ip || null
  );

  res.status(201).json({
    id, username, role: 'reseller', status: 'active',
    expiry_date: expiryDate,
    bouquet: bouquetJson,
  });
});

// POST /api/resellers/:id/suspend
router.post('/:id/suspend', requireAuth, (req: AuthRequest, res: Response): void => {
  const admin = req.admin!;
  if (admin.role !== 'admin' && admin.role !== 'super_admin') {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const db = getDb();
  const target = db.prepare("SELECT id FROM admins WHERE id = ? AND role = 'reseller'").get(req.params.id);
  if (!target) {
    res.status(404).json({ error: 'Reseller not found' });
    return;
  }

  db.prepare("UPDATE admins SET status = 'suspended', updated_at = datetime('now') WHERE id = ?").run(req.params.id);
  logAction(admin.id, admin.username, 'SUSPEND_RESELLER', 'reseller', req.params.id, {}, req.ip || null);
  res.json({ message: 'Reseller suspended' });
});

// POST /api/resellers/:id/activate
router.post('/:id/activate', requireAuth, (req: AuthRequest, res: Response): void => {
  const admin = req.admin!;
  if (admin.role !== 'admin' && admin.role !== 'super_admin') {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const db = getDb();
  const target = db.prepare("SELECT id FROM admins WHERE id = ? AND role = 'reseller'").get(req.params.id);
  if (!target) {
    res.status(404).json({ error: 'Reseller not found' });
    return;
  }

  db.prepare("UPDATE admins SET status = 'active', suspended_at = NULL, updated_at = datetime('now') WHERE id = ?").run(req.params.id);
  logAction(admin.id, admin.username, 'ACTIVATE_RESELLER', 'reseller', req.params.id, {}, req.ip || null);
  res.json({ message: 'Reseller activated' });
});

// PUT /api/resellers/:id — update reseller bouquet and/or expiry (admin or super_admin)
router.put('/:id', requireAuth, async (req: AuthRequest, res: Response): Promise<void> => {
  const admin = req.admin!;
  if (admin.role !== 'admin' && admin.role !== 'super_admin') {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const { bouquet, duration_days, password } = req.body as {
    bouquet?: Array<{ protocolId: string; maxAccounts: number }>;
    duration_days?: number;
    password?: string;
  };

  const db = getDb();
  const target = db.prepare(
    "SELECT id, username FROM admins WHERE id = ? AND role = 'reseller'"
  ).get(req.params.id) as { id: string; username: string } | undefined;

  if (!target) {
    res.status(404).json({ error: 'Reseller not found' });
    return;
  }

  const updates: string[] = [];
  const params: unknown[] = [];

  if (Array.isArray(bouquet)) {
    const seen = new Set<string>();
    const normalized = bouquet.map((b) => {
      const proto = normalizeProtocol(String(b?.protocolId || ''));
      const maxAccounts = Number(b?.maxAccounts || 0);
      if (!ALLOWED_PROTOCOLS.has(proto)) throw new Error(`Invalid protocol: ${proto}`);
      if (!Number.isInteger(maxAccounts) || maxAccounts < 1 || maxAccounts > 100000) throw new Error(`Invalid maxAccounts for ${proto}`);
      if (seen.has(proto)) throw new Error(`Duplicate protocol: ${proto}`);
      seen.add(proto);
      return { protocolId: proto, maxAccounts };
    });
    updates.push('bouquet = ?');
    params.push(JSON.stringify(normalized));
  }

  if (duration_days !== undefined) {
    const days = Number(duration_days);
    if (!Number.isInteger(days) || days < 1 || days > 3650) {
      res.status(400).json({ error: 'duration_days must be between 1 and 3650' });
      return;
    }
    const newExpiry = (db.prepare("SELECT datetime('now', ?) as d").get(`+${days} days`) as { d: string }).d;
    // When an admin explicitly sets a new expiry, the reseller is intentionally re-authorized
    // (clears any prior suspension from auto-expiry and resets suspended_at).
    updates.push('expiry_date = ?', 'suspended_at = NULL', "status = 'active'");
    params.push(newExpiry);
  }

  if (password !== undefined) {
    if (password.length < 6) {
      res.status(400).json({ error: 'Password must be at least 6 characters' });
      return;
    }
    updates.push('password_hash = ?');
    params.push(await bcrypt.hash(password, 12));
  }

  if (updates.length === 0) {
    res.status(400).json({ error: 'No fields to update' });
    return;
  }

  updates.push("updated_at = datetime('now')");
  params.push(req.params.id);

  try {
    db.prepare(`UPDATE admins SET ${updates.join(', ')} WHERE id = ?`).run(...params);
  } catch (e: any) {
    res.status(400).json({ error: e.message || 'Update failed' });
    return;
  }

  logAction(admin.id, admin.username, 'UPDATE_RESELLER', 'reseller', req.params.id, {}, req.ip || null);

  const updated = db.prepare(
    'SELECT id, username, role, status, bouquet, expiry_date FROM admins WHERE id = ?'
  ).get(req.params.id);
  res.json(updated);
});

// DELETE /api/resellers/:id
router.delete('/:id', requireAuth, (req: AuthRequest, res: Response): void => {
  const admin = req.admin!;
  if (admin.role !== 'admin' && admin.role !== 'super_admin') {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const db = getDb();
  const target = db.prepare("SELECT id FROM admins WHERE id = ? AND role = 'reseller'").get(req.params.id);
  if (!target) {
    res.status(404).json({ error: 'Reseller not found' });
    return;
  }

  db.prepare('DELETE FROM sessions WHERE admin_id = ?').run(req.params.id);
  db.prepare('DELETE FROM admins WHERE id = ?').run(req.params.id);

  logAction(admin.id, admin.username, 'DELETE_RESELLER', 'reseller', req.params.id, {}, req.ip || null);
  res.json({ message: 'Reseller deleted' });
});

export default router;
