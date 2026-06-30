import { Router, Request, Response } from 'express';
import { exec } from 'child_process';
import { promisify } from 'util';
import { requireAuth } from '../middleware/auth';

const router = Router();
const execAsync = promisify(exec);

async function getSystemStats() {
  const stats: Record<string, any> = {};

  // CPU usage
  try {
    const { stdout: cpuRaw } = await execAsync("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | tr -d '%us,'");
    stats.cpu = parseFloat(cpuRaw.trim()) || 0;
  } catch { stats.cpu = 0; }

  // Memory
  try {
    const { stdout: memRaw } = await execAsync("free -m | awk 'NR==2{printf \"%s %s %s\", $2,$3,$4}'");
    const [total, used, free] = memRaw.trim().split(' ').map(Number);
    stats.memory = { total, used, free, percent: Math.round((used / total) * 100) };
  } catch { stats.memory = { total: 0, used: 0, free: 0, percent: 0 }; }

  // Disk
  try {
    const { stdout: diskRaw } = await execAsync("df -h / | awk 'NR==2{printf \"%s %s %s %s\", $2,$3,$4,$5}'");
    const [total, used, free, percent] = diskRaw.trim().split(' ');
    stats.disk = { total, used, free, percent: parseInt(percent) || 0 };
  } catch { stats.disk = { total: '0', used: '0', free: '0', percent: 0 }; }

  // Network (rx/tx bytes)
  try {
    const { stdout: netRaw } = await execAsync("cat /proc/net/dev | grep -E 'eth0|ens|enp' | head -1 | awk '{print $2, $10}'");
    const [rx, tx] = netRaw.trim().split(' ').map(Number);
    stats.network = { rx_bytes: rx || 0, tx_bytes: tx || 0 };
  } catch { stats.network = { rx_bytes: 0, tx_bytes: 0 }; }

  // Uptime
  try {
    const { stdout: uptimeRaw } = await execAsync("cat /proc/uptime");
    stats.uptime_seconds = Math.floor(parseFloat(uptimeRaw.split(' ')[0]));
  } catch { stats.uptime_seconds = 0; }

  // Active connections (SSH)
  try {
    const { stdout: connRaw } = await execAsync("ss -tn | grep ':22 ' | wc -l");
    stats.ssh_connections = parseInt(connRaw.trim()) || 0;
  } catch { stats.ssh_connections = 0; }

  // Load average
  try {
    const { stdout: loadRaw } = await execAsync("cat /proc/loadavg");
    const parts = loadRaw.trim().split(' ');
    stats.load = { '1m': parseFloat(parts[0]), '5m': parseFloat(parts[1]), '15m': parseFloat(parts[2]) };
  } catch { stats.load = { '1m': 0, '5m': 0, '15m': 0 }; }

  return stats;
}

// SSE endpoint — real-time monitoring stream
router.get('/stream', requireAuth, (req: Request, res: Response) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.flushHeaders();

  const send = async () => {
    try {
      const stats = await getSystemStats();
      res.write(`data: ${JSON.stringify({ ...stats, timestamp: new Date().toISOString() })}\n\n`);
    } catch (e) {
      res.write(`data: ${JSON.stringify({ error: 'stats_unavailable' })}\n\n`);
    }
  };

  send();
  const interval = setInterval(send, 3000);

  req.on('close', () => {
    clearInterval(interval);
    res.end();
  });
});

// Snapshot — single poll
router.get('/snapshot', requireAuth, async (_req: Request, res: Response) => {
  const stats = await getSystemStats();
  res.json({ ...stats, timestamp: new Date().toISOString() });
});

export default router;
