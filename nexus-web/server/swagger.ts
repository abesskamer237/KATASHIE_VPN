/**
 * Swagger / OpenAPI 3.0 documentation
 * Available at /api/docs
 */
export const swaggerSpec = {
  openapi: '3.0.0',
  info: {
    title: 'KATASHIE VPN API',
    version: '2.0.0',
    description: 'API REST complète pour le panneau de gestion KATASHIE VPN',
    contact: { name: 'KATASHIE VPN', url: 'https://t.me/abess237' }
  },
  servers: [{ url: '/api', description: 'Serveur principal' }],
  components: {
    securitySchemes: {
      BearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }
    },
    schemas: {
      Client: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          username: { type: 'string' },
          protocol: { type: 'string', enum: ['ssh', 'vless', 'vmess', 'trojan', 'socks', 'slowdns', 'zivpn'] },
          status: { type: 'string', enum: ['active', 'suspended', 'deleted'] },
          expires_at: { type: 'string', format: 'date' },
          data_limit: { type: 'number', nullable: true },
          data_used: { type: 'number' },
          created_at: { type: 'string', format: 'date-time' }
        }
      },
      Plan: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid' },
          name: { type: 'string' },
          protocol: { type: 'string' },
          duration_days: { type: 'integer' },
          price: { type: 'number' },
          currency: { type: 'string', default: 'XAF' }
        }
      },
      Payment: {
        type: 'object',
        properties: {
          payment_id: { type: 'string', format: 'uuid' },
          reference: { type: 'string' },
          campay_reference: { type: 'string' },
          ussd_code: { type: 'string' },
          status: { type: 'string', enum: ['pending', 'successful', 'failed'] }
        }
      },
      SystemStats: {
        type: 'object',
        properties: {
          cpu: { type: 'number', description: 'CPU usage %' },
          memory: { type: 'object', properties: { total: { type: 'integer' }, used: { type: 'integer' }, percent: { type: 'integer' } } },
          disk: { type: 'object', properties: { total: { type: 'string' }, used: { type: 'string' }, percent: { type: 'integer' } } },
          uptime_seconds: { type: 'integer' },
          timestamp: { type: 'string', format: 'date-time' }
        }
      }
    }
  },
  security: [{ BearerAuth: [] }],
  paths: {
    '/auth/login': {
      post: {
        tags: ['Auth'], summary: 'Connexion', security: [],
        requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { username: { type: 'string' }, password: { type: 'string' } }, required: ['username', 'password'] } } } },
        responses: { '200': { description: 'Token JWT', content: { 'application/json': { schema: { type: 'object', properties: { token: { type: 'string' }, role: { type: 'string' } } } } } }, '401': { description: 'Identifiants invalides' } }
      }
    },
    '/clients': {
      get: { tags: ['Clients'], summary: 'Liste des comptes VPN', responses: { '200': { description: 'Liste clients', content: { 'application/json': { schema: { type: 'array', items: { $ref: '#/components/schemas/Client' } } } } } } },
      post: { tags: ['Clients'], summary: 'Créer un compte VPN',
        requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { username: { type: 'string' }, protocol: { type: 'string' }, expires_at: { type: 'string', format: 'date' } }, required: ['username', 'protocol', 'expires_at'] } } } },
        responses: { '201': { description: 'Compte créé', content: { 'application/json': { schema: { $ref: '#/components/schemas/Client' } } } } }
      }
    },
    '/clients/{id}': {
      delete: { tags: ['Clients'], summary: 'Supprimer un compte', parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }], responses: { '200': { description: 'Supprimé' } } }
    },
    '/monitoring/snapshot': {
      get: { tags: ['Monitoring'], summary: 'Snapshot système (CPU/RAM/Disque)', responses: { '200': { description: 'Stats système', content: { 'application/json': { schema: { $ref: '#/components/schemas/SystemStats' } } } } } }
    },
    '/monitoring/stream': {
      get: { tags: ['Monitoring'], summary: 'Stream SSE temps réel (toutes les 3s)', responses: { '200': { description: 'Server-Sent Events stream' } } }
    },
    '/payment/initiate': {
      post: {
        tags: ['Paiement'], summary: 'Initier un paiement Mobile Money (Campay)', security: [],
        requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { phone: { type: 'string', example: '237682229367' }, amount: { type: 'number', example: 2000 }, plan_id: { type: 'string', format: 'uuid' } }, required: ['phone', 'amount', 'plan_id'] } } } },
        responses: { '200': { description: 'Paiement initié', content: { 'application/json': { schema: { $ref: '#/components/schemas/Payment' } } } } }
      }
    },
    '/payment/status/{reference}': {
      get: { tags: ['Paiement'], summary: 'Vérifier statut paiement', security: [], parameters: [{ name: 'reference', in: 'path', required: true, schema: { type: 'string' } }], responses: { '200': { description: 'Statut' } } }
    },
    '/qrcode/{clientId}': {
      get: { tags: ['QR Code'], summary: 'Générer QR code de connexion', parameters: [{ name: 'clientId', in: 'path', required: true, schema: { type: 'string' } }, { name: 'format', in: 'query', schema: { type: 'string', enum: ['png', 'uri'] } }], responses: { '200': { description: 'QR Code base64' } } }
    },
    '/export/clients/csv': {
      get: { tags: ['Export'], summary: 'Exporter comptes en CSV', responses: { '200': { description: 'Fichier CSV' } } }
    },
    '/servers': {
      get: { tags: ['Serveurs'], summary: 'Liste des serveurs VPS', responses: { '200': { description: 'Serveurs' } } },
      post: { tags: ['Serveurs'], summary: 'Ajouter un serveur VPS', requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { name: { type: 'string' }, host: { type: 'string' }, port: { type: 'integer' }, ssh_user: { type: 'string' } } } } } }, responses: { '201': { description: 'Serveur ajouté' } } }
    }
  },
  tags: [
    { name: 'Auth', description: 'Authentification et sessions' },
    { name: 'Clients', description: 'Gestion des comptes VPN' },
    { name: 'Monitoring', description: 'Surveillance système temps réel' },
    { name: 'Paiement', description: 'Mobile Money Campay (Orange/MTN)' },
    { name: 'QR Code', description: 'Génération QR codes de connexion' },
    { name: 'Export', description: 'Export CSV/JSON' },
    { name: 'Serveurs', description: 'Gestion multi-serveurs VPS' }
  ]
};
