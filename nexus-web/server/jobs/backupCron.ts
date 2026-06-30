/**
 * Backup automatique SQLite → S3 / Backblaze B2
 * Compatible S3 API (AWS SDK v3)
 */
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';
import path from 'path';
import https from 'https';

const execAsync = promisify(exec);

const DB_PATH = process.env.KATASHIE_DB_PATH || '/etc/katashie-tunnel-web/data.db';
const BACKUP_DIR = process.env.KATASHIE_BACKUP_DIR || '/tmp/katashie_backups';
const S3_BUCKET = process.env.BACKUP_S3_BUCKET || '';
const S3_ENDPOINT = process.env.BACKUP_S3_ENDPOINT || ''; // For Backblaze: https://s3.us-west-004.backblazeb2.com
const S3_ACCESS_KEY = process.env.BACKUP_S3_ACCESS_KEY || '';
const S3_SECRET_KEY = process.env.BACKUP_S3_SECRET_KEY || '';
const S3_REGION = process.env.BACKUP_S3_REGION || 'us-east-1';

export async function runBackup(): Promise<{ success: boolean; file?: string; error?: string }> {
  try {
    if (!fs.existsSync(DB_PATH)) {
      return { success: false, error: `DB not found: ${DB_PATH}` };
    }

    fs.mkdirSync(BACKUP_DIR, { recursive: true });
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupFile = path.join(BACKUP_DIR, `katashie-backup-${timestamp}.db`);

    // SQLite online backup via .backup command
    await execAsync(`sqlite3 "${DB_PATH}" ".backup '${backupFile}'"`);

    // Compress backup
    const gzFile = backupFile + '.gz';
    await execAsync(`gzip -9 "${backupFile}"`);

    // If S3 configured, upload via AWS CLI (must be installed on server)
    if (S3_BUCKET && S3_ACCESS_KEY) {
      const s3Key = `backups/${path.basename(gzFile)}`;
      const endpoint = S3_ENDPOINT ? `--endpoint-url "${S3_ENDPOINT}"` : '';
      process.env.AWS_ACCESS_KEY_ID = S3_ACCESS_KEY;
      process.env.AWS_SECRET_ACCESS_KEY = S3_SECRET_KEY;
      await execAsync(
        `aws s3 cp "${gzFile}" "s3://${S3_BUCKET}/${s3Key}" --region ${S3_REGION} ${endpoint}`
      );
      fs.unlinkSync(gzFile); // Remove local after upload
    }

    // Keep only last 7 local backups
    const files = fs.readdirSync(BACKUP_DIR)
      .filter(f => f.startsWith('katashie-backup-') && f.endsWith('.gz'))
      .map(f => ({ name: f, mtime: fs.statSync(path.join(BACKUP_DIR, f)).mtime }))
      .sort((a, b) => b.mtime.getTime() - a.mtime.getTime());

    for (const old of files.slice(7)) {
      fs.unlinkSync(path.join(BACKUP_DIR, old.name));
    }

    const result = S3_BUCKET && S3_ACCESS_KEY ? `s3://${S3_BUCKET}/backups/${path.basename(gzFile)}` : gzFile;
    console.log(`[BACKUP] Completed: ${result}`);
    return { success: true, file: result };
  } catch (err: any) {
    console.error('[BACKUP] Failed:', err.message);
    return { success: false, error: err.message };
  }
}

// Schedule daily backup at 02:00 server time
export function scheduleDailyBackup(): void {
  function msUntil2AM(): number {
    const now = new Date();
    const next2AM = new Date(now);
    next2AM.setHours(2, 0, 0, 0);
    if (next2AM <= now) next2AM.setDate(next2AM.getDate() + 1);
    return next2AM.getTime() - now.getTime();
  }

  setTimeout(() => {
    runBackup().catch(console.error);
    setInterval(() => runBackup().catch(console.error), 24 * 60 * 60 * 1000);
  }, msUntil2AM());

  console.log(`[BACKUP] Scheduled daily at 02:00 (next in ${Math.round(msUntil2AM() / 60000)} min)`);
}
