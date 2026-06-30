import { useState } from 'react';
import { LayoutDashboard, Users, UserCog, Shield, Server, Activity, Settings, ScrollText, CreditCard, Globe, LogOut, Menu, X } from 'lucide-react';
import ThemeToggle from './ThemeToggle';
import LanguageSwitcher from './LanguageSwitcher';
import { useI18n } from '../contexts/I18nContext';

interface SidebarProps {
  currentPage: string;
  onNavigate: (page: string) => void;
  role: string;
  username: string;
  onLogout: () => void;
}

export default function AppSidebar({ currentPage, onNavigate, role, username, onLogout }: SidebarProps) {
  const { t } = useI18n();
  const [mobileOpen, setMobileOpen] = useState(false);
  const nav = (page: string) => { onNavigate(page); setMobileOpen(false); };

  const Item = ({ page, icon: Icon, label }: { page: string; icon: any; label: string }) => (
    <button className={`sidebar-item ${currentPage === page ? 'active' : ''}`} onClick={() => nav(page)}>
      <Icon size={16} className="sidebar-icon" />{label}
    </button>
  );

  return (
    <>
      <button className="sidebar-toggle" onClick={() => setMobileOpen(o => !o)}>
        {mobileOpen ? <X size={20} /> : <Menu size={20} />}
      </button>
      <div className={`sidebar-overlay ${mobileOpen ? 'visible' : ''}`} onClick={() => setMobileOpen(false)} />
      <nav className={`sidebar ${mobileOpen ? 'open' : ''}`}>
        <div className="sidebar-logo">
          <span className="logo-k">K</span>
          <span className="logo-text">ATASHIE <span style={{ color: 'var(--blue)' }}>VPN</span></span>
        </div>
        <div className="sidebar-section">
          <div className="sidebar-section-label">Principal</div>
          <Item page="dashboard" icon={LayoutDashboard} label={t('nav.dashboard')} />
          <Item page="accounts" icon={Users} label={t('nav.accounts')} />
          <Item page="monitoring" icon={Activity} label={t('nav.monitoring')} />
          <Item page="servers" icon={Server} label={t('nav.servers')} />
        </div>
        {role === 'admin' && (
          <div className="sidebar-section">
            <div className="sidebar-section-label">Administration</div>
            <Item page="resellers" icon={UserCog} label={t('nav.resellers')} />
            <Item page="admins" icon={Shield} label={t('nav.admins')} />
            <Item page="protocols" icon={Globe} label={t('nav.protocols')} />
            <Item page="audit" icon={ScrollText} label={t('nav.audit')} />
            <Item page="payment" icon={CreditCard} label={t('nav.payment')} />
          </div>
        )}
        <div className="sidebar-section">
          <div className="sidebar-section-label">Système</div>
          <Item page="settings" icon={Settings} label={t('nav.settings')} />
        </div>
        <div className="sidebar-footer">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', padding: '0 0.25rem' }}>
            <div style={{ width: 28, height: 28, background: 'var(--blue)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: '0.8rem', fontWeight: 700, flexShrink: 0 }}>
              {username[0]?.toUpperCase()}
            </div>
            <div style={{ flex: 1, overflow: 'hidden' }}>
              <div style={{ fontSize: '0.8rem', fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{username}</div>
              <div style={{ fontSize: '0.68rem', color: 'var(--text-muted)', textTransform: 'uppercase' }}>{role}</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '0.25rem', alignItems: 'center', justifyContent: 'space-between' }}>
            <LanguageSwitcher />
            <ThemeToggle />
            <button className="btn btn-ghost btn-sm btn-danger" onClick={onLogout} title={t('nav.logout')}><LogOut size={14} /></button>
          </div>
        </div>
      </nav>
    </>
  );
}
