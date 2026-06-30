/**
 * Job: Notification Telegram 24h avant expiry
 * Envoyer alertes CPU > 80%
 */
import { getDb } from '../db';
import https from 'https';

let BOT_TOKEN = '';
let ADMIN_CHAT_ID = '';
let lastCpuAlert = 0;

export function initNotifier(token: string, chatId: string) {
  BOT_TOKEN = token;
  ADMIN_CHAT_ID = chatId;
}

async function sendTelegram(chatId: string, message: string): Promise<void> {
  if (!BOT_TOKEN) return;
  const body = JSON.stringify({ chat_id: chatId, text: message, parse_mode: 'HTML' });
  return new Promise((resolve) => {
    const req = https.request({
      hostname: 'api.telegram.org',
      path: `/bot${BOT_TOKEN}/sendMessage`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) }
    }, (res) => { res.resume(); resolve(); });
    req.on('error', () => resolve());
    req.write(body);
    req.end();
  });
}

export async function runExpiryNotifier(): Promise<void> {
  if (!BOT_TOKEN || !ADMIN_CHAT_ID) return;
  try {
    const db = getDb();

    // Clients expiring in exactly 24h (±15 min)
    const expiringSoon = db.prepare(`
      SELECT username, protocol, expires_at FROM clients
      WHERE status = 'active'
        AND expires_at BETWEEN date('now', '+23 hours') AND date('now', '+25 hours')
    `).all() as { username: string; protocol: string; expires_at: string }[];

    for (const client of expiringSoon) {
      const msg = `⚠️ <b>KATASHIE VPN — Expiry Alert</b>\n\nCompte <code>${client.username}</code> (${client.protocol.toUpperCase()}) expire le <b>${client.expires_at}</b>.\n\nRenouvelez via le panneau ou le bot.`;
      await sendTelegram(ADMIN_CHAT_ID, msg);
    }

    // Resellers expiring in 24h
    const resellersSoon = db.prepare(`
      SELECT username, expiry_date FROM admins
      WHERE role = 'reseller' AND status = 'active'
        AND expiry_date BETWEEN date('now', '+23 hours') AND date('now', '+25 hours')
    `).all() as { username: string; expiry_date: string }[];

    for (const reseller of resellersSoon) {
      const msg = `🔔 <b>KATASHIE VPN — Revendeur</b>\n\nLe revendeur <code>${reseller.username}</code> expire le <b>${reseller.expiry_date}</b>.`;
      await sendTelegram(ADMIN_CHAT_ID, msg);
    }
  } catch (err) {
    console.error('[NOTIFY] Expiry notifier error:', err);
  }
}

export async function runCpuAlert(cpuPercent: number): Promise<void> {
  if (!BOT_TOKEN || !ADMIN_CHAT_ID) return;
  const now = Date.now();
  if (cpuPercent < 80 || now - lastCpuAlert < 15 * 60 * 1000) return; // Max 1 alerte/15min
  lastCpuAlert = now;
  const msg = `🚨 <b>KATASHIE VPN — Alerte CPU</b>\n\nCPU à <b>${cpuPercent.toFixed(1)}%</b> — vérifiez le serveur !`;
  await sendTelegram(ADMIN_CHAT_ID, msg);
}
