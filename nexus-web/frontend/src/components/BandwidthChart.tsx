import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';

const PROTOCOL_COLORS: Record<string, string> = {
  ssh: '#0055ff',
  vless: '#10b981',
  vmess: '#f59e0b',
  trojan: '#8b5cf6',
  socks: '#ec4899',
  slowdns: '#06b6d4',
  zivpn: '#84cc16',
};

interface ProtocolData { protocol: string; n: number }
interface BandwidthData { username: string; data_used: number; data_limit: number }

export function ProtocolPieChart({ data }: { data: ProtocolData[] }) {
  const chartData = data.map(d => ({ name: d.protocol.toUpperCase(), value: d.n }));
  return (
    <ResponsiveContainer width="100%" height={220}>
      <PieChart>
        <Pie data={chartData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label={({ name, value }) => `${name}: ${value}`}>
          {chartData.map((entry) => (
            <Cell key={entry.name} fill={PROTOCOL_COLORS[entry.name.toLowerCase()] || '#6b7280'} />
          ))}
        </Pie>
        <Tooltip contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 8 }} />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}

export function BandwidthBarChart({ data }: { data: BandwidthData[] }) {
  const chartData = data
    .filter(d => d.data_used > 0)
    .slice(0, 15)
    .map(d => ({
      name: d.username.length > 12 ? d.username.slice(0, 12) + '…' : d.username,
      used: Math.round((d.data_used || 0) / 1024 / 1024),
      limit: d.data_limit ? Math.round(d.data_limit / 1024 / 1024) : 0
    }));

  if (chartData.length === 0) {
    return <div style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem' }}>Aucune donnée de bande passante</div>;
  }

  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={chartData} margin={{ top: 0, right: 0, left: 0, bottom: 30 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
        <XAxis dataKey="name" tick={{ fontSize: 10, fill: 'var(--text-muted)' }} angle={-35} textAnchor="end" />
        <YAxis tick={{ fontSize: 10, fill: 'var(--text-muted)' }} unit=" MB" />
        <Tooltip contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 8 }} formatter={(v: any) => [`${v} MB`]} />
        <Bar dataKey="used" name="Utilisé" fill="#0055ff" radius={[4, 4, 0, 0]} />
        {chartData.some(d => d.limit > 0) && <Bar dataKey="limit" name="Limite" fill="#374151" radius={[4, 4, 0, 0]} />}
      </BarChart>
    </ResponsiveContainer>
  );
}
