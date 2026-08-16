import { ProtocolType, ServerConfig } from './types';

interface AccountData {
  username: string;
  password: string;
  expiryDate: string;
  protocol: ProtocolType;
  uuid?: string;
  domain?: string;
  host?: string;
  [key: string]: unknown;
}

const LINE = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

export function formatConfig(data: AccountData, server: ServerConfig): string {
  switch (data.protocol) {
    case 'ssh': return formatSSH(data, server);
    case 'vmess': return formatVMess(data, server);
    case 'vless': return formatVLess(data, server);
    case 'trojan': return formatTrojan(data, server);
    case 'socks': return formatSocks(data, server);
    case 'openvpn': return formatOpenVPN(data, server);
    case 'slowdns': return formatSlowDNS(data, server);
    case 'udpcustom': return formatUDPCustom(data, server);
    case 'zipvpn': return formatZipVPN(data, server);
    default: return '';
  }
}

/** Priorité : domain depuis account_data > domain depuis settings > IP */
function effectiveDomain(data: AccountData, server: ServerConfig): string {
  return (data.domain as string) || server.domain || (data.host as string) || server.ip || '';
}

function b64(str: string): string {
  const bytes = new TextEncoder().encode(str);
  let binary = '';
  bytes.forEach(b => { binary += String.fromCharCode(b); });
  return btoa(binary);
}

function formatSSH(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  const ip = server.ip || (data.host as string) || '';
  return `┏${LINE}┓
┃               SSH ACCOUNT DETAILS                ┃
┗${LINE}┛
┏${LINE}┓
┃ Username    : ${data.username}
┃ Password    : ${data.password}
┃ Expiry Date : ${data.expiryDate}
┃ Host/IP     : ${ip}
┃ Domain      : ${domain}
┃ NS Domain   : ${server.nsDomain}
●${LINE}●
┃ OpenSSH      : 22
┃ Dropbear     : 109, 143
┃ Stunnel      : 447, 777
┃ WS NTLS      : 80
┃ WS TLS       : 443
┃ UDPGW        : 7100–7900
┃ Squid        : 3128, 8080
┃ OpenVPN      : TCP 1194, SSL 2200, OHP 8000
┃ Slow DNS     : 22,53,5300,80,443
●${LINE}●
┃ UDP Custom
┃ ${domain}:1-65535@${data.username}:${data.password}
●${LINE}●
┃ Slow DNS
┃ PUB : ${server.slowdnsPub}
●${LINE}●
┃ OpenVPN File
┃ Download     : ${server.openvpnDownload}
●${LINE}●
┃ Payload
┃ GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]
┗${LINE}┛`;
}

function formatVLess(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  const uuid = (data.uuid as string) || data.password;
  const user = data.username;

  const linkTls  = `vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&type=ws#${user}`;
  const linkNtls = `vless://${uuid}@${domain}:80?path=/vless&encryption=none&type=ws#${user}`;
  const linkGrpc = `vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc#${user}`;

  return `┏${LINE}┓
┃             VLESS ACCOUNT DETAILS               ┃
┗${LINE}┛
┏${LINE}┓
┃ Remarks     : ${user}
┃ Domain      : ${domain}
┃ Port TLS    : 443
┃ Port NTLS   : 80
┃ UUID        : ${uuid}
┃ Path        : /vless
┃ Expiry Date : ${data.expiryDate}
●${LINE}●
┃ gRPC
┃ Service Name: vless-grpc
┃ Port        : 443
●${LINE}●
┃ 🔗 TLS (443):
┃ ${linkTls}
●${LINE}●
┃ 🔗 NTLS (80):
┃ ${linkNtls}
●${LINE}●
┃ 🔗 GRPC (443):
┃ ${linkGrpc}
┗${LINE}┛`;
}

function formatVMess(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  const uuid = (data.uuid as string) || data.password;
  const user = data.username;

  const wsTls  = JSON.stringify({ v: '2', ps: user, add: domain, port: '443', id: uuid, aid: '0', net: 'ws',   path: '/vmess',     type: 'none', host: '', tls: 'tls'  });
  const wsNtls = JSON.stringify({ v: '2', ps: user, add: domain, port: '80',  id: uuid, aid: '0', net: 'ws',   path: '/vmess',     type: 'none', host: '', tls: 'none' });
  const grpc   = JSON.stringify({ v: '2', ps: user, add: domain, port: '443', id: uuid, aid: '0', net: 'grpc', path: 'vmess-grpc', type: 'none', host: '', tls: 'tls'  });

  const linkTls  = 'vmess://' + b64(wsTls);
  const linkNtls = 'vmess://' + b64(wsNtls);
  const linkGrpc = 'vmess://' + b64(grpc);

  return `┏${LINE}┓
┃             VMESS ACCOUNT DETAILS               ┃
┗${LINE}┛
┏${LINE}┓
┃ Remarks     : ${user}
┃ Domain      : ${domain}
┃ Port TLS    : 443
┃ Port NTLS   : 80
┃ UUID        : ${uuid}
┃ Path        : /vmess
┃ Expiry Date : ${data.expiryDate}
●${LINE}●
┃ gRPC
┃ Service Name: vmess-grpc
┃ Port        : 443
●${LINE}●
┃ 🔗 TLS (443):
┃ ${linkTls}
●${LINE}●
┃ 🔗 NTLS (80):
┃ ${linkNtls}
●${LINE}●
┃ 🔗 GRPC (443):
┃ ${linkGrpc}
┗${LINE}┛`;
}

