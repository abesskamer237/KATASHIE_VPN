import { useState, useEffect, useCallback } from 'react';
import { api } from '@/lib/api';
import { expiryToUnix } from '@/lib/utils';
import { formatConfig } from '@/lib/config-formatter';
import ConfigOutput from '@/components/ConfigOutput';
import { Search, Trash2, RefreshCw, Eye, X, MinusCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { ProtocolType } from '@/lib/types';

interface Client {
  id: string;
  username: string;
  password: string;
  protocol: string;
  expires_at: string;
  status: string;
  created_at: string;
  extra_data?: Record<string, unknown>;
}

export default function ResellerAccounts() {
  const [accounts, setAccounts] = useState<Client[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [renewingId, setRenewingId] = useState<string | null>(null);
  // Server time (unix seconds) fetched once and used for display
  const [serverUnix, setServerUnix] = useState<number | null>(null);

  // Detail modal
  const [detailClient, setDetailClient] = useState<Client | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [renewDays, setRenewDays] = useState('30');
  const [renewLoading, setRenewLoading] = useState(false);
  const [renewError, setRenewError] = useState('');
  const [reduceDays, setReduceDays] = useState('1');
  const [reduceLoading, setReduceLoading] = useState(false);
  const [reduceError, setReduceError] = useState('');
  const [configText, setConfigText] = useState('');
  const [configLoading, setConfigLoading] = useState(false);

  const loadAccounts = useCallback(async () => {
    setLoadingList(true);
    try {
      const data = await api.listClients({ mine: true });
      setAccounts(data);
    } catch {}
    setLoadingList(false);
  }, []);

  useEffect(() => {
    loadAccounts();
    // Fetch server time once so status display uses server clock, not client clock
    api.getServerTime()
      .then(({ unix }) => setServerUnix(unix))
      .catch(() => {});
  }, [loadAccounts]);

  // Server-time-based active check — immune to client clock manipulation
  const isActive = (client: Client) => {
    const expiresUnix = expiryToUnix(client.expires_at);
    const now = serverUnix ?? Math.floor(Date.now() / 1000);
    return client.status === 'active' && expiresUnix > now;
  };

  const handleDelete = async (id: string) => {
    try {
      await api.deleteClient(id);
      await loadAccounts();
      if (detailClient?.id === id) setDetailClient(null);
    } catch {}
  };

  const handleRefreshData = async (id: string) => {
    setRenewingId(id); // On garde cet état uniquement pour déclencher l'animation de rotation
    try {
      await loadAccounts(); // Met à jour l'affichage avec les données fraîches du backend
    } catch {}
    setRenewingId(null);
  };

  const openDetail = async (id: string) => {
    setDetailLoading(true);
    setDetailClient(null);
    setConfigText('');
    setRenewError('');
    setReduceError('');
    setRenewDays('30');
    setReduceDays('1');
    try {
      const data = await api.getClient(id);
      setDetailClient(data);
      // Build config from extra_data
      setConfigLoading(true);
      try {
        const serverSettings = { ip: '', domain: '', nsDomain: '', slowdnsPub: '', openvpnDownload: '' };
        try {
          const s = await api.getSettings();
          if (s?.server) Object.assign(serverSettings, s.server);
        } catch {}
        const extra = typeof data.extra_data === 'object' && data.extra_data ? data.extra_data : {};
        const expiryStr = data.expires_at
          ? new Date(data.expires_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
          : data.expires_at;
        const config = formatConfig(
          { username: data.username, password: data.password, expiryDate: expiryStr, protocol: data.protocol as ProtocolType, ...extra },
          serverSettings,
        );
        setConfigText(config);
      } catch {}
      setConfigLoading(false);
    } catch {}
    setDetailLoading(false);
  };

  const handleDetailRenew = async () => {
    if (!detailClient) return;
    const days = parseInt(renewDays) || 30;
    if (days < 1) { setRenewError('Durée invalide'); return; }
    setRenewLoading(true);
    setRenewError('');
    try {
      const result = await api.renewClient(detailClient.id, days);
      await loadAccounts();
      setDetailClient(prev => prev ? { ...prev, expires_at: result.expires_at || prev.expires_at, status: 'active' } : null);
    } catch (e: any) {
      setRenewError(e.message || 'Erreur lors du renouvellement');
    }
    setRenewLoading(false);
  };

  const handleDetailReduce = async () => {
    if (!detailClient) return;
    const days = parseInt(reduceDays) || 1;
    if (days < 1) { setReduceError('Durée invalide'); return; }
    setReduceLoading(true);
    setReduceError('');
    try {
      const result = await api.reduceClientDays(detailClient.id, days);
      await loadAccounts();
      setDetailClient(prev => prev ? { ...prev, expires_at: result.expires_at || prev.expires_at, status: result.status || prev.status } : null);
    } catch (e: any) {
      setReduceError(e.message || 'Erreur lors de la réduction');
    }
    setReduceLoading(false);
  };

  const filtered = accounts.filter(a =>
    a.username.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
        <h1 className="text-2xl font-display font-bold tracking-tight">
          <span className="text-gradient-primary">Mes Comptes Créés</span>
        </h1>
        <p className="text-muted-foreground text-sm mt-1">{accounts.length} comptes au total</p>
      </motion.div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          className="input-dark w-full pl-10"
          placeholder="Rechercher..."
        />
      </div>

      <div className="glass-card overflow-hidden">
        <div className="grid grid-cols-6 gap-4 p-4 border-b border-border text-[10px] uppercase tracking-[0.2em] text-muted-foreground font-semibold">
          <span>Utilisateur</span>
          <span>Protocole</span>
          <span>Expiration</span>
          <span>Statut</span>
          <span>Créé le</span>
          <span className="text-right">Actions</span>
        </div>
        {loadingList ? (
          <div className="p-8 text-center text-muted-foreground">Chargement...</div>
        ) : (
          <AnimatePresence>
            {filtered.map((acc, i) => (
              <motion.div
                key={acc.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0 }}
                transition={{ delay: i * 0.05 }}
                className="grid grid-cols-6 gap-4 p-4 border-b border-border last:border-0 hover:bg-secondary/20 transition-all items-center"
              >
                <span className="text-sm font-mono text-foreground font-semibold">{acc.username}</span>
                <span className="protocol-badge border-primary/30 text-primary bg-primary/10 w-fit">
                  {acc.protocol?.toUpperCase()}
                </span>
                <span className="text-sm font-mono text-muted-foreground">{acc.expires_at}</span>
                <span className={`protocol-badge w-fit ${isActive(acc) ? 'border-success/30 text-success bg-success/10' : 'border-destructive/30 text-destructive bg-destructive/10'}`}>
                  {isActive(acc) ? 'Actif' : 'Expiré'}
                </span>
                <span className="text-sm font-mono text-muted-foreground">{acc.created_at?.split('T')[0]}</span>
                <div className="flex items-center justify-end gap-1">
                  <button
                    onClick={() => openDetail(acc.id)}
                    className="p-2 rounded-lg hover:bg-accent/10 text-accent transition-colors"
                    title="Voir les détails"
                  >
                    <Eye className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleRefreshData(acc.id)}
                    disabled={renewingId === acc.id}
                    className="p-2 rounded-lg hover:bg-primary/10 text-primary transition-colors"
                    title="Rafraîchir le statut"
                  >
                    <RefreshCw className={`w-4 h-4 ${renewingId === acc.id ? 'animate-spin' : ''}`} />
                  </button>
                  <button
                    onClick={() => handleDelete(acc.id)}
                    className="p-2 rounded-lg hover:bg-destructive/10 text-destructive transition-colors"
                    title="Supprimer"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        )}
        {!loadingList && filtered.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">Aucun compte trouvé</div>
        )}
      </div>

      {/* Detail Modal */}
      <AnimatePresence>
        {(detailLoading || detailClient) && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4"
            onClick={e => { if (e.target === e.currentTarget) setDetailClient(null); }}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="glass-card w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6 relative"
            >
              <button
                onClick={() => setDetailClient(null)}
                className="absolute top-4 right-4 p-1.5 rounded-lg hover:bg-secondary/50 text-muted-foreground"
              >
                <X className="w-5 h-5" />
              </button>

              {detailLoading ? (
                <div className="py-12 text-center text-muted-foreground">Chargement...</div>
              ) : detailClient && (
                <div className="space-y-5">
                  <h2 className="text-xl font-display font-bold text-gradient-primary">
                    Détails du compte — {detailClient.username}
                  </h2>

                  {/* Info grid */}
                  <div className="grid grid-cols-2 gap-3">
                    {[
                      { label: 'Protocole', value: detailClient.protocol?.toUpperCase() },
                      { label: 'Statut',    value: isActive(detailClient) ? '✅ Actif' : '❌ Expiré' },
                      { label: 'Expiration', value: detailClient.expires_at },
                      { label: 'Créé le',   value: detailClient.created_at?.split('T')[0] },
                    ].map(item => (
                      <div key={item.label} className="bg-secondary/20 rounded-lg p-3">
                        <p className="text-[10px] uppercase tracking-widest text-muted-foreground mb-1">{item.label}</p>
                        <p className="text-sm font-mono text-foreground font-semibold">{item.value}</p>
                      </div>
                    ))}
                  </div>

                  {/* Renew */}
                  <div className="border border-border rounded-xl p-4 space-y-3">
                    <h3 className="text-sm font-display font-semibold text-foreground">🔁 Renouveler le compte</h3>
                    {renewError && (
                      <p className="text-xs text-destructive bg-destructive/10 border border-destructive/20 rounded px-3 py-2">{renewError}</p>
                    )}
                    <div className="flex gap-3">
                      <div className="flex-1">
                        <select
                          value={renewDays}
                          onChange={e => setRenewDays(e.target.value)}
                          className="input-dark w-full"
                        >
                          <option value="1">1 Jour</option>
                          <option value="7">7 Jours</option>
                          <option value="30">30 Jours</option>
                          <option value="60">60 Jours</option>
                          <option value="90">90 Jours</option>
                          <option value="180">180 Jours</option>
                          <option value="360">360 Jours</option>
                        </select>
                      </div>
                      <button
                        onClick={handleDetailRenew}
                        disabled={renewLoading}
                        className="btn-primary flex items-center gap-2"
                      >
                        {renewLoading ? <RefreshCw className="w-4 h-4 animate-spin" /> : <RefreshCw className="w-4 h-4" />}
                        Renouveler
                      </button>
                    </div>
                  </div>

                  {/* Reduce days */}
                  <div className="border border-border rounded-xl p-4 space-y-3">
                    <h3 className="text-sm font-display font-semibold text-foreground">➖ Réduire la durée</h3>
                    {reduceError && (
                      <p className="text-xs text-destructive bg-destructive/10 border border-destructive/20 rounded px-3 py-2">{reduceError}</p>
                    )}
                    <div className="flex gap-3">
                      <div className="flex-1">
                        <select
                          value={reduceDays}
                          onChange={e => setReduceDays(e.target.value)}
                          className="input-dark w-full"
                        >
                          <option value="1">1 Jour</option>
                          <option value="7">7 Jours</option>
                          <option value="15">15 Jours</option>
                          <option value="30">30 Jours</option>
                          <option value="60">60 Jours</option>
                          <option value="90">90 Jours</option>
                        </select>
                      </div>
                      <button
                        onClick={handleDetailReduce}
                        disabled={reduceLoading}
                        className="btn-ghost border border-warning/30 text-warning hover:bg-warning/10 flex items-center gap-2"
                      >
                        {reduceLoading ? <MinusCircle className="w-4 h-4 animate-spin" /> : <MinusCircle className="w-4 h-4" />}
                        Réduire
                      </button>
                    </div>
                  </div>

                  {/* Config */}
                  {configLoading ? (
                    <div className="text-center text-muted-foreground text-sm py-4">Génération de la config...</div>
                  ) : configText ? (
                    <ConfigOutput config={configText} protocol={detailClient.protocol as ProtocolType} />
                  ) : null}

                  <div className="flex justify-end gap-3 pt-2">
                    <button
                      onClick={() => { handleDelete(detailClient.id); setDetailClient(null); }}
                      className="btn-ghost text-destructive hover:bg-destructive/10 flex items-center gap-2"
                    >
                      <Trash2 className="w-4 h-4" />
                      Supprimer le compte
                    </button>
                    <button onClick={() => setDetailClient(null)} className="btn-ghost">Fermer</button>
                  </div>
                </div>
              )}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
