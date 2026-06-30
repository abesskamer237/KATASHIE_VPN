import { Router, Request, Response } from 'express';
import { getDb } from '../db';
import { requireAuth } from '../middleware/auth';

const router = Router();

function toCSV(rows: Record<string, any>[], columns: string[]): string {
  const header = columns.join(',');
  const lines = rows.map(row =>
    columns.map(col => {
      const val = row[col] ?? '';
      const str = String(val).replace(/"/g, '""');
      return str.includes(',') || str.includes('"') || str.includes('\n') ? `"${str}"` : str;
    }).join(',')
  );
  return [header, ...lines].join('\r\n');
}

// Export clients as CSV
router.get('/clients/csv', requireAuth, (req: Request, res: Response) => {
  const db = getDb();
  const admin = (req as any).admin;

  let clients: any[];
  if (admin.role === 'admin') {
    clients = db.prepare('SELECT username, protocol, status, expires_at, data_limit, data_used, created_at FROM clients ORDER BY created_at DESC').all();
  } else {
    clients = db.prepare('SELECT username, protocol, status, expires_at, data_limit, data_used, created_at FROM clients WHERE created_by = ? ORDER BY created_at DESC').all(admin.id);
  }

  const columns = ['username', 'protocol', 'status', 'expires_at', 'data_limit', 'data_used', 'created_at'];
  const csv = toCSV(clients as Record<string, any>[], columns);

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="katashie-clients-${new Date().toISOString().slice(0, 10)}.csv"`);
  res.send('\uFEFF' + csv); // BOM for Excel UTF-8
});

// Export audit logs as CSV (admin only)
router.get('/audit/csv', requireAuth, (req: Request, res: Response) => {
  const db = getDb();
  const admin = (req as any).admin;
  if (admin.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });

  const logs = db.prepare('SELECT admin_username, admin_role, action, ip, status, created_at FROM audit_logs ORDER BY created_at DESC LIMIT 5000').all();
  const columns = ['admin_username', 'admin_role', 'action', 'ip', 'status', 'created_at'];
  const csv = toCSV(logs as Record<string, any>[], columns);

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="katashie-audit-${new Date().toISOString().slice(0, 10)}.csv"`);
  res.send('\uFEFF' + csv);
});

// Stats summary JSON
router.get('/stats/json', requireAuth, (req: Request, res: Response) => {
  const db = getDb();
  const admin = (req as any).admin;

  const base = admin.role === 'admin'
    ? { where: '1=1', params: [] }
    : { where: 'created_by = ?', params: [admin.id] };

  const total = (db.prepare(`SELECT COUNT(*) as n FROM clients WHERE ${base.where}`).get(...base.params) as any)?.n || 0;
  const active = (db.prepare(`SELECT COUNT(*) as n FROM clients WHERE ${base.where} AND status = 'active'`).get(...base.params) as any)?.n || 0;
  const expired = (db.prepare(`SELECT COUNT(*) as n FROM clients WHERE ${base.where} AND status = 'suspended'`).get(...base.params) as any)?.n || 0;
  const byProtocol = db.prepare(`SELECT protocol, COUNT(*) as n FROM clients WHERE ${base.where} GROUP BY protocol`).all(...base.params);

  res.json({ total, active, expired, by_protocol: byProtocol, generated_at: new Date().toISOString() });
});

export default router;
