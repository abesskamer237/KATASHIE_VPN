import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/lib/auth-context';
import { api } from '@/lib/api';
import { protocols } from '@/lib/mock-data';
import { Plus, Trash2, UserCheck, UserX, Eye, EyeOff, Search, Pencil, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface Reseller {
  id: string;
  username: string;
  role: string;
  status: string;
  created_at: string;
  expiry_date?: string;
  bouquet?: Array<{ protocolId: string; maxAccounts: number; usedAccounts?: number }>;
  isActive: boolean;
}

function mapReseller(r: any): Reseller {
  let bouquet: Array<{ protocolId: string; maxAccounts: number; usedAccounts?: number }> = [];
  try {
    bouquet = typeof r.bouquet === 'string' ? JSON.parse(r.bouquet || '[]') : (r.bouquet ?? []);
  } catch {}
  return {
    id: r.id,
    username: r.username,
    role: r.role,
    status: r.status,
    created_at: r.created_at,
    expiry_date: r.expiry_date,
    bouquet,
    isActive: r.status === 'active',
  };
}

export default function AdminResellers() {
  const { user: currentUser } = useAuth();

  const [resellers, setResellers] = useState<Reseller[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [newDuration, setNewDuration] = useState('30');
  const [customDuration, setCustomDuration] = useState('');
  const [useCustomDuration, setUseCustomDuration] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'inactive'>('all');
  const [selectedProtocols, setSelectedProtocols] = useState<Record<string, boolean>>({});
  const [protocolLimits, setProtocolLimits] = useState<Record<string, number>>({});
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  // Edit modal
  const [editReseller, setEditReseller] = useState<Reseller | null>(null);
  const [editBouquet, setEditBouquet] = useState<Record<string, boolean>>({});
  const [editLimits, setEditLimits] = useState<Record<string, number>>({});
  const [editDuration, setEditDuration] = useState('30');
  const [editPassword, setEditPassword] = useState('');
  const [editSaving, setEditSaving] = useState(false);
  const [editError, setEditError] = useState('');

  const loadResellers = useCallback(async () => {
    setLoadingList(true);
    try {
      const data = await api.listResellers();
      setResellers(data.map(mapReseller));
    } catch {}
    setLoadingList(false);
  }, []);

  useEffect(() => { loadResellers(); }, [loadResellers]);

  const toggleProtocol = (id: string) => {
    setSelectedProtocols(prev => ({ ...prev, [id]: !prev[id] }));
  };

  const setLimit = (id: string, limit: number) => {
    setProtocolLimits(prev => ({ ...prev, [id]: limit }));
  };

  const handleCreate = async () => {
    if (!newName.trim() || !newPassword.trim()) return;
    setSaving(true);
    setError('');
    const days = useCustomDuration ? parseInt(customDuration) || 30 : parseInt(newDuration);
    const bouquet = protocols
      .filter(p => selectedProtocols[p.id])
      .map(p => ({ protocolId: p.id, maxAccounts: protocolLimits[p.id] || 10 }));
    try {
      await api.createReseller({ username: newName, password: newPassword, duration_days: days, bouquet });
      setNewName('');
      setNewPassword('');
      setShowCreate(false);
      setSelectedProtocols({});
      setProtocolLimits({});
      await loadResellers();
    } catch (e: any) {
      setError(e.message || 'Erreur lors de la création');
    }
    setSaving(false);
  };

  const handleToggle = async (reseller: Reseller) => {
    try {
      if (reseller.isActive) {
        await api.suspendReseller(reseller.id);
      } else {
        await api.activateReseller(reseller.id);
      }
      await loadResellers();
    } catch {}
  };

  const handleDelete = async (id: string) => {
    try {
      await api.deleteReseller(id);
      await loadResellers();
    } catch {}
  };

  const openEdit = (reseller: Reseller) => {
    setEditReseller(reseller);
    setEditError('');
    setEditPassword('');
    setEditDuration('30');
    // Pre-populate bouquet
    const bq: Record<string, boolean> = {};
    const lm: Record<string, number> = {};
    reseller.bouquet?.forEach(b => {
      bq[b.protocolId] = true;
      lm[b.protocolId] = b.maxAccounts;
    });
    setEditBouquet(bq);
    setEditLimits(lm);
  };

  const handleEdit = async () => {
    if (!editReseller) return;
    setEditSaving(true);
    setEditError('');
    const bouquet = protocols
      .filter(p => editBouquet[p.id])
      .map(p => ({ protocolId: p.id, maxAccounts: editLimits[p.id] || 10 }));
    const payload: any = { bouquet };
    if (editDuration && parseInt(editDuration) > 0) payload.duration_days = parseInt(editDuration);
    if (editPassword.trim()) payload.password = editPassword.trim();
    try {
      await api.updateReseller(editReseller.id, payload);
      setEditReseller(null);
      await loadResellers();
    } catch (e: any) {
      setEditError(e.message || 'Erreur lors de la modification');
    }
    setEditSaving(false);
  };

  const filtered = resellers.filter(r => {
    const matchSearch = r.username.toLowerCase().includes(searchQuery.toLowerCase());
    const matchStatus =
      filterStatus === 'all' ||
      (filterStatus === 'active' ? r.isActive : !r.isActive);
    return matchSearch && matchStatus;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
          <h1 className="text-2xl font-display font-bold tracking-tight">
            <span className="text-gradient-primary">Gestion Revendeurs</span>
          </h1>
          <p className="text-muted-foreground text-sm mt-1">{resellers.length} revendeurs enregistrés</p>
        </motion.div>
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={() => { setShowCreate(!showCreate); setError(''); }}
          className="btn-primary flex items-center gap-2 text-sm"
        >
          <Plus className="w-4 h-4" />
          Ajouter Revendeur
        </motion.button>
      </div>

      {/* Create Form */}
      <AnimatePresence>
        {showCreate && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden"
          >
            <div className="glass-card p-6">
              <h3 className="text-lg font-display font-semibold text-foreground mb-4">Nouveau Revendeur</h3>
              {error && (
                <div className="mb-4 text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-lg px-4 py-2">{error}</div>
              )}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <div>
                  <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Nom d'utilisateur</label>
                  <input value={newName} onChange={e => setNewName(e.target.value)} className="input-dark w-full font-mono" placeholder="reseller_name" />
                </div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Mot de passe</label>
                  <div className="relative">
                    <input
                      type={showNewPassword ? 'text' : 'password'}
                      value={newPassword}
                      onChange={e => setNewPassword(e.target.value)}
                      className="input-dark w-full font-mono pr-10"
                      placeholder="••••••••"
                    />
                    <button type="button" onClick={() => setShowNewPassword(!showNewPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground">
                      {showNewPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Durée du compte</label>
                  {useCustomDuration ? (
                    <div className="flex gap-2">
                      <input
                        type="number"
                        value={customDuration}
                        onChange={e => setCustomDuration(e.target.value)}
                        className="input-dark w-full font-mono"
                        placeholder="Jours"
                        min="1"
                      />
                      <button onClick={() => setUseCustomDuration(false)} className="btn-ghost text-xs whitespace-nowrap">Standard</button>
                    </div>
                  ) : (
                    <div className="flex gap-2">
                      <select value={newDuration} onChange={e => setNewDuration(e.target.value)} className="input-dark w-full">
                        <option value="1">1 Jour</option>
                        <option value="7">7 Jours</option>
                        <option value="30">30 Jours</option>
                        <option value="60">60 Jours</option>
                        <option value="90">90 Jours</option>
                        <option value="180">180 Jours</option>
                        <option value="360">360 Jours</option>
                      </select>
                      <button onClick={() => setUseCustomDuration(true)} className="btn-ghost text-xs whitespace-nowrap">Custom</button>
                    </div>
                  )}
                </div>
              </div>

              {/* Bouquet */}
              <div className="mt-6">
                <label className="text-xs uppercase tracking-widest text-muted-foreground mb-3 block font-semibold">
                  🎯 Bouquet — Protocoles attribués
                </label>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {protocols.filter(p => p.isEnabled).map(proto => (
                    <div
                      key={proto.id}
                      className={`rounded-xl border p-3 transition-all cursor-pointer ${
                        selectedProtocols[proto.id]
                          ? 'border-primary/50 bg-primary/10'
                          : 'border-border bg-card/30 hover:border-border hover:bg-secondary/20'
                      }`}
                      onClick={() => toggleProtocol(proto.id)}
                    >
                      <div className="flex items-center gap-2 mb-2">
                        <span className="text-lg">{proto.icon}</span>
                        <span className="text-sm font-semibold text-foreground">{proto.name}</span>
                      </div>
                      {selectedProtocols[proto.id] && (
                        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} onClick={e => e.stopPropagation()}>
                          <label className="text-[10px] text-muted-foreground mb-1 block">Max comptes</label>
                          <input
                            type="number"
                            value={protocolLimits[proto.id] || 10}
                            onChange={e => setLimit(proto.id, parseInt(e.target.value) || 0)}
                            className="input-dark w-full text-xs py-1.5 px-2"
                            min="1"
                          />
                        </motion.div>
                      )}
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  onClick={handleCreate}
                  className="btn-primary"
                  disabled={!newName.trim() || !newPassword.trim() || saving}
                >
                  {saving ? 'Création...' : 'Créer le Revendeur'}
                </button>
                <button onClick={() => setShowCreate(false)} className="btn-ghost">Annuler</button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Search & Filters */}
      <div className="flex gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="input-dark w-full pl-10"
            placeholder="Rechercher un revendeur..."
          />
        </div>
        <select
          value={filterStatus}
          onChange={e => setFilterStatus(e.target.value as any)}
          className="input-dark w-40"
        >
          <option value="all">Tous</option>
          <option value="active">Actifs</option>
          <option value="inactive">Inactifs</option>
        </select>
      </div>

      {/* Resellers Table */}
      <div className="glass-card overflow-hidden">
        <div className="grid grid-cols-6 gap-4 p-4 border-b border-border text-[10px] uppercase tracking-[0.2em] text-muted-foreground font-semibold">
          <span>Utilisateur</span>
          <span>Statut</span>
          <span>Bouquet</span>
          <span>Expiration</span>
          <span>Créé le</span>
          <span className="text-right">Actions</span>
        </div>
        {loadingList ? (
          <div className="p-8 text-center text-muted-foreground">Chargement...</div>
        ) : (
          <AnimatePresence>
            {filtered.map((reseller, i) => (
              <motion.div
                key={reseller.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0 }}
                transition={{ delay: i * 0.03 }}
                className="grid grid-cols-6 gap-4 p-4 border-b border-border last:border-0 hover:bg-secondary/20 transition-all items-center"
              >
                <div>
                  <p className="text-sm font-mono text-foreground font-semibold">{reseller.username}</p>
                  <p className="text-xs text-muted-foreground">ID: {reseller.id.slice(0, 8)}</p>
                </div>
                <div>
                  <span className={`protocol-badge ${reseller.isActive ? 'border-success/30 text-success bg-success/10' : 'border-destructive/30 text-destructive bg-destructive/10'}`}>
                    {reseller.isActive ? 'Actif' : 'Inactif'}
                  </span>
                </div>
                <div className="flex flex-wrap gap-1">
                  {reseller.bouquet?.slice(0, 3).map(b => (
                    <span key={b.protocolId} className="text-[10px] px-1.5 py-0.5 rounded bg-primary/10 text-primary border border-primary/20">
                      {b.protocolId.toUpperCase()}
                    </span>
                  ))}
                  {(reseller.bouquet?.length || 0) > 3 && (
                    <span className="text-[10px] text-muted-foreground">+{(reseller.bouquet?.length || 0) - 3}</span>
                  )}
                  {!reseller.bouquet?.length && <span className="text-xs text-muted-foreground">—</span>}
                </div>
                <p className="text-sm text-muted-foreground font-mono">{reseller.expiry_date ?? '—'}</p>
                <p className="text-sm text-muted-foreground font-mono">{reseller.created_at?.split('T')[0] ?? '—'}</p>
                <div className="flex items-center justify-end gap-1">
                  <button
                    onClick={() => openEdit(reseller)}
                    className="p-2 rounded-lg hover:bg-accent/10 text-accent transition-colors"
                    title="Modifier"
                  >
                    <Pencil className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleToggle(reseller)}
                    className={`p-2 rounded-lg transition-colors ${reseller.isActive ? 'hover:bg-warning/10 text-warning' : 'hover:bg-success/10 text-success'}`}
                    title={reseller.isActive ? 'Désactiver' : 'Activer'}
                  >
                    {reseller.isActive ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                  </button>
                  <button
                    onClick={() => handleDelete(reseller.id)}
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
          <div className="p-8 text-center text-muted-foreground">Aucun revendeur trouvé</div>
        )}
      </div>

      {/* Edit Modal */}
      <AnimatePresence>
        {editReseller && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4"
            onClick={e => { if (e.target === e.currentTarget) setEditReseller(null); }}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="glass-card w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6 relative"
            >
              <button
                onClick={() => setEditReseller(null)}
                className="absolute top-4 right-4 p-1.5 rounded-lg hover:bg-secondary/50 text-muted-foreground"
              >
                <X className="w-5 h-5" />
              </button>

              <h2 className="text-xl font-display font-bold text-gradient-primary mb-5">
                Modifier — {editReseller.username}
              </h2>

              {editError && (
                <div className="mb-4 text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-lg px-4 py-2">{editError}</div>
              )}

              <div className="space-y-5">
                {/* Bouquet */}
                <div>
                  <label className="text-xs uppercase tracking-widest text-muted-foreground mb-3 block font-semibold">
                    🎯 Bouquet — Protocoles attribués
                  </label>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                    {protocols.filter(p => p.isEnabled).map(proto => (
                      <div
                        key={proto.id}
                        className={`rounded-xl border p-3 transition-all cursor-pointer ${
                          editBouquet[proto.id]
                            ? 'border-primary/50 bg-primary/10'
                            : 'border-border bg-card/30 hover:border-border hover:bg-secondary/20'
                        }`}
                        onClick={() => setEditBouquet(prev => ({ ...prev, [proto.id]: !prev[proto.id] }))}
                      >
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-base">{proto.icon}</span>
                          <span className="text-sm font-semibold text-foreground">{proto.name}</span>
                        </div>
                        {editBouquet[proto.id] && (
                          <div onClick={e => e.stopPropagation()}>
                            <label className="text-[10px] text-muted-foreground mb-1 block">Max comptes</label>
                            <input
                              type="number"
                              value={editLimits[proto.id] || 10}
                              onChange={e => setEditLimits(prev => ({ ...prev, [proto.id]: parseInt(e.target.value) || 0 }))}
                              className="input-dark w-full text-xs py-1.5 px-2"
                              min="1"
                            />
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Duration / Credits / Password */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">
                      Prolonger de (jours)
                    </label>
                    <select value={editDuration} onChange={e => setEditDuration(e.target.value)} className="input-dark w-full">
                      <option value="">Ne pas modifier</option>
                      <option value="7">+7 Jours</option>
                      <option value="30">+30 Jours</option>
                      <option value="60">+60 Jours</option>
                      <option value="90">+90 Jours</option>
                      <option value="180">+180 Jours</option>
                      <option value="360">+360 Jours</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">
                      Nouveau mot de passe
                    </label>
                    <input
                      type="password"
                      value={editPassword}
                      onChange={e => setEditPassword(e.target.value)}
                      className="input-dark w-full font-mono"
                      placeholder="Laisser vide = inchangé"
                    />
                  </div>
                </div>

                <div className="flex gap-3 pt-2">
                  <button onClick={handleEdit} disabled={editSaving} className="btn-primary">
                    {editSaving ? 'Enregistrement...' : 'Enregistrer les modifications'}
                  </button>
                  <button onClick={() => setEditReseller(null)} className="btn-ghost">Annuler</button>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
