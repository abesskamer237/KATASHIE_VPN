import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { Settings, Globe, Shield, Bell, Server } from 'lucide-react';
import { motion } from 'framer-motion';

const DEFAULT_SETTINGS = {
  siteName: 'Nexus Pro',
  sitePort: 2087,
  primaryColor: '270 100% 65%',
  accentColor: '320 100% 60%',
  logoText: 'N',
  footerText: 'Nexus Pro VPN Panel',
  maintenanceMode: false,
  registrationEnabled: false,
  maxResellersPerAdmin: 10,
  defaultResellerDuration: 30,
  telegramBot: '',
  telegramChannel: '',
  server: { ip: '', domain: '', nsDomain: '', slowdnsPub: '', openvpnDownload: '' },
};

export default function AdminSettings() {
  const [settings, setSettings] = useState(DEFAULT_SETTINGS);
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api.getSettings()
      .then(data => {
        setSettings(prev => ({ ...prev, ...data }));
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const update = (field: string, value: any) => {
    setSettings(prev => ({ ...prev, [field]: value }));
  };

  const updateConfig = (field: string, value: string) => {
    setSettings(prev => ({ ...prev, server: { ...prev.server, [field]: value } }));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.updateSettings(settings);
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

  const serverFields = [
    { key: 'ip', label: 'Adresse IP' },
    { key: 'domain', label: 'Domaine Principal' },
    { key: 'nsDomain', label: 'NS Domain' },
    { key: 'slowdnsPub', label: 'SlowDNS Public Key' },
    { key: 'openvpnDownload', label: 'OpenVPN Download URL' },
  ];

  return (
    <div className="space-y-6">
      <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
        <h1 className="text-2xl font-display font-bold tracking-tight">
          <span className="text-gradient-primary">Paramètres</span>
        </h1>
        <p className="text-muted-foreground text-sm mt-1">Configuration générale du panel</p>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Server Config */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="glass-card p-6">
          <h3 className="text-lg font-display font-semibold text-foreground mb-4 flex items-center gap-2">
            <Server className="w-5 h-5 text-primary" />
            Serveur VPS
          </h3>
          <div className="space-y-4">
            {serverFields.map(({ key, label }) => (
              <div key={key}>
                <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">{label}</label>
                <input
                  value={(settings.server as any)[key] || ''}
                  onChange={e => updateConfig(key, e.target.value)}
                  className="input-dark w-full font-mono"
                />
              </div>
            ))}
          </div>
        </motion.div>

        {/* General Settings */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="glass-card p-6">
          <h3 className="text-lg font-display font-semibold text-foreground mb-4 flex items-center gap-2">
            <Settings className="w-5 h-5 text-accent" />
            Général
          </h3>
          <div className="space-y-4">
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Nom du Site</label>
              <input
                value={settings.siteName}
                onChange={e => update('siteName', e.target.value)}
                className="input-dark w-full font-mono"
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Port du Site</label>
              <input
                type="number"
                value={settings.sitePort}
                onChange={e => update('sitePort', parseInt(e.target.value))}
                className="input-dark w-full font-mono"
              />
              <p className="text-xs text-muted-foreground mt-1">Port personnalisé pour accéder au panel</p>
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Max Revendeurs par Admin</label>
              <input
                type="number"
                value={settings.maxResellersPerAdmin}
                onChange={e => update('maxResellersPerAdmin', parseInt(e.target.value))}
                className="input-dark w-full font-mono"
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Durée par défaut (jours)</label>
              <input
                type="number"
                value={settings.defaultResellerDuration}
                onChange={e => update('defaultResellerDuration', parseInt(e.target.value))}
                className="input-dark w-full font-mono"
              />
            </div>
          </div>
        </motion.div>

        {/* Security */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="glass-card p-6">
          <h3 className="text-lg font-display font-semibold text-foreground mb-4 flex items-center gap-2">
            <Shield className="w-5 h-5 text-success" />
            Sécurité
          </h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-foreground">Mode Maintenance</p>
                <p className="text-xs text-muted-foreground">Désactive l'accès aux revendeurs</p>
              </div>
              <button
                onClick={() => update('maintenanceMode', !settings.maintenanceMode)}
                className={`relative w-12 h-6 rounded-full transition-all ${settings.maintenanceMode ? 'bg-gradient-primary' : 'bg-secondary'}`}
              >
                <span className={`absolute top-0.5 w-5 h-5 rounded-full bg-foreground transition-transform ${settings.maintenanceMode ? 'left-6' : 'left-0.5'}`} />
              </button>
            </div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-foreground">Inscription Revendeurs</p>
                <p className="text-xs text-muted-foreground">Autoriser l'auto-inscription</p>
              </div>
              <button
                onClick={() => update('registrationEnabled', !settings.registrationEnabled)}
                className={`relative w-12 h-6 rounded-full transition-all ${settings.registrationEnabled ? 'bg-gradient-primary' : 'bg-secondary'}`}
              >
                <span className={`absolute top-0.5 w-5 h-5 rounded-full bg-foreground transition-transform ${settings.registrationEnabled ? 'left-6' : 'left-0.5'}`} />
              </button>
            </div>
          </div>
        </motion.div>

        {/* Telegram */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="glass-card p-6">
          <h3 className="text-lg font-display font-semibold text-foreground mb-4 flex items-center gap-2">
            <Bell className="w-5 h-5 text-warning" />
            Intégrations
          </h3>
          <div className="space-y-4">
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Bot Telegram Token</label>
              <input
                value={settings.telegramBot}
                onChange={e => update('telegramBot', e.target.value)}
                className="input-dark w-full font-mono"
                placeholder="123456:ABC-DEF..."
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Channel Telegram</label>
              <input
                value={settings.telegramChannel}
                onChange={e => update('telegramChannel', e.target.value)}
                className="input-dark w-full font-mono"
                placeholder="@my_channel"
              />
            </div>
          </div>
        </motion.div>
      </div>

      <div className="flex items-center gap-3">
        <button onClick={handleSave} disabled={saving} className="btn-primary">
          {saving ? 'Sauvegarde...' : 'Sauvegarder les Paramètres'}
        </button>
        {saved && (
          <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-sm text-success">
            ✓ Paramètres sauvegardés
          </motion.span>
        )}
      </div>
    </div>
  );
}
