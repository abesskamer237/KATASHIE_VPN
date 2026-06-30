import { useState, useEffect } from 'react';
import { Shield, Zap, Globe, Lock, Phone, MessageCircle, Star, ChevronRight, Wifi } from 'lucide-react';

interface Plan {
  id: string;
  name: string;
  protocol: string;
  duration_days: number;
  price: number;
}

export default function LandingPage() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [phone, setPhone] = useState('');
  const [selectedPlan, setSelectedPlan] = useState<Plan | null>(null);
  const [step, setStep] = useState<'plans' | 'pay' | 'pending'>('plans');
  const [payResult, setPayResult] = useState<any>(null);

  useEffect(() => {
    fetch('/api/plans').then(r => r.json()).then(setPlans).catch(() => {});
  }, []);

  const handleBuy = async (plan: Plan) => {
    setSelectedPlan(plan);
    setStep('pay');
  };

  const handlePay = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPlan) return;
    const r = await fetch('/api/payment/initiate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone, plan_id: selectedPlan.id, amount: selectedPlan.price })
    });
    const data = await r.json();
    setPayResult(data);
    setStep('pending');
  };

  return (
    <div className="landing-page">
      {/* Header */}
      <header className="landing-header">
        <div className="landing-logo">
          <span className="logo-k">K</span>
          <span className="logo-text">ATASHIE <span style={{ color: 'var(--blue)' }}>VPN</span></span>
        </div>
        <nav className="landing-nav">
          <a href="#features">Fonctionnalités</a>
          <a href="#plans">Tarifs</a>
          <a href={`https://wa.me/237682229367`} target="_blank" rel="noreferrer">Support</a>
          <a href="/login" className="btn btn-primary btn-sm">Connexion</a>
        </nav>
      </header>

      {/* Hero */}
      <section className="hero-section">
        <div className="hero-content">
          <div className="hero-badge"><Wifi size={14} /> VPN Haute Performance — Cameroun</div>
          <h1 className="hero-title">Naviguez sans<br /><span className="hero-accent">limite</span> et sans<br />surveillance</h1>
          <p className="hero-subtitle">
            KATASHIE VPN vous offre SSH, VLESS, VMESS et plus encore — avec des serveurs rapides,
            un support réactif et des tarifs adaptés à l'Afrique.
          </p>
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            <a href="#plans" className="btn btn-primary btn-lg">
              Voir les tarifs <ChevronRight size={18} />
            </a>
            <a href={`https://wa.me/237682229367?text=Bonjour,%20je%20veux%20un%20VPN%20KATASHIE`}
              target="_blank" rel="noreferrer" className="btn btn-ghost btn-lg">
              <MessageCircle size={18} /> WhatsApp
            </a>
          </div>
        </div>
        <div className="hero-visual">
          <div className="hero-globe">
            <Globe size={120} style={{ color: 'var(--blue)', opacity: 0.15 }} />
            <div className="hero-shield"><Shield size={60} style={{ color: 'var(--blue)' }} /></div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="features-section">
        <h2 className="section-title">Pourquoi choisir KATASHIE VPN ?</h2>
        <div className="features-grid">
          {[
            { icon: Zap, title: 'Ultra rapide', desc: 'Serveurs optimisés pour les connexions africaines. Pas de latence, pas de buffering.' },
            { icon: Lock, title: 'Chiffrement fort', desc: 'TLS 1.3, VLESS Reality, VMESS. Vos données sont invisibles aux yeux des FAI.' },
            { icon: Globe, title: 'Multi-protocoles', desc: 'SSH, VLESS, VMESS, Trojan, SOCKS5. Choisissez ce qui fonctionne le mieux pour vous.' },
            { icon: Phone, title: 'Support WhatsApp', desc: 'Assistance 24/7 via WhatsApp. Un problème ? On règle ça immédiatement.' },
            { icon: Star, title: 'Paiement local', desc: 'Orange Money et MTN MoMo acceptés. Pas de carte bancaire nécessaire.' },
            { icon: Shield, title: 'Compte auto', desc: 'Après paiement, votre compte est créé instantanément. Connexion en 2 minutes.' }
          ].map(({ icon: Icon, title, desc }) => (
            <div key={title} className="feature-card">
              <div className="feature-icon"><Icon size={28} /></div>
              <h3>{title}</h3>
              <p>{desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Plans */}
      <section id="plans" className="plans-section">
        <h2 className="section-title">Nos offres</h2>

        {step === 'plans' && (
          <div className="plans-grid">
            {plans.filter(p => p.price > 0).map(plan => (
              <div key={plan.id} className="plan-card">
                <div className="plan-protocol">{plan.protocol.toUpperCase()}</div>
                <div className="plan-name">{plan.name}</div>
                <div className="plan-price">
                  <span className="plan-amount">{plan.price?.toLocaleString()}</span>
                  <span className="plan-currency"> XAF</span>
                </div>
                <div className="plan-duration">{plan.duration_days} jours</div>
                <ul className="plan-features">
                  <li>✅ Activation instantanée</li>
                  <li>✅ Support WhatsApp inclus</li>
                  <li>✅ Renouvellement facile</li>
                </ul>
                <button className="btn btn-primary" style={{ width: '100%' }} onClick={() => handleBuy(plan)}>
                  Acheter — {plan.price?.toLocaleString()} XAF
                </button>
              </div>
            ))}
            {plans.filter(p => p.price > 0).length === 0 && (
              <div style={{ textAlign: 'center', color: 'var(--text-muted)', gridColumn: '1/-1' }}>
                <p>Contactez-nous sur WhatsApp pour nos tarifs</p>
                <a href="https://wa.me/237682229367" target="_blank" rel="noreferrer" className="btn btn-primary">
                  <MessageCircle size={16} /> Contacter le support
                </a>
              </div>
            )}
          </div>
        )}

        {step === 'pay' && selectedPlan && (
          <div style={{ maxWidth: 420, margin: '0 auto' }}>
            <div className="plan-card" style={{ marginBottom: '1.5rem' }}>
              <div className="plan-name">{selectedPlan.name}</div>
              <div className="plan-price"><span className="plan-amount">{selectedPlan.price?.toLocaleString()}</span> XAF</div>
            </div>
            <form onSubmit={handlePay} style={{ display: 'grid', gap: '1rem' }}>
              <div>
                <label className="form-label">Votre numéro Orange Money ou MTN MoMo</label>
                <input className="input" placeholder="237XXXXXXXXX" value={phone}
                  onChange={e => setPhone(e.target.value)} required />
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                  Exemple: 237682229367 ou 237671234567
                </span>
              </div>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button type="button" className="btn btn-ghost" style={{ flex: 1 }} onClick={() => setStep('plans')}>Retour</button>
                <button type="submit" className="btn btn-primary" style={{ flex: 2 }}>
                  <Phone size={16} /> Payer {selectedPlan.price?.toLocaleString()} XAF
                </button>
              </div>
            </form>
          </div>
        )}

        {step === 'pending' && payResult && (
          <div style={{ maxWidth: 420, margin: '0 auto', textAlign: 'center' }}>
            {payResult.error ? (
              <div className="alert alert-error">{payResult.error}<br /><button className="btn btn-ghost btn-sm" onClick={() => setStep('pay')}>Réessayer</button></div>
            ) : (
              <div className="card">
                <div className="card-body" style={{ textAlign: 'center', display: 'grid', gap: '1rem' }}>
                  <div style={{ fontSize: '3rem' }}>📱</div>
                  <h3>Confirmez le paiement</h3>
                  {payResult.ussd_code && (
                    <div className="info-box">
                      <div style={{ marginBottom: '0.5rem' }}>Composez ce code sur votre téléphone:</div>
                      <code style={{ fontSize: '1.4rem', color: 'var(--blue)', fontWeight: 700 }}>{payResult.ussd_code}</code>
                    </div>
                  )}
                  <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                    Après confirmation, votre compte VPN sera créé automatiquement et vous recevrez les détails de connexion par SMS ou WhatsApp.
                  </p>
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Réf: {payResult.reference}</p>
                  <a href={`https://wa.me/237682229367?text=J'ai%20payé%20avec%20la%20réf%20${payResult.reference}`}
                    target="_blank" rel="noreferrer" className="btn btn-primary">
                    <MessageCircle size={16} /> Confirmer via WhatsApp
                  </a>
                </div>
              </div>
            )}
          </div>
        )}
      </section>

      {/* Contact */}
      <section className="contact-section">
        <h2 className="section-title">Nous contacter</h2>
        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center', flexWrap: 'wrap' }}>
          <a href="https://wa.me/237682229367" target="_blank" rel="noreferrer" className="btn btn-primary btn-lg">
            <MessageCircle size={18} /> WhatsApp: +237 682 229 367
          </a>
          <a href="https://t.me/abess237" target="_blank" rel="noreferrer" className="btn btn-ghost btn-lg">
            Telegram: @abess237
          </a>
          <a href="https://whatsapp.com/channel/0029Vb8J9L44Y9li0Ffkqu1J" target="_blank" rel="noreferrer" className="btn btn-ghost btn-lg">
            Chaîne WhatsApp
          </a>
        </div>
      </section>

      {/* Footer */}
      <footer className="landing-footer">
        <div className="landing-logo" style={{ justifyContent: 'center' }}>
          <span className="logo-k">K</span>
          <span className="logo-text">ATASHIE VPN</span>
        </div>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.8rem', marginTop: '0.5rem' }}>
          © {new Date().getFullYear()} KATASHIE VPN — Tous droits réservés
        </p>
      </footer>
    </div>
  );
}
