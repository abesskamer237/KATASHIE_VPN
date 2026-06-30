import { useState, useEffect } from 'react';
import { CreditCard, Phone, CheckCircle, Clock, XCircle, RefreshCw } from 'lucide-react';
import { useI18n } from '../contexts/I18nContext';

interface Plan {
  id: string;
  name: string;
  protocol: string;
  duration_days: number;
  price: number;
  currency: string;
}

interface Payment {
  id: string;
  reference: string;
  plan_id: string;
  phone: string;
  amount: number;
  status: string;
  created_at: string;
}

export default function PaymentPage() {
  const { t } = useI18n();
  const [plans, setPlans] = useState<Plan[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [form, setForm] = useState({ phone: '', plan_id: '', amount: '' });
  const [result, setResult] = useState<any>(null);
  const [checking, setChecking] = useState(false);
  const [tab, setTab] = useState<'new' | 'history'>('new');
  const token = localStorage.getItem('token');
  const headers = { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` };

  useEffect(() => {
    fetch('/api/plans', { headers }).then(r => r.json()).then(setPlans).catch(() => {});
    fetch('/api/payment', { headers }).then(r => r.json()).then(setPayments).catch(() => {});
  }, []);

  const selectedPlan = plans.find(p => p.id === form.plan_id);

  const initiate = async (e: React.FormEvent) => {
    e.preventDefault();
    setResult(null);
    try {
      const r = await fetch('/api/payment/initiate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: form.phone, plan_id: form.plan_id, amount: parseFloat(form.amount) })
      });
      const data = await r.json();
      setResult(data);
    } catch (err) {
      setResult({ error: 'Erreur de connexion' });
    }
  };

  const checkStatus = async (reference: string) => {
    setChecking(true);
    try {
      const r = await fetch(`/api/payment/status/${reference}`);
      const data = await r.json();
      setResult(prev => ({ ...prev, status: data.status, client_id: data.client_id }));
    } finally { setChecking(false); }
  };

  const StatusIcon = ({ status }: { status: string }) => {
    if (status === 'successful') return <CheckCircle size={16} color="#10b981" />;
    if (status === 'failed') return <XCircle size={16} color="#ef4444" />;
    return <Clock size={16} color="#f59e0b" />;
  };

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">
          <CreditCard size={22} style={{ display: 'inline', marginRight: '0.5rem', color: 'var(--blue)' }} />
          {t('payment.title')}
        </h1>
        <div style={{ display: 'flex', gap: '0.25rem' }}>
          {(['new', 'history'] as const).map(tab_name => (
            <button key={tab_name} className={`btn btn-sm ${tab === tab_name ? 'btn-primary' : 'btn-ghost'}`} onClick={() => setTab(tab_name)}>
              {tab_name === 'new' ? 'Nouveau paiement' : 'Historique'}
            </button>
          ))}
        </div>
      </div>

      {tab === 'new' && (
        <div style={{ maxWidth: 500 }}>
          <div className="card">
            <div className="card-header"><span className="card-title">Paiement Orange Money / MTN MoMo</span></div>
            <form onSubmit={initiate} className="card-body" style={{ display: 'grid', gap: '1rem' }}>
              <div>
                <label className="form-label"><Phone size={13} /> {t('payment.phone')}</label>
                <input className="input" placeholder="237XXXXXXXXX" value={form.phone}
                  onChange={e => setForm(p => ({...p, phone: e.target.value}))} required />
                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Format: 237 suivi des 9 chiffres</span>
              </div>
              <div>
                <label className="form-label">{t('payment.plan')}</label>
                <select className="input" value={form.plan_id} onChange={e => {
                  const plan = plans.find(p => p.id === e.target.value);
                  setForm(p => ({...p, plan_id: e.target.value, amount: plan?.price?.toString() || ''}));
                }} required>
                  <option value="">Choisir un plan...</option>
                  {plans.map(p => (
                    <option key={p.id} value={p.id}>{p.name} — {p.price} XAF / {p.duration_days}j ({p.protocol.toUpperCase()})</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="form-label">{t('payment.amount')}</label>
                <input className="input" type="number" value={form.amount}
                  onChange={e => setForm(p => ({...p, amount: e.target.value}))} required min="100" />
              </div>
              <button type="submit" className="btn btn-primary" style={{ width: '100%' }}>
                <CreditCard size={16} /> {t('payment.pay_now')}
              </button>
            </form>
          </div>

          {result && (
            <div className="card" style={{ marginTop: '1rem' }}>
              <div className="card-body">
                {result.error ? (
                  <div className="alert alert-error">{result.error}</div>
                ) : (
                  <>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                      <StatusIcon status={result.status || 'pending'} />
                      <strong>Statut: {result.status || 'pending'}</strong>
                    </div>
                    {result.ussd_code && (
                      <div className="info-box">
                        <strong>Code USSD:</strong> <code style={{ fontSize: '1.1rem', color: 'var(--blue)' }}>{result.ussd_code}</code>
                        <br /><span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Composez ce code sur votre téléphone pour confirmer</span>
                      </div>
                    )}
                    {result.reference && (
                      <div style={{ marginTop: '1rem', display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Réf: {result.reference}</span>
                        <button className="btn btn-ghost btn-sm" onClick={() => checkStatus(result.reference)} disabled={checking}>
                          {checking ? <RefreshCw size={13} className="spin" /> : <RefreshCw size={13} />} Actualiser
                        </button>
                      </div>
                    )}
                    {result.client_id && (
                      <div className="alert alert-success" style={{ marginTop: '0.5rem' }}>
                        ✅ Compte VPN créé automatiquement! ID: {result.client_id}
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>
          )}
        </div>
      )}

      {tab === 'history' && (
        <div className="table-container">
          <table className="table">
            <thead>
              <tr>
                <th>Référence</th>
                <th>Téléphone</th>
                <th>Montant</th>
                <th>Statut</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {payments.map(p => (
                <tr key={p.id}>
                  <td><code style={{ fontSize: '0.75rem' }}>{p.reference}</code></td>
                  <td>{p.phone}</td>
                  <td>{p.amount?.toLocaleString()} XAF</td>
                  <td><span className={`badge badge-${p.status === 'successful' ? 'online' : p.status === 'failed' ? 'offline' : 'warning'}`}>{p.status}</span></td>
                  <td style={{ fontSize: '0.8rem' }}>{new Date(p.created_at).toLocaleString('fr-FR')}</td>
                </tr>
              ))}
              {payments.length === 0 && <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Aucun paiement</td></tr>}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
