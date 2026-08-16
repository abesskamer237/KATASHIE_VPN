import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { getDb, logAction } from '../db';
import { requireAuth, requireSuperAdmin, AuthRequest } from '../middleware/auth';

const router = Router();

// GET /api/admins — list all admins (super_admin only)
router.get('/', requireSuperAdmin, (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const admins = db.prepare(
    'SELECT id, username, role, status, created_at, updated_at FROM admins ORDER BY created_at DESC'
  ).all();
  res.json(admins);
});

// POST /api/admins — create admin (super_admin only)
router.post('/', requireSuperAdmin, async (req: AuthRequest, res: Response): Promise<void> => {
  const { username, password, role } = req.body as {
    username?: string;
    password?: string;
    role?: string;
  };

  if (!username || !password) {
    res.status(400).json({ error: 'username and password required' });
    return;
  }

  if (password.length < 6) {
    res.status(400).json({ error: 'Password must be at least 6 characters' });
    return;
  }

  const allowedRoles = ['admin', 'super_admin'];
  const adminRole = allowedRoles.includes(role || '') ? role! : 'admin';

  const db = getDb();
  const exists = db.prepare('SELECT id FROM admins WHERE username = ?').get(username);
  if (exists) {
    res.status(409).json({ error: 'Username already exists' });
    return;
  }

  const id = uuidv4();
  const hash = await bcrypt.hash(password, 12);
  db.prepare(
    'INSERT INTO admins (id, username, password_hash, role, status) VALUES (?, ?, ?, ?, ?)'
  ).run(id, username, hash, adminRole, 'active');

  logAction(req.admin!.id, req.admin!.username, 'CREATE_ADMIN', 'admin', id, { username, role: adminRole }, req.ip || null);

  res.status(201).json({ id, username, role: adminRole, status: 'active' });
});

// GET /api/admins/:id — get single admin
router.get('/:id', requireSuperAdmin, (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const admin = db.prepare(
    'SELECT id, username, role, status, created_at, updated_at FROM admins WHERE id = ?'
  ).get(req.params.id);

  if (!admin) {
    res.status(404).json({ error: 'Admin not found' });
    return;
  }
  res.json(admin);
});

// PUT /api/admins/:id — update admin info
router.put('/:id', requireSuperAdmin, async (req: AuthRequest, res: Response): Promise<void> => {
  const { username, password } = req.body as { username?: string; password?: string };
  const db = getDb();

  const target = db.prepare('SELECT id FROM admins WHERE id = ?').get(req.params.id);
  if (!target) {
    res.status(404).json({ error: 'Admin not found' });
    return;
  }

  const updates: string[] = [];
  const params: unknown[] = [];

  if (username) {
    const conflict = db.prepare('SELECT id FROM admins WHERE username = ? AND id != ?').get(username, req.params.id);
    if (conflict) {
      res.status(409).json({ error: 'Username already taken' });
      return;
    }
    updates.push('username = ?');
    params.push(username);
  }

  if (password) {
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

  db.prepare(`UPDATE admins SET ${updates.join(', ')} WHERE id = ?`).run(...params);

  logAction(req.admin!.id, req.admin!.username, 'UPDATE_ADMIN', 'admin', req.params.id, { username }, req.ip || null);

  res.json({ message: 'Admin updated' });
});

// POST /api/admins/:id/suspend — suspend admin
router.post('/:id/suspend', requireSuperAdmin, (req: AuthRequest, res: Response): void => {
  const db = getDb();

  if (req.params.id === req.admin!.id) {
    res.status(400).json({ error: 'Cannot suspend yourself' });
    return;
  }

  const target = db.prepare('SELECT id, role FROM admins WHERE id = ?').get(req.params.id) as { id: string; role: string } | undefined;
  if (!target) {
    res.status(404).json({ error: 'Admin not found' });
    return;
  }

  db.prepare("UPDATE admins SET status = 'suspended', updated_at = datetime('now') WHERE id = ?").run(req.params.id);

  logAction(req.admin!.id, req.admin!.username, 'SUSPEND_ADMIN', 'admin', req.params.id, {}, req.ip || null);

  res.json({ message: 'Admin suspended' });
});

// POST /api/admins/:id/activate — re-activate admin
router.post('/:id/activate', requireSuperAdmin, (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const target = db.prepare('SELECT id FROM admins WHERE id = ?').get(req.params.id);
  if (!target) {
    res.status(404).json({ error: 'Admin not found' });
    return;
  }

  db.prepare("UPDATE admins SET status = 'active', updated_at = datetime('now') WHERE id = ?").run(req.params.id);

  logAction(req.admin!.id, req.admin!.username, 'ACTIVATE_ADMIN', 'admin', req.params.id, {}, req.ip || null);

  res.json({ message: 'Admin activated' });
});

// POST /api/admins/:id/promote — promote to super_admin
router.post('/:id/promote', requireSuperAdmin, (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const target = db.prepare('SELECT id, role FROM admins WHERE id = ?').get(req.params.id) as { id: string; role: string } | undefined;
  if (!target) {
    res.status(404).json({ error: 'Admin not found' });
    return;
  }

  db.prepare("UPDATE admins SET role = 'super_admin', updated_at = datetime('now') WHERE id = ?").run(req.params.id);

  logAction(req.admin!.id, req.admin!.username, 'PROMOTE_ADMIN', 'admin', req.params.id, {}, req.ip || null);

  res.json({ message: 'Admin promoted to super_admin' });
});

// DELETE /api/admins/:id — delete admin
router.delete('/:id', requireSuperAdmin, (req: AuthRequest, res: Response): void => {
  const db = getDb();

  if (req.params.id === req.admin!.id) {
    res.status(400).json({ error: 'Cannot delete yourself' });
    return;
  }

  const target = db.prepare('SELECT id FROM admins WHERE id = ?').get(req.params.id);
  if (!target) {
    res.status(404).json({ error: 'Admin not found' });
    return;
  }

  db.prepare('DELETE FROM sessions WHERE admin_id = ?').run(req.params.id);
  db.prepare('DELETE FROM admins WHERE id = ?').run(req.params.id);

  logAction(req.admin!.id, req.admin!.username, 'DELETE_ADMIN', 'admin', req.params.id, {}, req.ip || null);

  res.json({ message: 'Admin deleted' });
});

export default router;
