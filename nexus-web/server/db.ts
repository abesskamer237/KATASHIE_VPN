import Database from 'better-sqlite3';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import fs from 'fs';

const DB_DIR = process.env.NEXUS_DB_DIR || '/etc/nexus-tunnel-web';
const DB_PATH = path.join(DB_DIR, 'nexus.db');

let db: Database.Database;

export function getDb(): Database.Database {
  if (!db) {
    fs.mkdirSync(DB_DIR, { recursive: true });
    db = new Database(DB_PATH);
    db.pragma('journal_mode = WAL');
    db.pragma('foreign_keys = ON');
    // Allow up to 10 s of retries when another writer holds the lock
    // (prevents "database is locked" crashes during heavy concurrent use)
    db.pragma('busy_timeout = 10000');
    // Faster fsync without sacrificing crash safety (WAL already protects us)
    db.pragma('synchronous = NORMAL');
    // Keep temp tables in memory for faster queries
    db.pragma('temp_store = MEMORY');
    initSchema();
  }
  return db;
}

function initSchema(): void {
  const database = db;

  database.exec(`
    CREATE TABLE IF NOT EXISTS admins (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'admin',
      status TEXT NOT NULL DEFAULT 'active',
      bouquet TEXT DEFAULT '[]',
      expiry_date TEXT,
      credits INTEGER DEFAULT 0,
      max_credits INTEGER DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS clients (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      protocol TEXT NOT NULL,
      plan_id TEXT,
      expires_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      created_by TEXT,
      extra_data TEXT DEFAULT '{}',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now')),
      UNIQUE(username, protocol)
    );

    CREATE TABLE IF NOT EXISTS plans (
      id TEXT PRIMARY KEY,
      name TEXT UNIQUE NOT NULL,
      description TEXT DEFAULT '',
      duration_days INTEGER NOT NULL DEFAULT 30,
      price REAL NOT NULL DEFAULT 0,
      protocols TEXT NOT NULL DEFAULT '["ssh"]',
      max_connections INTEGER NOT NULL DEFAULT 1,
      bandwidth_gb REAL DEFAULT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS audit_logs (
      id TEXT PRIMARY KEY,
      admin_id TEXT,
      admin_username TEXT,
      action TEXT NOT NULL,
      target_type TEXT,
      target_id TEXT,
      details TEXT DEFAULT '{}',
      ip_address TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      admin_id TEXT NOT NULL,
      token TEXT UNIQUE NOT NULL,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE INDEX IF NOT EXISTS idx_clients_created_by ON clients(created_by);
    CREATE INDEX IF NOT EXISTS idx_admins_role_status ON admins(role, status);
    CREATE INDEX IF NOT EXISTS idx_admins_role_status_expiry ON admins(role, status, expiry_date);
  `);

  // Migration: add new columns to admins table if they don't exist
  interface ColInfo { name: string }
  const cols = (database.prepare('PRAGMA table_info(admins)').all() as ColInfo[]).map(c => c.name);
  if (!cols.includes('bouquet')) {
    database.exec("ALTER TABLE admins ADD COLUMN bouquet TEXT DEFAULT '[]'");
  }
  if (!cols.includes('expiry_date')) {
    database.exec('ALTER TABLE admins ADD COLUMN expiry_date TEXT');
  }
  if (!cols.includes('credits')) {
    database.exec('ALTER TABLE admins ADD COLUMN credits INTEGER DEFAULT 0');
  }
  if (!cols.includes('max_credits')) {
    database.exec('ALTER TABLE admins ADD COLUMN max_credits INTEGER DEFAULT 0');
  }
  if (!cols.includes('suspended_at')) {
    database.exec('ALTER TABLE admins ADD COLUMN suspended_at TEXT');
  }

  // Create index on suspended_at only after ensuring the column exists
  database.exec('CREATE INDEX IF NOT EXISTS idx_admins_role_status_suspended ON admins(role, status, suspended_at)');
}

export function seedSuperAdmin(username: string, password: string): void {
  const database = getDb();
  const existing = database.prepare('SELECT id FROM admins WHERE role = ?').get('super_admin');
  if (!existing) {
    const hash = bcrypt.hashSync(password, 12);
    database.prepare(
      'INSERT INTO admins (id, username, password_hash, role, status) VALUES (?, ?, ?, ?, ?)'
    ).run(uuidv4(), username, hash, 'super_admin', 'active');
    console.log(`[DB] Super admin '${username}' created.`);
  }
}

export function logAction(
  adminId: string | null,
  adminUsername: string | null,
  action: string,
  targetType: string | null,
  targetId: string | null,
  details: Record<string, unknown>,
  ip: string | null
): void {
  const database = getDb();
  database.prepare(
    `INSERT INTO audit_logs (id, admin_id, admin_username, action, target_type, target_id, details, ip_address)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    uuidv4(),
    adminId,
    adminUsername,
    action,
    targetType,
    targetId,
    JSON.stringify(details),
    ip
  );
}
