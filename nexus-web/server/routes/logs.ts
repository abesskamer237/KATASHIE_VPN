import { Router, Response } from 'express';
import { getDb } from '../db';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

// GET /api/logs
router.get('/', requireAuth, (req: AuthRequest, res: Response): void => {
  const db = getDb();
  const limit = Math.min(parseInt(String(req.query['limit'] || '100'), 10), 500);
  const offset = parseInt(String(req.query['offset'] || '0'), 10);
  const action = req.query['action'] as string | undefined;
  const targetType = req.query['target_type'] as string | undefined;

  let query = 'SELECT * FROM audit_logs';
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (action) {
    conditions.push('action LIKE ?');
    params.push(`%${action}%`);
  }
  if (targetType) {
    conditions.push('target_type = ?');
    params.push(targetType);
  }

  if (conditions.length > 0) {
    query += ' WHERE ' + conditions.join(' AND ');
  }

  query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
  params.push(limit, offset);

  const logs = db.prepare(query).all(...params) as Array<Record<string, unknown>>;
  const parsed = logs.map(l => {
    try { l['details'] = JSON.parse(l['details'] as string); } catch {}
    return l;
  });

  const total = (db.prepare('SELECT COUNT(*) as cnt FROM audit_logs').get() as { cnt: number }).cnt;

  res.json({ total, limit, offset, logs: parsed });
});

// GET /api/logs/stats — summary statistics
router.get('/stats', requireAuth, (_req: AuthRequest, res: Response): void => {
  const db = getDb();

  const totalClients = (db.prepare("SELECT COUNT(*) as cnt FROM clients").get() as { cnt: number }).cnt;
  const activeClients = (db.prepare("SELECT COUNT(*) as cnt FROM clients WHERE status = 'active'").get() as { cnt: number }).cnt;
  const expiredClients = (db.prepare("SELECT COUNT(*) as cnt FROM clients WHERE expires_at < date('now')").get() as { cnt: number }).cnt;
  const totalAdmins = (db.prepare("SELECT COUNT(*) as cnt FROM admins WHERE role IN ('admin', 'super_admin')").get() as { cnt: number }).cnt;
  const totalResellers = (db.prepare("SELECT COUNT(*) as cnt FROM admins WHERE role = 'reseller'").get() as { cnt: number }).cnt;
  const activeResellers = (db.prepare("SELECT COUNT(*) as cnt FROM admins WHERE role = 'reseller' AND status = 'active'").get() as { cnt: number }).cnt;
  const suspendedResellers = (db.prepare("SELECT COUNT(*) as cnt FROM admins WHERE role = 'reseller' AND status = 'suspended'").get() as { cnt: number }).cnt;
  const totalPlans = (db.prepare("SELECT COUNT(*) as cnt FROM plans").get() as { cnt: number }).cnt;
  const recentActions = (db.prepare(
    "SELECT action, COUNT(*) as cnt FROM audit_logs WHERE created_at > datetime('now', '-7 days') GROUP BY action ORDER BY cnt DESC LIMIT 10"
  ).all()) as Array<{ action: string; cnt: number }>;

  const protocolStats = (db.prepare(
    "SELECT protocol, COUNT(*) as cnt FROM clients GROUP BY protocol ORDER BY cnt DESC"
  ).all()) as Array<{ protocol: string; cnt: number }>;

  res.json({
    clients: { total: totalClients, active: activeClients, expired: expiredClients },
    admins: { total: totalAdmins },
    resellers: { total: totalResellers, active: activeResellers, suspended: suspendedResellers },
    plans: { total: totalPlans },
    recent_actions: recentActions,
    protocol_stats: protocolStats,
  });
});

export default router;
