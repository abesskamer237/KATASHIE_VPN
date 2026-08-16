import { useState } from 'react';
import { defaultSiteSettings } from '@/lib/mock-data';
import { Palette, Monitor, Type } from 'lucide-react';
import { motion } from 'framer-motion';

export default function AdminAppearance() {
  const [settings, setSettings] = useState(defaultSiteSettings);
  const [saved, setSaved] = useState(false);

  const update = (field: string, value: any) => {
    setSettings(prev => ({ ...prev, [field]: value }));
    setSaved(false);
  };

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div className="space-y-6">
      <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
        <h1 className="text-2xl font-display font-bold tracking-tight">
          <span className="text-gradient-primary">Apparence du Site</span>
        </h1>
        <p className="text-muted-foreground text-sm mt-1">Personnaliser le thème et l'identité visuelle</p>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Branding */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="glass-card p-6">
          <h3 className="text-lg font-display font-semibold text-foreground mb-4 flex items-center gap-2">
            <Type className="w-5 h-5 text-primary" />
            Identité
          </h3>
          <div className="space-y-4">
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Nom du site</label>
              <input value={settings.siteName} onChange={e => update('siteName', e.target.value)} className="input-dark w-full" />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Texte du logo</label>
              <input value={settings.logoText} onChange={e => update('logoText', e.target.value)} className="input-dark w-full font-display" />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Texte du pied de page</label>
              <input value={settings.footerText} onChange={e => update('footerText', e.target.value)} className="input-dark w-full" />
            </div>
          </div>
        </motion.div>

        {/* Colors */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="glass-card p-6">
          <h3 className="text-lg font-display font-semibold text-foreground mb-4 flex items-center gap-2">
            <Palette className="w-5 h-5 text-accent" />
            Couleurs
          </h3>
          <div className="space-y-4">
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Couleur Primaire</label>
              <div className="flex items-center gap-3">
                <input type="color" value={settings.primaryColor} onChange={e => update('primaryColor', e.target.value)}
                  className="w-12 h-10 rounded-lg border border-border cursor-pointer" />
                <input value={settings.primaryColor} onChange={e => update('primaryColor', e.target.value)}
                  className="input-dark flex-1 font-mono" />
              </div>
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Couleur d'Accent</label>
              <div className="flex items-center gap-3">
                <input type="color" value={settings.accentColor} onChange={e => update('accentColor', e.target.value)}
                  className="w-12 h-10 rounded-lg border border-border cursor-pointer" />
                <input value={settings.accentColor} onChange={e => update('accentColor', e.target.value)}
                  className="input-dark flex-1 font-mono" />
              </div>
            </div>
          </div>

          {/* Preview */}
          <div className="mt-4 p-4 rounded-xl border border-border bg-background/50">
            <p className="text-xs text-muted-foreground mb-2 font-semibold uppercase tracking-widest">Aperçu</p>
            <div className="flex gap-3 items-center">
              <div className="w-10 h-10 rounded-xl" style={{ background: `linear-gradient(135deg, ${settings.primaryColor}, ${settings.accentColor})` }} />
              <div>
                <p className="font-display font-bold" style={{ color: settings.primaryColor }}>{settings.logoText}</p>
                <p className="text-xs text-muted-foreground">{settings.siteName}</p>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Preview Panel */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="glass-card p-6 lg:col-span-2">
          <h3 className="text-lg font-display font-semibold text-foreground mb-4 flex items-center gap-2">
            <Monitor className="w-5 h-5 text-primary" />
            Aperçu Complet
          </h3>
          <div className="rounded-xl border border-border bg-background/80 p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 rounded-xl flex items-center justify-center font-display font-black text-white text-xl"
                style={{ background: `linear-gradient(135deg, ${settings.primaryColor}, ${settings.accentColor})` }}>
                {settings.logoText.charAt(0)}
              </div>
              <div>
                <h4 className="font-display font-bold text-lg" style={{ color: settings.primaryColor }}>{settings.logoText}</h4>
                <p className="text-xs text-muted-foreground">{settings.siteName}</p>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-3 mb-4">
              {['Dashboard', 'Revendeurs', 'Protocoles'].map(label => (
                <div key={label} className="p-3 rounded-lg border border-border text-center text-sm text-muted-foreground hover:border-primary/30 transition-colors cursor-pointer">
                  {label}
                </div>
              ))}
            </div>
            <div className="p-3 rounded-lg text-center text-sm"
              style={{ background: `linear-gradient(135deg, ${settings.primaryColor}, ${settings.accentColor})`, color: 'white' }}>
              Bouton Primaire
            </div>
            <p className="text-center text-xs text-muted-foreground mt-4">{settings.footerText}</p>
          </div>
        </motion.div>
      </div>

      <div className="flex items-center gap-3">
        <button onClick={handleSave} className="btn-primary">Sauvegarder les Modifications</button>
        {saved && (
          <motion.span initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-sm text-success">
            ✓ Modifications sauvegardées
          </motion.span>
        )}
      </div>
    </div>
  );
}
