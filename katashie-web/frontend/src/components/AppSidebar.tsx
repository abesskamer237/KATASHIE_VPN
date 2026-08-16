import { useAuth } from '@/lib/auth-context';
import { useLocation, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  LayoutDashboard, Users, Settings, LogOut,
  Zap, Server, CreditCard, UserPlus, Palette, Shield, Crown
} from 'lucide-react';

const adminLinks = [
  { to: '/admin', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/admin/resellers', icon: Users, label: 'Revendeurs' },
  { to: '/admin/admins', icon: Crown, label: 'Administrateurs' },
  { to: '/admin/create', icon: UserPlus, label: 'Créer un Compte' },
  { to: '/admin/accounts', icon: CreditCard, label: 'Tous les Comptes' },
  { to: '/admin/protocols', icon: Zap, label: 'Protocoles' },
  { to: '/admin/server', icon: Server, label: 'Serveur' },
  { to: '/admin/appearance', icon: Palette, label: 'Apparence' },
  { to: '/admin/settings', icon: Settings, label: 'Paramètres' },
];

const resellerLinks = [
  { to: '/reseller', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/reseller/create', icon: Zap, label: 'Créer un Compte' },
  { to: '/reseller/accounts', icon: CreditCard, label: 'Mes Comptes' },
];

export default function AppSidebar() {
  const { user, logout } = useAuth();
  const location = useLocation();

  const isAdmin = user?.role === 'admin' || user?.role === 'super_admin';
  const links = isAdmin ? adminLinks : resellerLinks;

  return (
    <aside className="w-64 min-h-screen bg-card/40 backdrop-blur-xl border-r border-border flex flex-col relative">
      {/* Gradient accent */}
      <div className="absolute top-0 left-0 bottom-0 w-[2px] bg-gradient-primary" />

      {/* Header */}
      <div className="p-6 border-b border-border">
        <div className="flex items-center gap-3">
          <motion.div
            whileHover={{ scale: 1.05, rotate: 5 }}
            className="w-10 h-10 rounded-xl flex items-center justify-center relative"
            style={{ background: 'var(--gradient-primary)' }}
          >
            <span className="text-sm font-display font-black text-primary-foreground">N</span>
          </motion.div>
          <div>
            <h2 className="text-sm font-display font-bold text-gradient-primary tracking-wider">KATASHIE VPN</h2>
            <p className="text-xs text-muted-foreground">Panel v2.0</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 p-4 space-y-1">
        <p className="text-[10px] uppercase tracking-[0.2em] text-muted-foreground mb-3 px-4 font-semibold">
          {isAdmin ? '⚡ Administration' : '📦 Revendeur'}
        </p>
        {links.map((link, i) => {
          const isActive = location.pathname === link.to;
          return (
            <motion.div key={link.to} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.05 }}>
              <Link to={link.to} className={isActive ? 'sidebar-link-active' : 'sidebar-link'}>
                <link.icon className="w-4 h-4" />
                <span className="font-semibold">{link.label}</span>
              </Link>
            </motion.div>
          );
        })}
      </nav>

      {/* User */}
      <div className="p-4 border-t border-border">
        <div className="flex items-center gap-3 mb-3 px-4">
          <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold font-display"
            style={{ background: 'var(--gradient-primary)', color: 'white' }}>
            {user?.username?.charAt(0).toUpperCase()}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-foreground truncate">{user?.username}</p>
            <div className="flex items-center gap-1.5">
              {user?.role === 'super_admin' && <Crown className="w-3 h-3 text-warning" />}
              {user?.role === 'admin' && <Shield className="w-3 h-3 text-primary" />}
              <p className="text-xs text-muted-foreground capitalize">{user?.role === 'super_admin' ? 'Super Admin' : user?.role}</p>
            </div>
          </div>
        </div>
        <button onClick={logout} className="sidebar-link w-full text-destructive hover:bg-destructive/10 hover:text-destructive">
          <LogOut className="w-4 h-4" />
          Déconnexion
        </button>
      </div>
    </aside>
  );
}
