import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import { api } from '@/lib/api';
import { protocols } from '@/lib/mock-data';
import { ProtocolType } from '@/lib/types';
import { formatConfig } from '@/lib/config-formatter';
import ConfigOutput from '@/components/ConfigOutput';
import { Loader2, Lock, AlertTriangle } from 'lucide-react';
import { motion } from 'framer-motion';

// Maximum tolerated clock skew between client and server (in seconds)
const MAX_CLOCK_SKEW_SECONDS = 300; // 5 minutes

export default function ResellerCreateAccount() {
  const { user, refreshUser } = useAuth();
  const [selectedProtocol, setSelectedProtocol] = useState<ProtocolType>('ssh');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [duration, setDuration] = useState('1');
  const [customDuration, setCustomDuration] = useState('');
  const [useCustomDuration, setUseCustomDuration] = useState(false);
  const [loading, setLoading] = useState(false);
  const [generatedConfig, setGeneratedConfig] = useState('');
  const [error, setError] = useState('');
  const [serverUnix, setServerUnix] = useState<number | null>(null);
  const [clockSkewError, setClockSkewError] = useState('');

  // Fetch server time on mount and validate client clock
  useEffect(() => {
    api.getServerTime().then(({ unix }) => {
      setServerUnix(unix);
      const clientUnix = Math.floor(Date.now() / 1000);
      const skew = Math.abs(clientUnix - unix);
      if (skew > MAX_CLOCK_SKEW_SECONDS) {
        setClockSkewError(
          `⚠️ Veuillez régler la date et l'heure de votre téléphone. L'écart détecté (${skew}s) est trop important par rapport à l'heure du serveur.`
        );
      } else {
        setClockSkewError('');
      }
    }).catch(() => {});
  }, []);

  const allowedProtocols = user?.bouquet?.map(b => b.protocolId) || [];
  const availableProtocols = protocols.filter(
    p => p.isEnabled && (allowedProtocols.length === 0 || allowedProtocols.includes(p.id))
  );

  const currentQuota = user?.bouquet?.find(b => b.protocolId === selectedProtocol);
  const canCreate = !currentQuota || (currentQuota.usedAccounts || 0) < currentQuota.maxAccounts;

  // Cap duration at the reseller's remaining days (server-side enforced)
  const remainingDays = user?.remainingDays ?? 9999;
  const NO_EXPIRY = remainingDays >= 9999;
  const requestedDays = useCustomDuration ? (parseInt(customDuration) || 1) : parseInt(duration);
  const effectiveDays = NO_EXPIRY ? requestedDays : Math.min(requestedDays, remainingDays);

  const handleGenerate = async () => {
    if (!username.trim() || !password.trim() || !canCreate) return;

    // Block if clock is too far off from server
    if (clockSkewError) {
      setError(clockSkewError);
      return;
    }

    // Re-check server time before creating (belt and suspenders)
    try {
      const { unix } = await api.getServerTime();
      const clientUnix = Math.floor(Date.now() / 1000);
      if (Math.abs(clientUnix - unix) > MAX_CLOCK_SKEW_SECONDS) {
        setError(`⚠️ Veuillez régler la date et l'heure de votre téléphone. Création refusée.`);
        return;
      }
    } catch {
      // If server-time fetch fails, proceed (server will enforce anyway)
    }

    setLoading(true);
    setGeneratedConfig('');
    setError('');

    const days = Math.max(1, effectiveDays);

    try {
      const result = await api.createClient({
        username,
        password,
        protocol: selectedProtocol,
        days,
      });

      // Build config from result
      const serverSettings = { ip: '', domain: '', nsDomain: '', slowdnsPub: '', openvpnDownload: '' };
      try {
        const s = await api.getSettings();
        if (s?.server) Object.assign(serverSettings, s.server);
      } catch {}

      // Use server-returned expiry date to prevent client clock manipulation
      const expiryStr = result.expires_at
        ? new Date(result.expires_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
        : new Date((serverUnix ? serverUnix * 1000 : Date.now()) + days * 86400000).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

      const config = formatConfig(
        { username, password, expiryDate: expiryStr, protocol: selectedProtocol, ...result.account_data },
        serverSettings,
      );
      setGeneratedConfig(config);

      // Refresh user to update quota counters
      await refreshUser();
    } catch (e: any) {
      setError(e.message || 'Erreur lors de la création du compte');
    }
    setLoading(false);
  };

  return (
    <div className="space-y-6">
      <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
        <h1 className="text-2xl font-display font-bold tracking-tight">
          <span className="text-gradient-primary">Créer un Compte VPN</span>
        </h1>
        <p className="text-muted-foreground text-sm mt-1">Sélectionnez un protocole et générez les identifiants</p>
      </motion.div>

      {/* Clock skew warning */}
      {clockSkewError && (
        <div className="flex items-start gap-3 text-sm text-amber-600 bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 dark:bg-amber-900/20 dark:border-amber-800 dark:text-amber-400">
          <AlertTriangle className="w-5 h-5 flex-shrink-0 mt-0.5" />
          <span>{clockSkewError}</span>
        </div>
      )}

      {/* Protocol Selector */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {availableProtocols.map((proto, i) => {
          const quota = user?.bouquet?.find(b => b.protocolId === proto.id);
          const remaining = quota ? quota.maxAccounts - (quota.usedAccounts || 0) : '∞';
          return (
            <motion.button
              key={proto.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              onClick={() => setSelectedProtocol(proto.id as ProtocolType)}
              className={`p-4 rounded-xl border transition-all text-left relative overflow-hidden ${
                selectedProtocol === proto.id
                  ? 'border-primary/50 bg-primary/10'
                  : 'border-border bg-card/50 hover:border-border hover:bg-secondary/30'
              }`}
            >
              {selectedProtocol === proto.id && (
                <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-primary" />
              )}
              <span className="text-2xl block mb-2">{proto.icon}</span>
              <p className="text-sm font-display font-bold text-foreground">{proto.name}</p>
              <p className="text-xs text-muted-foreground mt-0.5">{remaining} restants</p>
            </motion.button>
          );
        })}
      </div>

      {availableProtocols.length === 0 && (
        <div className="glass-card p-8 text-center">
          <Lock className="w-8 h-8 text-muted-foreground mx-auto mb-3" />
          <p className="text-muted-foreground">Aucun protocole dans votre bouquet.</p>
        </div>
      )}

      {/* Form */}
      {availableProtocols.length > 0 && (
        <div className="glass-card p-6">
          <h2 className="text-lg font-display font-semibold text-foreground mb-4">
            Compte {protocols.find(p => p.id === selectedProtocol)?.name}
            {!canCreate && <span className="text-xs text-destructive ml-2">(Quota atteint)</span>}
          </h2>
          {error && (
            <div className="mb-4 text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-lg px-4 py-2">{error}</div>
          )}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Nom d'utilisateur</label>
              <input
                value={username}
                onChange={e => setUsername(e.target.value)}
                className="input-dark w-full font-mono"
                placeholder="username"
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Mot de passe</label>
              <input
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="input-dark w-full font-mono"
                placeholder="password"
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">
                Validité
                {!NO_EXPIRY && (
                  <span className="ml-1 text-muted-foreground normal-case font-normal">(max {remainingDays}j)</span>
                )}
              </label>
              {useCustomDuration ? (
                <div className="flex gap-2">
                  <input
                    type="number"
                    value={customDuration}
                    onChange={e => setCustomDuration(e.target.value)}
                    className="input-dark w-full font-mono"
                    placeholder="Jours"
                    min="1"
                    max={NO_EXPIRY ? undefined : remainingDays}
                  />
                  <button onClick={() => setUseCustomDuration(false)} className="btn-ghost text-xs whitespace-nowrap">Standard</button>
                </div>
              ) : (
                <div className="flex gap-2">
                  <select value={duration} onChange={e => setDuration(e.target.value)} className="input-dark w-full">
                    {[1, 7, 30, 60, 90, 180, 360].filter(d => NO_EXPIRY || d <= remainingDays).map(d => (
                      <option key={d} value={String(d)}>{d} {d === 1 ? 'Jour' : 'Jours'}</option>
                    ))}
                    {!NO_EXPIRY && remainingDays > 0 && ![1, 7, 30, 60, 90, 180, 360].includes(remainingDays) && (
                      <option value={String(remainingDays)}>{remainingDays} Jours (max)</option>
                    )}
                  </select>
                  <button onClick={() => setUseCustomDuration(true)} className="btn-ghost text-xs whitespace-nowrap">Custom</button>
                </div>
              )}
            </div>
          </div>
          <button
            onClick={handleGenerate}
            disabled={loading || !username.trim() || !password.trim() || !canCreate || !!clockSkewError}
            className="btn-primary w-full mt-6 disabled:opacity-50 flex items-center justify-center gap-2 text-base tracking-wider"
          >
            {loading ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Création en cours...
              </>
            ) : 'GÉNÉRER LES IDENTIFIANTS'}
          </button>
        </div>
      )}

      {generatedConfig && <ConfigOutput config={generatedConfig} protocol={selectedProtocol} />}
    </div>
  );
}
