/**
 * Campay Mobile Money Integration
 * Orange Money & MTN MoMo — Cameroun
 * Docs: https://www.campay.net/en/documentation/
 */
import { Router, Request, Response } from 'express';
import { getDb } from '../db';
import { requireAuth } from '../middleware/auth';
import { v4 as uuidv4 } from 'uuid';
import crypto from 'crypto';

const router = Router();

const CAMPAY_BASE = 'https://www.campay.net/api';
const CAMPAY_APP_USERNAME = process.env.CAMPAY_APP_USERNAME || '';
const CAMPAY_APP_PASSWORD = process.env.CAMPAY_APP_PASSWORD || '';

function ensurePaymentTables() {
  const db = getDb();
  db.prepare(`
    CREATE TABLE IF NOT EXISTS payments (
      id TEXT PRIMARY KEY,
      reference TEXT UNIQUE,
      plan_id TEXT,
      phone TEXT NOT NULL,
      amount REAL NOT NULL,
      currency TEXT NOT NULL DEFAULT 'XAF',
      operator TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      campay_ref TEXT,
      client_id TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  `).run();
}

async function campayToken(): Promise<string> {
  const resp = await fetch(`${CAMPAY_BASE}/token/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: CAMPAY_APP_USERNAME, password: CAMPAY_APP_PASSWORD })
  });
  const data = await resp.json() as any;
  if (!data.token) throw new Error('Campay auth failed: ' + JSON.stringify(data));
  return data.token;
}

// Initiate a Mobile Money payment
router.post('/initiate', async (req: Request, res: Response) => {
  ensurePaymentTables();
  const { phone, amount, plan_id, description } = req.body;
  if (!phone || !amount || !plan_id) {
    return res.status(400).json({ error: 'phone, amount, and plan_id are required' });
  }

  const db = getDb();
  const plan = db.prepare('SELECT * FROM plans WHERE id = ?').get(plan_id) as any;
  if (!plan) return res.status(404).json({ error: 'Plan not found' });

  try {
    const token = await campayToken();
    const reference = uuidv4();
    const externalRef = `KATASHIE-${reference.slice(0, 8).toUpperCase()}`;

    const campayResp = await fetch(`${CAMPAY_BASE}/collect/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Token ${token}` },
      body: JSON.stringify({
        amount: String(amount),
        currency: 'XAF',
        from: phone,
        description: description || `KATASHIE VPN — ${plan.name}`,
        external_reference: externalRef,
        redirect_url: process.env.CAMPAY_REDIRECT_URL || ''
      })
    });

    const campayData = await campayResp.json() as any;

    const paymentId = uuidv4();
    db.prepare(`
      INSERT INTO payments (id, reference, plan_id, phone, amount, currency, status, campay_ref, created_at)
      VALUES (?, ?, ?, ?, ?, 'XAF', 'pending', ?, datetime('now'))
    `).run(paymentId, externalRef, plan_id, phone, amount, campayData.reference || null);

    res.json({
      payment_id: paymentId,
      reference: externalRef,
      campay_reference: campayData.reference,
      ussd_code: campayData.ussd_code,
      operator: campayData.operator,
      status: 'pending'
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message || 'Payment initiation failed' });
  }
});

// Check payment status
router.get('/status/:reference', async (req: Request, res: Response) => {
  ensurePaymentTables();
  const db = getDb();
  const payment = db.prepare('SELECT * FROM payments WHERE reference = ? OR campay_ref = ?')
    .get(req.params.reference, req.params.reference) as any;
  if (!payment) return res.status(404).json({ error: 'Payment not found' });

  if (payment.status === 'successful' || payment.status === 'failed') {
    return res.json({ status: payment.status, client_id: payment.client_id });
  }

  try {
    const token = await campayToken();
    const campayResp = await fetch(`${CAMPAY_BASE}/transaction/${payment.campay_ref}/`, {
      headers: { Authorization: `Token ${token}` }
    });
    const data = await campayResp.json() as any;

    if (data.status === 'SUCCESSFUL') {
      db.prepare("UPDATE payments SET status = 'successful', updated_at = datetime('now') WHERE id = ?").run(payment.id);
      // Auto-create client account after successful payment
      await autoCreateAccount(db, payment);
      return res.json({ status: 'successful', client_id: payment.client_id });
    } else if (data.status === 'FAILED') {
      db.prepare("UPDATE payments SET status = 'failed', updated_at = datetime('now') WHERE id = ?").run(payment.id);
    }

    res.json({ status: data.status?.toLowerCase() || 'pending' });
  } catch (err: any) {
    res.json({ status: payment.status });
  }
});

// Campay webhook
router.post('/webhook', (req: Request, res: Response) => {
  ensurePaymentTables();
  const db = getDb();
  const { reference, status } = req.body;
  if (!reference) return res.sendStatus(400);

  const payment = db.prepare('SELECT * FROM payments WHERE campay_ref = ?').get(reference) as any;
  if (!payment) return res.sendStatus(404);

  if (status === 'SUCCESSFUL' && payment.status !== 'successful') {
    db.prepare("UPDATE payments SET status = 'successful', updated_at = datetime('now') WHERE campay_ref = ?").run(reference);
    autoCreateAccount(db, payment).catch(console.error);
  } else if (status === 'FAILED') {
    db.prepare("UPDATE payments SET status = 'failed', updated_at = datetime('now') WHERE campay_ref = ?").run(reference);
  }

  res.sendStatus(200);
});

// List payments (admin only)
router.get('/', requireAuth, (req: Request, res: Response) => {
  ensurePaymentTables();
  const db = getDb();
  const admin = (req as any).admin;
  if (admin.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
  const payments = db.prepare('SELECT id, reference, plan_id, phone, amount, currency, status, created_at FROM payments ORDER BY created_at DESC LIMIT 500').all();
  res.json(payments);
});

async function autoCreateAccount(db: any, payment: any) {
  const plan = db.prepare('SELECT * FROM plans WHERE id = ?').get(payment.plan_id) as any;
  if (!plan) return;

  const username = `vpn_${payment.phone.replace(/[^0-9]/g, '').slice(-8)}_${Date.now().toString(36)}`;
  const clientId = uuidv4();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + (plan.duration_days || 30));

  db.prepare(`
    INSERT INTO clients (id, username, protocol, status, expires_at, data_limit, created_at)
    VALUES (?, ?, ?, 'active', ?, ?, datetime('now'))
  `).run(clientId, username, plan.protocol || 'ssh', expiresAt.toISOString().slice(0, 10), plan.data_limit || null);

  db.prepare("UPDATE payments SET client_id = ?, updated_at = datetime('now') WHERE id = ?").run(clientId, payment.id);
}

export default router;
