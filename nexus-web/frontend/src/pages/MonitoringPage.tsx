import { useEffect, useRef, useState } from 'react';
import { Activity, Cpu, HardDrive, Wifi, Clock, Users } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { useI18n } from '../contexts/I18nContext';

interface SystemStats {
  cpu: number;
  memory: { total: number; used: number; free: number; percent: number };
  disk: { total: string; used: string; free: string; percent: number };
  network: { rx_bytes: number; tx_bytes: number };
  uptime_seconds: number;
  ssh_connections: number;
  load: { '1m': number; '5m': number; '15m': number };
  timestamp: string;
}

function formatUptime(sec: number): string {
  const d = Math.floor(sec / 86400);
  const h = Math.floor((sec % 86400) / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return `${d}j ${h}h ${m}m`;
}

function formatBytes(bytes: number): string {
  if (bytes > 1e9) return (bytes / 1e9).toFixed(1) + ' GB';
  if (bytes > 1e6) return (bytes / 1e6).toFixed(1) + ' MB';
  return (bytes / 1e3).toFixed(1) + ' KB';
}

export default function MonitoringPage() {
  const { t } = useI18n();
  const [stats, setStats] = useState<SystemStats | null>(null);
  const [history, setHistory] = useState<Array<{ time: string; cpu: number; mem: number; rx: number; tx: number }>>([]);
  const [connected, setConnected] = useState(false);
  const esRef = useRef<EventSource | null>(null);
  const prevNetRef = useRef<{ rx: number; tx: number } | null>(null);

  useEffect(() => {
    const token = localStorage.getItem('token');
    const es = new EventSource(`/api/monitoring/stream?token=${token}`);
    esRef.current = es;
    setConnected(true);

    es.onmessage = (e) => {
      try {
        const data: SystemStats = JSON.parse(e.data);
        if (data.error) return;
        setStats(data);

        const prev = prevNetRef.current;
        const rxSpeed = prev ? Math.max(0, data.network.rx_bytes - prev.rx) : 0;
        const txSpeed = prev ? Math.max(0, data.network.tx_bytes - prev.tx) : 0;
        prevNetRef.current = { rx: data.network.rx_bytes, tx: data.network.tx_bytes };

        const time = new Date(data.timestamp).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
        setHistory(prev => [...prev.slice(-29), { time, cpu: data.cpu, mem: data.memory.percent, rx: rxSpeed, tx: txSpeed }]);
      } catch {}
    };

    es.onerror = () => setConnected(false);
    return () => { es.close(); setConnected(false); };
  }, []);

  const StatCard = ({ icon: Icon, label, value, sub, color, percent }: any) => (
    <div className="stat-card">
      <div className="stat-card-header">
        <div className="stat-icon" style={{ background: `${color}22`, color }}>
          <Icon size={20} />
        </div>
        <span className="stat-label">{label}</span>
        <span className={`badge ${connected ? 'badge-online' : 'badge-offline'}`} style={{ marginLeft: 'auto', fontSize: '0.65rem' }}>
          {connected ? 'LIVE' : 'OFF'}
        </span>
      </div>
      <div className="stat-value" style={{ color }}>{value}</div>
      {sub && <div className="stat-sub">{sub}</div>}
      {percent !== undefined && (
        <div className="progress-bar-track" style={{ marginTop: '0.5rem' }}>
          <div className="progress-bar-fill" style={{ width: `${Math.min(100, percent)}%`, background: percent > 80 ? '#ef4444' : percent > 60 ? '#f59e0b' : color }} />
        </div>
      )}
    </div>
  );

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">
          <Activity size={22} style={{ display: 'inline', marginRight: '0.5rem', color: 'var(--blue)' }} />
          {t('monitoring.title')}
        </h1>
      </div>

      <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))' }}>
        <StatCard icon={Cpu} label={t('monitoring.cpu')} value={stats ? `${stats.cpu.toFixed(1)}%` : '—'}
          sub={stats ? `Load: ${stats.load['1m'].toFixed(2)} / ${stats.load['5m'].toFixed(2)} / ${stats.load['15m'].toFixed(2)}` : ''}
          color="#0055ff" percent={stats?.cpu} />
        <StatCard icon={Activity} label={t('monitoring.memory')} value={stats ? `${stats.memory.percent}%` : '—'}
          sub={stats ? `${stats.memory.used} / ${stats.memory.total} MB` : ''}
          color="#10b981" percent={stats?.memory.percent} />
        <StatCard icon={HardDrive} label={t('monitoring.disk')} value={stats ? `${stats.disk.percent}%` : '—'}
          sub={stats ? `${stats.disk.used} / ${stats.disk.total}` : ''}
          color="#f59e0b" percent={stats?.disk.percent} />
        <StatCard icon={Clock} label={t('monitoring.uptime')} value={stats ? formatUptime(stats.uptime_seconds) : '—'}
          color="#8b5cf6" />
        <StatCard icon={Users} label={t('monitoring.connections')} value={stats ? String(stats.ssh_connections) : '—'}
          color="#0055ff" />
        <StatCard icon={Wifi} label={t('monitoring.network')} value={stats ? `↓ ${formatBytes(0)} / ↑ ${formatBytes(0)}` : '—'}
          color="#ec4899" />
      </div>

      <div style={{ display: 'grid', gap: '1.5rem', marginTop: '1.5rem', gridTemplateColumns: '1fr 1fr' }}>
        <div className="card">
          <div className="card-header"><span className="card-title">CPU & Mémoire</span></div>
          <div className="card-body" style={{ height: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={history}>
                <defs>
                  <linearGradient id="cpu-grad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#0055ff" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#0055ff" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="mem-grad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="time" tick={{ fontSize: 10, fill: 'var(--text-muted)' }} />
                <YAxis domain={[0, 100]} tick={{ fontSize: 10, fill: 'var(--text-muted)' }} unit="%" />
                <Tooltip contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 8 }} />
                <Area type="monotone" dataKey="cpu" name="CPU" stroke="#0055ff" fill="url(#cpu-grad)" strokeWidth={2} dot={false} />
                <Area type="monotone" dataKey="mem" name="Mémoire" stroke="#10b981" fill="url(#mem-grad)" strokeWidth={2} dot={false} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="card">
          <div className="card-header"><span className="card-title">Bande passante réseau</span></div>
          <div className="card-body" style={{ height: 220 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={history}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="time" tick={{ fontSize: 10, fill: 'var(--text-muted)' }} />
                <YAxis tick={{ fontSize: 10, fill: 'var(--text-muted)' }} />
                <Tooltip contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 8 }} />
                <Line type="monotone" dataKey="rx" name="↓ Reçu" stroke="#0055ff" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="tx" name="↑ Envoyé" stroke="#ec4899" strokeWidth={2} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
