import { useState, useEffect } from 'react';
import { ScrollText, Search, RefreshCw, Trash2 } from 'lucide-react';
import { useI18n } from '../contexts/I18nContext';

interface AuditLog {
  id: number;
  admin_username: string;
  admin_role: string;
  action: string;
  ip: string;
  status: string;
  created_at: string;
}

export default function AuditLogPage() {
  const { t } = useI18n();
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ username: '', action: '', status: '' });
  const token = localStorage.getItem('token');
  const headers = { Authorization: `Bearer ${token}` };

  const load = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: String(page), limit: '50', ...filters });
      const r = await fetch(`/api/audit-logs?${params}`, { headers });
      const data = await r.json();
      setLogs(data.logs || []);
      setTotal(data.total || 0);
    } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, [page, filters]);

  const exportCsv = () => {
    window.open('/api/export/audit/csv', '_blank');
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">
          <ScrollText size={22} style={{ display: 'inline', marginRight: '0.5rem', color: 'var(--blue)' }} />
          {t('nav.audit')}
        </h1>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button className="btn btn-ghost btn-sm" onClick={exportCsv}>Export CSV</button>
          <button className="btn btn-ghost btn-sm" onClick={load}><RefreshCw size={15} /></button>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative', flex: 1, minWidth: 160 }}>
          <Search size={14} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
          <input className="input" style={{ paddingLeft: '2rem' }} placeholder="Utilisateur..."
            value={filters.username} onChange={e => setFilters(p => ({...p, username: e.target.value}))} />
        </div>
        <input className="input" style={{ flex: 1, minWidth: 140 }} placeholder="Action..."
          value={filters.action} onChange={e => setFilters(p => ({...p, action: e.target.value}))} />
        <select className="input" style={{ flex: 1, minWidth: 120 }} value={filters.status}
          onChange={e => setFilters(p => ({...p, status: e.target.value}))}>
          <option value="">Tous statuts</option>
          <option value="success">Succès</option>
          <option value="failure">Échec</option>
        </select>
      </div>

      <div className="table-container">
        <table className="table">
          <thead>
            <tr>
              <th>Utilisateur</th>
              <th>Rôle</th>
              <th>Action</th>
              <th>IP</th>
              <th>Statut</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} style={{ textAlign: 'center' }}><RefreshCw size={16} className="spin" /> Chargement...</td></tr>
            ) : logs.map(log => (
              <tr key={log.id}>
                <td><strong>{log.admin_username}</strong></td>
                <td><span className={`badge badge-${log.admin_role === 'admin' ? 'online' : 'warning'}`}>{log.admin_role}</span></td>
                <td style={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', fontSize: '0.8rem' }}>{log.action}</td>
                <td style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontFamily: 'monospace' }}>{log.ip}</td>
                <td><span className={`badge badge-${log.status === 'success' ? 'online' : 'offline'}`}>{log.status}</span></td>
                <td style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{new Date(log.created_at).toLocaleString('fr-FR')}</td>
              </tr>
            ))}
            {!loading && logs.length === 0 && (
              <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Aucun log</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {total > 50 && (
        <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'center', marginTop: '1rem' }}>
          <button className="btn btn-ghost btn-sm" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>← Précédent</button>
          <span style={{ color: 'var(--text-muted)', fontSize: '0.85rem', lineHeight: '2rem' }}>Page {page} — {total} entrées</span>
          <button className="btn btn-ghost btn-sm" onClick={() => setPage(p => p + 1)} disabled={page * 50 >= total}>Suivant →</button>
        </div>
      )}
    </div>
  );
}
