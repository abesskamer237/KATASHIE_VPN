export type UserRole = 'super_admin' | 'admin' | 'reseller';

export interface ProtocolQuota {
  protocolId: ProtocolType;
  maxAccounts: number;
  usedAccounts: number;
}

export interface User {
  id: string;
  username: string;
  password?: string;
  role: UserRole;
  remainingDays?: number;
  expiryDate: string;
  createdAt: string;
  createdBy?: string;
  isActive: boolean;
  bouquet?: ProtocolQuota[];
}

export type ProtocolType = 'ssh' | 'vmess' | 'vless' | 'trojan' | 'socks' | 'openvpn' | 'slowdns' | 'udpcustom' | 'zipvpn';

export interface Protocol {
  id: ProtocolType;
  name: string;
  description: string;
  icon: string;
  ports: PortConfig[];
  isEnabled: boolean;
}

export interface PortConfig {
  service: string;
  transport: string;
  tls: string;
  ntls: string;
}

export interface VPNAccount {
  id: string;
  protocol: ProtocolType;
  username: string;
  password: string;
  expiryDate: string;
  createdAt: string;
  createdBy: string;
  serverIp: string;
  domain: string;
  nsDomain: string;
  isActive: boolean;
  config: string;
}

export interface ServerConfig {
  ip: string;
  domain: string;
  nsDomain: string;
  slowdnsPub: string;
  openvpnDownload: string;
}

export interface DashboardStats {
  totalResellers: number;
  activeResellers: number;
  totalAccounts: number;
  activeAccounts: number;
  protocolsEnabled: number;
}

export interface SiteSettings {
  siteName: string;
  sitePort: number;
  primaryColor: string;
  accentColor: string;
  logoText: string;
  footerText: string;
  maintenanceMode: boolean;
  registrationEnabled: boolean;
  maxResellersPerAdmin: number;
  defaultResellerDuration: number;
  telegramBot: string;
  telegramChannel: string;
}
