import { User, Protocol, VPNAccount, ServerConfig, DashboardStats, SiteSettings } from './types';

export const serverConfig: ServerConfig = {
  ip: '45.41.206.33',
  domain: 'joel.camtel.eu.cc',
  nsDomain: 'blue.camtel.eu.cc',
  slowdnsPub: '3c80f158747e724d61dc94b610198a65ab0183b657cf373f606993bb66731e5a',
  openvpnDownload: 'https://joel.camtel.eu.cc:2081',
};

export const defaultSiteSettings: SiteSettings = {
  siteName: 'KATASHIE VPN Panel',
  sitePort: 8443,
  primaryColor: '#8a2be2',
  accentColor: '#ff0080',
  logoText: 'KATASHIE VPN',
  footerText: '© 2026 KATASHIE VPN Panel. All rights reserved.',
  maintenanceMode: false,
  registrationEnabled: true,
  maxResellersPerAdmin: 100,
  defaultResellerDuration: 30,
  telegramBot: '',
  telegramChannel: '',
};

export const protocols: Protocol[] = [
  {
    id: 'ssh',
    name: 'SSH',
    description: 'SSH WebSocket avec Stunnel, Dropbear et OpenSSH',
    icon: '🔑',
    isEnabled: true,
    ports: [
      { service: 'OpenSSH', transport: 'TCP', tls: '22', ntls: '22' },
      { service: 'Dropbear', transport: 'TCP', tls: '109, 143', ntls: '109, 143' },
      { service: 'Stunnel', transport: 'TCP', tls: '447, 777', ntls: '-' },
      { service: 'WS', transport: 'WebSocket', tls: '443', ntls: '80' },
      { service: 'UDPGW', transport: 'UDP', tls: '7100-7900', ntls: '-' },
      { service: 'Squid', transport: 'TCP', tls: '3128, 8080', ntls: '-' },
    ],
  },
  {
    id: 'vmess',
    name: 'VMess',
    description: 'VMess WebSocket & gRPC',
    icon: '⚡',
    isEnabled: true,
    ports: [
      { service: 'VMess WS', transport: 'WebSocket', tls: '443', ntls: '80' },
      { service: 'VMess gRPC', transport: 'gRPC', tls: '443', ntls: '-' },
      { service: 'VMess Custom', transport: 'WebSocket', tls: '2083', ntls: '2082' },
    ],
  },
  {
    id: 'vless',
    name: 'VLESS',
    description: 'VLESS WebSocket & gRPC',
    icon: '🚀',
    isEnabled: true,
    ports: [
      { service: 'VLESS WS', transport: 'WebSocket', tls: '443', ntls: '80' },
      { service: 'VLESS gRPC', transport: 'gRPC', tls: '443', ntls: '-' },
      { service: 'VLESS Custom', transport: 'WebSocket', tls: '2087', ntls: '2086' },
    ],
  },
  {
    id: 'trojan',
    name: 'Trojan',
    description: 'Trojan WebSocket & gRPC',
    icon: '🛡️',
    isEnabled: true,
    ports: [
      { service: 'Trojan WS', transport: 'WebSocket', tls: '443', ntls: '80' },
      { service: 'Trojan gRPC', transport: 'gRPC', tls: '443', ntls: '-' },
    ],
  },
  {
    id: 'socks',
    name: 'SOCKS',
    description: 'SOCKS5 WebSocket & gRPC',
    icon: '🧦',
    isEnabled: true,
    ports: [
      { service: 'SOCKS WS', transport: 'WebSocket', tls: '443', ntls: '80' },
      { service: 'SOCKS gRPC', transport: 'gRPC', tls: '443', ntls: '-' },
    ],
  },
  {
    id: 'openvpn',
    name: 'OpenVPN',
    description: 'OpenVPN TCP/UDP/SSL avec OHP',
    icon: '🔐',
    isEnabled: true,
    ports: [
      { service: 'OpenVPN TCP', transport: 'TCP', tls: '1194', ntls: '-' },
      { service: 'OpenVPN SSL', transport: 'SSL', tls: '2200', ntls: '-' },
      { service: 'OHP', transport: 'TCP', tls: '8000', ntls: '-' },
    ],
  },
  {
    id: 'slowdns',
    name: 'Slow DNS',
    description: 'DNS Tunneling sur tous les ports',
    icon: '🌐',
    isEnabled: true,
    ports: [
      { service: 'SlowDNS', transport: 'DNS', tls: '22,53,5300,80,443', ntls: '-' },
    ],
  },
  {
    id: 'udpcustom',
    name: 'UDP Custom',
    description: 'UDP Custom sur tous les ports',
    icon: '📡',
    isEnabled: true,
    ports: [
      { service: 'UDP Custom', transport: 'UDP', tls: '1-65535', ntls: '-' },
    ],
  },
  {
    id: 'zipvpn',
    name: 'ZipVPN',
    description: 'Compte ZipVPN (KATASHIE Tunnel)',
    icon: '🧩',
    isEnabled: true,
    ports: [
      { service: 'ZipVPN', transport: 'TCP/UDP', tls: 'Auto', ntls: '-' },
    ],
  },
];

export const mockAccounts: VPNAccount[] = [
  {
    id: 'acc1', protocol: 'ssh', username: 'testssh', password: 'testssh',
    expiryDate: '2026-03-19', createdAt: '2026-03-18', createdBy: 'res-1',
    serverIp: '45.41.206.33', domain: 'joel.camtel.eu.cc', nsDomain: 'blue.camtel.eu.cc',
    isActive: true, config: '',
  },
];

export const mockStats: DashboardStats = {
  totalResellers: 3,
  activeResellers: 2,
  totalAccounts: 47,
  activeAccounts: 38,
  totalCreditsUsed: 1250,
  protocolsEnabled: 8,
};
