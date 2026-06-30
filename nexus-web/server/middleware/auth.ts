import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { getDb } from '../db';

// Require a proper JWT secret — generate a random one if not provided (warn in logs)
let JWT_SECRET: string;
if (process.env.NEXUS_JWT_SECRET && process.env.NEXUS_JWT_SECRET.length >= 32) {
  JWT_SECRET = process.env.NEXUS_JWT_SECRET;
} else {
  JWT_SECRET = crypto.randomBytes(48).toString('hex');
  console.warn('[AUTH] NEXUS_JWT_SECRET not set or too short — using ephemeral random secret. All sessions will be invalidated on restart.');
}

export interface AuthRequest extends Request {
  admin?: {
    id: string;
    username: string;
    role: string;
  };
}

export function requireAuth(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { id: string; username: string; role: string };

    const db = getDb();
    const session = db.prepare(
      "SELECT id FROM sessions WHERE token = ? AND expires_at > datetime('now')"
    ).get(token);
    if (!session) {
      res.status(401).json({ error: 'Session expired or invalid' });
      return;
    }

    const admin = db.prepare(
      "SELECT id, username, role, status FROM admins WHERE id = ?"
    ).get(payload.id) as { id: string; username: string; role: string; status: string } | undefined;

    if (!admin || admin.status !== 'active') {
      res.status(401).json({ error: 'Account inactive or not found' });
      return;
    }

    req.admin = { id: admin.id, username: admin.username, role: admin.role };
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

export function requireSuperAdmin(req: AuthRequest, res: Response, next: NextFunction): void {
  requireAuth(req, res, () => {
    if (req.admin?.role !== 'super_admin') {
      res.status(403).json({ error: 'Super admin required' });
      return;
    }
    next();
  });
}

export { JWT_SECRET };
