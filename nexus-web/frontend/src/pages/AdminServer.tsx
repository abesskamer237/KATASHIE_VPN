import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { motion } from 'framer-motion';

export default function AdminServer() {
  const [config, setConfig] = useState({
    ip: '',
    domain: '',
    nsDomain: '',
    slowdnsPub: '',
    openvpnDownload: '',
  });
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api.getSettings()
      .then(data => {
        if (data?.server) {
          setConfig(prev => ({ ...prev, ...data.server }));
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const updateField = (field: string, value: string) => {
    setConfig(prev => ({ ...prev, [field]: value }));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.updateSettings({ server: config });
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch {}
    setSaving(false);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
        <h1 className="text-2xl font-display font-bold tracking-tight">
          <span className="text-gradient-primary">Configuration Serveur</span>
        </h1>
        <p className="text-muted-foreground text-sm mt-1">Paramètres du serveur VPS</p>
      </motion.div>

      <div className="glass-card p-6 max-w-2xl">
        <div className="space-y-4">
          {[
            { key: 'ip', label: 'Adresse IP', placeholder: '45.41.206.33' },
            { key: 'domain', label: 'Domaine Principal', placeholder: 'joel.camtel.eu.cc' },
            { key: 'nsDomain', label: 'NS Domain', placeholder: 'blue.camtel.eu.cc' },
            { key: 'slowdnsPub', label: 'SlowDNS Public Key', placeholder: 'PUB Key' },
            { key: 'openvpnDownload', label: 'OpenVPN Download URL', placeholder: 'https://...' },
          ].map(({ key, label, placeholder }) => (
            <div key={key}>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">{label}</label>
              <input
                value={(config as any)[key] || ''}
                onChange={e => updateField(key, e.target.value)}
                className="input-dark w-full font-mono"
                placeholder={placeholder}
              />
            </div>
          ))}
        </div>
        <div className="flex items-center gap-3 mt-6">
          <button onClick={handleSave} disabled={saving} className="btn-primary">
            {saving ? 'Sauvegarde...' : 'Sauvegarder'}
          </button>
          {saved && (
            <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-sm text-success">
              ✓ Sauvegardé
            </motion.span>
          )}
        </div>
      </div>
    </div>
  );
}