function formatTrojan(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  const password = data.password;
  const user = data.username;

  const linkTls  = `trojan://${password}@${domain}:443?path=/trws&security=tls&encryption=none&host=${domain}&type=ws#${user}`;
  const linkNtls = `trojan://${password}@${domain}:80?path=/trws&encryption=none&security=none&host=${domain}&type=ws#${user}`;
  const linkGrpc = `trojan://${password}@${domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${domain}#${user}`;

  return `┏${LINE}┓
┃             TROJAN ACCOUNT DETAILS              ┃
┗${LINE}┛
┏${LINE}┓
┃ Remarks     : ${user}
┃ Domain      : ${domain}
┃ Port TLS    : 443
┃ Port NTLS   : 80
┃ Password    : ${password}
┃ Path        : /trws
┃ Expiry Date : ${data.expiryDate}
●${LINE}●
┃ gRPC
┃ Service Name: trojan-grpc
┃ Port        : 443
●${LINE}●
┃ 🔗 TLS (443):
┃ ${linkTls}
●${LINE}●
┃ 🔗 NTLS (80):
┃ ${linkNtls}
●${LINE}●
┃ 🔗 GRPC (443):
┃ ${linkGrpc}
┗${LINE}┛`;
}

function formatSocks(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  const password = data.password;
  const user = data.username;
  const link = `socks5://${user}:${password}@${domain}:1080`;

  return `┏${LINE}┓
┃              SOCKS ACCOUNT DETAILS              ┃
┗${LINE}┛
┏${LINE}┓
┃ Username    : ${user}
┃ Password    : ${password}
┃ Expiry Date : ${data.expiryDate}
┃ Domain      : ${domain}
┃ Port        : 1080
●${LINE}●
┃ 🔗 SOCKS5:
┃ ${link}
┗${LINE}┛`;
}

function formatOpenVPN(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  const ip = server.ip || (data.host as string) || '';
  return `┏${LINE}┓
┃           OPENVPN ACCOUNT DETAILS              ┃
┗${LINE}┛
┏${LINE}┓
┃ Username    : ${data.username}
┃ Password    : ${data.password}
┃ Expiry Date : ${data.expiryDate}
┃ Host/IP     : ${ip}
●${LINE}●
┃ OpenVPN TCP  : 1194
┃ OpenVPN SSL  : 2200
┃ OHP          : 8000
●${LINE}●
┃ Config File
┃ Download     : ${server.openvpnDownload || (domain ? `https://${domain}:2081` : 'N/A')}
┗${LINE}┛`;
}

function formatSlowDNS(data: AccountData, server: ServerConfig): string {
  return `┏${LINE}┓
┃           SLOW DNS ACCOUNT DETAILS             ┃
┗${LINE}┛
┏${LINE}┓
┃ Username    : ${data.username}
┃ Password    : ${data.password}
┃ Expiry Date : ${data.expiryDate}
┃ NS Domain   : ${server.nsDomain}
●${LINE}●
┃ Ports       : 22,53,5300,80,443
┃ PUB Key     : ${server.slowdnsPub}
┗${LINE}┛`;
}

function formatUDPCustom(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  return `┏${LINE}┓
┃          UDP CUSTOM ACCOUNT DETAILS            ┃
┗${LINE}┛
┏${LINE}┓
┃ Username    : ${data.username}
┃ Password    : ${data.password}
┃ Expiry Date : ${data.expiryDate}
●${LINE}●
┃ Auth String
┃ ${domain}:1-65535@${data.username}:${data.password}
┗${LINE}┛`;
}

function formatZipVPN(data: AccountData, server: ServerConfig): string {
  const domain = effectiveDomain(data, server);
  return `┏${LINE}┓
┃            ZIPVPN ACCOUNT DETAILS               ┃
┗${LINE}┛
┏${LINE}┓
┃ Username    : ${data.username}
┃ Password    : ${data.password}
┃ Expiry Date : ${data.expiryDate}
┃ Domain      : ${domain}
●${LINE}●
┃ Protocol    : ZIPVPN
┃ Notes       : Utilisez les identifiants dans l'application ZipVPN
┗${LINE}┛`;
}
