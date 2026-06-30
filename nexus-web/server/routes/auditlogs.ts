import { Router, Request, Response } from 'express';
import { getDb } from '../db';
import { requireAuth, requireAdmin } from '../middleware/auth';

const router = Router();

// GET /api/audit-logs?page=1&limit=50&username=&action=&status=
router.get('/', requireAuth, requireAdmin, (req: Request, res: Response) => {
  const db = getDb();
  const page = Math.max(1, parseInt(req.query.page as string) || 1);
  const limit = Math.min(200, parseInt(req.query.limit as string) || 50);
  const offset = (page - 1) * limit;

  const filters: string[] = [];
  const params: any[] = [];

  if (req.query.username) {
    filters.push('admin_username LIKE ?');
    params.push(`%${req.query.username}%`);
  }
  if (req.query.action) {
    filters.push('action LIKE ?');
    params.push(`%${req.query.action}%`);
  }
  if (req.query.status) {
    filters.push('status = ?');
    params.push(req.query.status);
  }

  const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';

  const total = (db.prepare(`SELECT COUNT(*) as n FROM audit_logs ${where}`).get(...params) as any)?.n || 0;
  const logs = db.prepare(`SELECT * FROM audit_logs ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`).all(...params, limit, offset);

  res.json({ logs, total, page, pages: Math.ceil(total / limit) });
});

// DELETE old audit logs (admin cleanup)
router.delete('/cleanup', requireAuth, requireAdmin, (req: Request, res: Response) => {
  const db = getDb();
  const days = parseInt(req.query.days as string) || 90;
  const result = db.prepare(`DELETE FROM audit_logs WHERE created_at < datetime('now', '-${days} days')`).run();
  res.json({ deleted: result.changes });
});

export default router;
