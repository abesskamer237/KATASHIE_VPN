/**
 * QR Code generation for VPN configs (VLESS, VMESS, SSH)
 * Uses qrcode package to generate base64 PNG
 */
import { Router, Request, Response } from 'express';
import { getDb } from '../db';
import { requireAuth } from '../middleware/auth';
import QRCode from 'qrcode';

const router = Router();

function buildVlessUri(client: any, settings: any): string {
  const host = settings?.server_domain || settings?.server_ip || 'server.example.com';
  const port = settings?.xray_port || 443;
  const uuid = client.uuid || client.username;
  const sni = settings?.server_domain || host;
  return `vless://${uuid}@${host}:${port}?security=tls&sni=${sni}&type=ws&path=/vless#KATASHIE-${client.username}`;
}

function buildVmessUri(client: any, settings: any): string {
  const host = settings?.server_domain || settings?.server_ip || 'server.example.com';
  const port = settings?.xray_port || 443;
  const uuid = client.uuid || client.username;
  const config = {
    v: '2',
    ps: `KATASHIE-${client.username}`,
    add: host,
    port: String(port),
    id: uuid,
    aid: '0',
    net: 'ws',
    type: 'none',
    host: host,
    path: '/vmess',
    tls: 'tls',
    sni: host
  };
  return `vmess://${Buffer.from(JSON.stringify(config)).toString('base64')}`;
}

function buildSshConfig(client: any, settings: any): string {
  const host = settings?.server_domain || settings?.server_ip || 'server.example.com';
  const port = settings?.ssh_port || 22;
  return `Host KATASHIE-${client.username}\n  HostName ${host}\n  User ${client.username}\n  Port ${port}\n  ServerAliveInterval 60`;
}

router.get('/:clientId', requireAuth, async (req: Request, res: Response) => {
  const db = getDb();
  const admin = (req as any).admin;
  const { format = 'png' } = req.query;

  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.clientId) as any;
  if (!client) return res.status(404).json({ error: 'Client not found' });

  if (admin.role === 'reseller' && client.created_by !== admin.id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const settings = db.prepare('SELECT key, value FROM settings').all() as any[];
  const settingsMap = Object.fromEntries(settings.map((s: any) => [s.key, s.value]));

  let uri = '';
  switch (client.protocol) {
    case 'vless':
      uri = buildVlessUri(client, settingsMap);
      break;
    case 'vmess':
      uri = buildVmessUri(client, settingsMap);
      break;
    case 'ssh':
    case 'slowdns':
      uri = buildSshConfig(client, settingsMap);
      break;
    default:
      uri = `katashie://connect?user=${client.username}&protocol=${client.protocol}`;
  }

  if (format === 'uri') {
    return res.json({ uri, username: client.username, protocol: client.protocol });
  }

  try {
    const qrDataUrl = await QRCode.toDataURL(uri, {
      errorCorrectionLevel: 'M',
      margin: 2,
      color: { dark: '#0055ff', light: '#ffffff' },
      width: 400
    });
    res.json({ qr: qrDataUrl, uri, username: client.username, protocol: client.protocol });
  } catch (err: any) {
    res.status(500).json({ error: 'QR generation failed', detail: err.message });
  }
});

export default router;
