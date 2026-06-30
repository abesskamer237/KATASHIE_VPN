import { useState, useEffect } from 'react';
import { Server, Plus, Trash2, RefreshCw, MapPin, CheckCircle, XCircle } from 'lucide-react';
import { useI18n } from '../contexts/I18nContext';

interface VPSServer {
  id: string;
  name: string;
  host: string;
  port: number;
  ssh_user: string;
  location: string;
  status: string;
  last_check: string;
  cpu_usage: number;
  memory_usage: number;
  active_users: number;
  created_at: string;
}

export default function ServersPage() {
  const { t } = useI18n();
  const [servers, setServers] = useState<VPSServer[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', host: '', port: 22, ssh_user: 'root', ssh_password: '', location: '' });
  const token = localStorage.getItem('token');

  const headers = { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` };

  const load = async () => {
    setLoading(true);
    try {
      const r = await fetch('/api/servers', { headers });
      setServers(await r.json());
    } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const addServer = async (e: React.FormEvent) => {
    e.preventDefault();
    await fetch('/api/servers', { method: 'POST', headers, body: JSON.stringify(form) });
    setShowForm(false);
    setForm({ name: '', host: '', port: 22, ssh_user: 'root', ssh_password: '', location: '' });
    load();
  };

  const deleteServer = async (id: string) => {
    if (!confirm('Supprimer ce serveur ?')) return;
    await fetch(`/api/servers/${id}`, { method: 'DELETE', headers });
    load();
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">
          <Server size={22} style={{ display: 'inline', marginRight: '0.5rem', color: 'var(--blue)' }} />
          {t('servers.title')}
        </h1>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button className="btn btn-ghost btn-sm" onClick={load}><RefreshCw size={15} /></button>
          <button className="btn btn-primary btn-sm" onClick={() => setShowForm(true)}>
            <Plus size={15} /> {t('servers.add')}
          </button>
        </div>
      </div>

      {showForm && (
        <div className="modal-overlay" onClick={() => setShowForm(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header"><h3>Ajouter un serveur VPS</h3></div>
            <form onSubmit={addServer} className="modal-body" style={{ display: 'grid', gap: '0.75rem' }}>
              <input className="input" placeholder={t('servers.name')} value={form.name} onChange={e => setForm(p => ({...p, name: e.target.value}))} required />
              <input className="input" placeholder={t('servers.host') + ' (IP ou domaine)'} value={form.host} onChange={e => setForm(p => ({...p, host: e.target.value}))} required />
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                <input className="input" type="number" placeholder="Port SSH" value={form.port} onChange={e => setForm(p => ({...p, port: +e.target.value}))} />
                <input className="input" placeholder="User SSH" value={form.ssh_user} onChange={e => setForm(p => ({...p, ssh_user: e.target.value}))} />
              </div>
              <input className="input" type="password" placeholder="Mot de passe SSH" value={form.ssh_password} onChange={e => setForm(p => ({...p, ssh_password: e.target.value}))} />
              <input className="input" placeholder={t('servers.location') + ' (ex: Cameroun, Paris)'} value={form.location} onChange={e => setForm(p => ({...p, location: e.target.value}))} />
              <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                <button type="button" className="btn btn-ghost" onClick={() => setShowForm(false)}>{t('common.cancel')}</button>
                <button type="submit" className="btn btn-primary">Ajouter</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {loading ? (
        <div className="loading-state"><RefreshCw size={24} className="spin" /> Chargement...</div>
      ) : servers.length === 0 ? (
        <div className="empty-state">
          <Server size={48} style={{ color: 'var(--blue)', opacity: 0.4 }} />
          <p>Aucun serveur configuré</p>
          <button className="btn btn-primary" onClick={() => setShowForm(true)}><Plus size={15} /> Ajouter un serveur</button>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: '1rem', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))' }}>
          {servers.map(srv => (
            <div key={srv.id} className="card">
              <div className="card-header">
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  {srv.status === 'online' ? <CheckCircle size={16} color="#10b981" /> : <XCircle size={16} color="#ef4444" />}
                  <span className="card-title">{srv.name}</span>
                </div>
                <button className="btn btn-ghost btn-sm btn-danger" onClick={() => deleteServer(srv.id)}><Trash2 size={14} /></button>
              </div>
              <div className="card-body" style={{ display: 'grid', gap: '0.5rem' }}>
                <div style={{ display: 'flex', gap: '0.5rem', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  <Server size={13} /> <span>{srv.host}:{srv.port}</span>
                  {srv.location && <><MapPin size={13} /><span>{srv.location}</span></>}
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.5rem', marginTop: '0.5rem' }}>
                  <div className="mini-stat">
                    <span className="mini-stat-label">CPU</span>
                    <span className="mini-stat-value">{srv.cpu_usage?.toFixed(1) || 0}%</span>
                    <div className="progress-bar-track"><div className="progress-bar-fill" style={{ width: `${srv.cpu_usage || 0}%` }} /></div>
                  </div>
                  <div className="mini-stat">
                    <span className="mini-stat-label">RAM</span>
                    <span className="mini-stat-value">{srv.memory_usage?.toFixed(1) || 0}%</span>
                    <div className="progress-bar-track"><div className="progress-bar-fill" style={{ width: `${srv.memory_usage || 0}%`, background: '#10b981' }} /></div>
                  </div>
                  <div className="mini-stat">
                    <span className="mini-stat-label">Users</span>
                    <span className="mini-stat-value">{srv.active_users || 0}</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
