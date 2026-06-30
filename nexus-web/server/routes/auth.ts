import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { getDb, logAction } from '../db';
import { requireAuth, AuthRequest, JWT_SECRET } from '../middleware/auth';

const router = Router();
const SESSION_HOURS = 24;

// POST /api/auth/login
router.post('/login', async (req: AuthRequest, res: Response): Promise<void> => {
  const { username, password } = req.body as { username?: string; password?: string };
  if (!username || !password) {
    res.status(400).json({ error: 'Username and password required' });
    return;
  }

  const db = getDb();
  const admin = db.prepare(
    'SELECT id, username, password_hash, role, status FROM admins WHERE username = ?'
  ).get(username) as { id: string; username: string; password_hash: string; role: string; status: string } | undefined;

  // Use async bcrypt.compare so the event loop is not blocked during heavy concurrent logins
  const passwordMatch = admin ? await bcrypt.compare(password, admin.password_hash) : false;

  if (!admin || !passwordMatch) {
    res.status(401).json({ error: 'Identifiants invalides' });
    return;
  }

  if (admin.status !== 'active') {
    res.status(403).json({ error: 'Compte suspendu' });
    return;
  }

  // For resellers: also check server-side expiry (date manipulation protection)
  if (admin.role === 'reseller') {
    const expired = db.prepare(
      "SELECT expiry_date IS NOT NULL AND expiry_date < date('now') as is_exp FROM admins WHERE id = ?"
    ).get(admin.id) as { is_exp: number } | undefined;
    if (expired?.is_exp) {
      res.status(403).json({ error: 'Compte revendeur expiré' });
      return;
    }
  }

  const expiresAt = new Date(Date.now() + SESSION_HOURS * 3600 * 1000);
  const token = jwt.sign(
    { id: admin.id, username: admin.username, role: admin.role },
    JWT_SECRET,
    { expiresIn: `${SESSION_HOURS}h` }
  );

  db.prepare(
    'INSERT INTO sessions (id, admin_id, token, expires_at) VALUES (?, ?, ?, ?)'
  ).run(uuidv4(), admin.id, token, expiresAt.toISOString());

  logAction(admin.id, admin.username, 'LOGIN', null, null, {}, req.ip || null);

  res.json({
    token,
    admin: { id: admin.id, username: admin.username, role: admin.role }
  });
});

// POST /api/auth/logout
router.post('/logout', requireAuth, (req: AuthRequest, res: Response): void => {
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    const db = getDb();
    db.prepare('DELETE FROM sessions WHERE token = ?').run(token);
  }
  logAction(req.admin?.id || null, req.admin?.username || null, 'LOGOUT', null, null, {}, req.ip || null);
  res.json({ message: 'Logged out' });
});

// GET /api/auth/me
router.get('/me', requireAuth, (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const admin = db.prepare(
    'SELECT id, username, role, status, bouquet, expiry_date FROM admins WHERE id = ?'
  ).get(req.admin!.id) as {
    id: string; username: string; role: string; status: string;
    bouquet?: string; expiry_date?: string;
  } | undefined;

  if (!admin) {
    res.status(404).json({ error: 'Admin not found' });
    return;
  }

  // For resellers: enforce server-side expiry (in case scheduler hasn't run yet)
  if (admin.role === 'reseller' && admin.expiry_date) {
    const expired = (db.prepare("SELECT expiry_date < date('now') as is_exp FROM admins WHERE id = ?").get(admin.id) as { is_exp: number }).is_exp;
    if (expired) {
      res.status(403).json({ error: 'Compte revendeur expiré' });
      return;
    }
  }

  // Calculate remaining days and remaining seconds from server time
  let remainingDays: number | null = null;
  let remainingSeconds: number | null = null;
  if (admin.expiry_date) {
    const row = db.prepare(
      "SELECT CAST(JULIANDAY(?) - JULIANDAY(date('now')) AS INTEGER) as days, " +
      "CAST((JULIANDAY(? || ' 23:59:59') - JULIANDAY(datetime('now'))) * 86400 AS INTEGER) as secs"
    ).get(admin.expiry_date, admin.expiry_date) as { days: number; secs: number };
    remainingDays = Math.max(0, row.days);
    remainingSeconds = Math.max(0, row.secs);
  }

  let bouquet: unknown = admin.bouquet;
  try {
    const parsed = typeof admin.bouquet === 'string' ? JSON.parse(admin.bouquet) : admin.bouquet;
    if (Array.isArray(parsed)) {
      bouquet = parsed.map((b: any) => {
        const protocolId = String(b?.protocolId || '').toLowerCase();
        const usedRow = db.prepare('SELECT COUNT(*) as c FROM clients WHERE created_by = ? AND protocol = ?')
          .get(admin.id, protocolId) as { c: number };
        return {
          protocolId,
          maxAccounts: Number(b?.maxAccounts || 0),
          usedAccounts: Number(usedRow?.c || 0),
        };
      });
    }
  } catch {}

  res.json({
    admin: {
      id: admin.id,
      username: admin.username,
      role: admin.role,
      status: admin.status,
      bouquet,
      expiry_date: admin.expiry_date,
      remaining_days: remainingDays,
      remaining_seconds: remainingSeconds,
    },
  });
});

// POST /api/auth/change-password
router.post('/change-password', requireAuth, async (req: AuthRequest, res: Response): Promise<void> => {
  const { current_password, new_password, new_username } = req.body as {
    current_password?: string;
    new_password?: string;
    new_username?: string;
  };

  if (!current_password || (!new_password && !new_username)) {
    res.status(400).json({ error: 'current_password and at least one of new_password or new_username required' });
    return;
  }

  const db = getDb();
  const admin = db.prepare(
    'SELECT id, username, password_hash FROM admins WHERE id = ?'
  ).get(req.admin!.id) as { id: string; username: string; password_hash: string } | undefined;

  const passwordMatch = admin ? await bcrypt.compare(current_password, admin.password_hash) : false;
  if (!admin || !passwordMatch) {
    res.status(401).json({ error: 'Current password incorrect' });
    return;
  }

  const updates: string[] = [];
  const params: unknown[] = [];

  if (new_password) {
    if (new_password.length < 6) {
      res.status(400).json({ error: 'New password must be at least 6 characters' });
      return;
    }
    updates.push('password_hash = ?');
    params.push(await bcrypt.hash(new_password, 12));
  }

  if (new_username) {
    const exists = db.prepare('SELECT id FROM admins WHERE username = ? AND id != ?').get(new_username, admin.id);
    if (exists) {
      res.status(409).json({ error: 'Username already taken' });
      return;
    }
    updates.push('username = ?');
    params.push(new_username);
  }

  updates.push("updated_at = datetime('now')");
  params.push(admin.id);

  db.prepare(`UPDATE admins SET ${updates.join(', ')} WHERE id = ?`).run(...params);

  logAction(req.admin!.id, req.admin!.username, 'CHANGE_CREDENTIALS', 'admin', admin.id, {}, req.ip || null);

  res.json({ message: 'Credentials updated successfully' });
});

export default router;
