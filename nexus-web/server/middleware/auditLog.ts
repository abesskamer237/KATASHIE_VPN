import { Request, Response, NextFunction } from 'express';
import { getDb } from '../db';

export function auditLog(action: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    const originalJson = res.json.bind(res);
    res.json = (body: unknown) => {
      try {
        const db = getDb();
        const admin = (req as any).admin;
        const statusCode = res.statusCode;
        const success = statusCode >= 200 && statusCode < 300;
        db.prepare(`
          INSERT INTO audit_logs (admin_id, admin_username, admin_role, action, target, ip, status, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
        `).run(
          admin?.id || null,
          admin?.username || 'anonymous',
          admin?.role || 'unknown',
          action,
          JSON.stringify({ method: req.method, path: req.path, params: req.params, body: sanitizeBody(req.body) }),
          req.ip || req.socket?.remoteAddress || 'unknown',
          success ? 'success' : 'failure'
        );
      } catch (_) {}
      return originalJson(body);
    };
    next();
  };
}

function sanitizeBody(body: any): any {
  if (!body || typeof body !== 'object') return body;
  const safe = { ...body };
  for (const key of ['password', 'token', 'secret', 'jwt']) {
    if (key in safe) safe[key] = '***';
  }
  return safe;
}

export function ensureAuditTable(): void {
  const db = getDb();
  db.prepare(`
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      admin_id TEXT,
      admin_username TEXT NOT NULL,
      admin_role TEXT NOT NULL,
      action TEXT NOT NULL,
      target TEXT,
      ip TEXT,
      status TEXT NOT NULL DEFAULT 'success',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  `).run();
  db.prepare(`CREATE INDEX IF NOT EXISTS idx_audit_admin ON audit_logs(admin_username)`).run();
  db.prepare(`CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at)`).run();
}
