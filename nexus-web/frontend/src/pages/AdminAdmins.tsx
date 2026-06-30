import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/lib/auth-context';
import { api } from '@/lib/api';
import { Plus, Trash2, Crown, Shield, UserX, UserCheck, Eye, EyeOff } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface Admin {
  id: string;
  username: string;
  role: string;
  status: string;
  created_at: string;
  isActive: boolean;
}

export default function AdminAdmins() {
  const { user: currentUser } = useAuth();

  const [admins, setAdmins] = useState<Admin[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const isSuperAdmin = currentUser?.role === 'super_admin';

  const loadAdmins = useCallback(async () => {
    setLoadingList(true);
    try {
      const data = await api.listAdmins();
      setAdmins(
        data
          .filter((a: any) => a.role === 'admin' || a.role === 'super_admin')
          .map((a: any) => ({
            id: a.id,
            username: a.username,
            role: a.role,
            status: a.status,
            created_at: a.created_at,
            isActive: a.status === 'active',
          }))
      );
    } catch {}
    setLoadingList(false);
  }, []);

  useEffect(() => { loadAdmins(); }, [loadAdmins]);

  const handleCreate = async () => {
    if (!newName.trim() || !newPassword.trim() || !isSuperAdmin) return;
    setSaving(true);
    setError('');
    try {
      await api.createAdmin({ username: newName, password: newPassword, role: 'admin' });
      setNewName('');
      setNewPassword('');
      setShowCreate(false);
      await loadAdmins();
    } catch (e: any) {
      setError(e.message || 'Erreur lors de la création');
    }
    setSaving(false);
  };

  const handleToggle = async (admin: Admin) => {
    try {
      if (admin.isActive) {
        await api.suspendAdmin(admin.id);
      } else {
        await api.activateAdmin(admin.id);
      }
      await loadAdmins();
    } catch {}
  };

  const handleDelete = async (id: string) => {
    try {
      await api.deleteAdmin(id);
      await loadAdmins();
    } catch {}
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}>
          <h1 className="text-2xl font-display font-bold tracking-tight">
            <span className="text-gradient-primary">Administrateurs</span>
          </h1>
          <p className="text-muted-foreground text-sm mt-1">{admins.length} administrateur(s)</p>
        </motion.div>
        {isSuperAdmin && (
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => { setShowCreate(!showCreate); setError(''); }}
            className="btn-primary flex items-center gap-2 text-sm"
          >
            <Plus className="w-4 h-4" />
            Ajouter Admin
          </motion.button>
        )}
      </div>

      {!isSuperAdmin && (
        <div className="glass-card p-4 border-warning/30 bg-warning/5">
          <p className="text-sm text-warning">⚠️ Seul le Super Admin peut gérer les administrateurs.</p>
        </div>
      )}

      <AnimatePresence>
        {showCreate && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden"
          >
            <div className="glass-card p-6">
              <h3 className="text-lg font-display font-semibold text-foreground mb-4">Nouvel Administrateur</h3>
              {error && (
                <div className="mb-4 text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-lg px-4 py-2">{error}</div>
              )}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-lg">
                <div>
                  <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Nom d'utilisateur</label>
                  <input
                    value={newName}
                    onChange={e => setNewName(e.target.value)}
                    className="input-dark w-full font-mono"
                    placeholder="admin_name"
                  />
                </div>
                <div>
                  <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">Mot de passe</label>
                  <div className="relative">
                    <input
                      type={showPassword ? 'text' : 'password'}
                      value={newPassword}
                      onChange={e => setNewPassword(e.target.value)}
                      className="input-dark w-full font-mono pr-10"
                      placeholder="••••••••"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
              </div>
              <div className="flex gap-3 mt-4">
                <button
                  onClick={handleCreate}
                  className="btn-primary"
                  disabled={!newName.trim() || !newPassword.trim() || saving}
                >
                  {saving ? 'Création...' : "Créer l'Admin"}
                </button>
                <button onClick={() => setShowCreate(false)} className="btn-ghost">Annuler</button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <div className="glass-card overflow-hidden">
        <div className="grid grid-cols-5 gap-4 p-4 border-b border-border text-[10px] uppercase tracking-[0.2em] text-muted-foreground font-semibold">
          <span>Utilisateur</span>
          <span>Rôle</span>
          <span>Statut</span>
          <span>Créé le</span>
          <span className="text-right">Actions</span>
        </div>
        {loadingList ? (
          <div className="p-8 text-center text-muted-foreground">Chargement...</div>
        ) : (
          admins.map((admin, i) => (
            <motion.div
              key={admin.id}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.05 }}
              className="grid grid-cols-5 gap-4 p-4 border-b border-border last:border-0 hover:bg-secondary/20 transition-all items-center"
            >
              <div className="flex items-center gap-2">
                <div
                  className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-display font-bold"
                  style={{
                    background:
                      admin.role === 'super_admin'
                        ? 'linear-gradient(135deg, hsl(38 92% 50%), hsl(25 90% 45%))'
                        : 'var(--gradient-primary)',
                    color: 'white',
                  }}
                >
                  {admin.username.charAt(0).toUpperCase()}
                </div>
                <div>
                  <p className="text-sm font-mono text-foreground font-semibold">{admin.username}</p>
                </div>
              </div>
              <div className="flex items-center gap-1.5">
                {admin.role === 'super_admin' ? (
                  <>
                    <Crown className="w-4 h-4 text-warning" />
                    <span className="text-sm text-warning font-semibold">Super Admin</span>
                  </>
                ) : (
                  <>
                    <Shield className="w-4 h-4 text-primary" />
                    <span className="text-sm text-primary font-semibold">Admin</span>
                  </>
                )}
              </div>
              <div>
                <span className={`protocol-badge ${admin.isActive ? 'border-success/30 text-success bg-success/10' : 'border-destructive/30 text-destructive bg-destructive/10'}`}>
                  {admin.isActive ? 'Actif' : 'Inactif'}
                </span>
              </div>
              <p className="text-sm text-muted-foreground font-mono">{admin.created_at?.split('T')[0] ?? '—'}</p>
              <div className="flex items-center justify-end gap-1">
                {admin.role !== 'super_admin' && isSuperAdmin && (
                  <>
                    <button
                      onClick={() => handleToggle(admin)}
                      className={`p-2 rounded-lg transition-colors ${admin.isActive ? 'hover:bg-warning/10 text-warning' : 'hover:bg-success/10 text-success'}`}
                    >
                      {admin.isActive ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                    </button>
                    <button
                      onClick={() => handleDelete(admin.id)}
                      className="p-2 rounded-lg hover:bg-destructive/10 text-destructive transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </>
                )}
                {admin.role === 'super_admin' && (
                  <span className="text-xs text-muted-foreground italic">Non supprimable</span>
                )}
              </div>
            </motion.div>
          ))
        )}
        {!loadingList && admins.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">Aucun administrateur trouvé</div>
        )}
      </div>
    </div>
  );
}
