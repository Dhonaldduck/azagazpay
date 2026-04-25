// src/config/database.js
// Menggunakan node:sqlite built-in Node.js 22 — tidak butuh library tambahan
const { DatabaseSync } = require('node:sqlite');
const path = require('path');

const DB_PATH = path.join(process.cwd(), 'azagaspay.db');

let _db;
const getDb = () => {
  if (!_db) {
    _db = new DatabaseSync(DB_PATH);
    _db.exec('PRAGMA journal_mode = WAL');
    _db.exec('PRAGMA foreign_keys = ON');
    _db.exec(`
      CREATE TABLE IF NOT EXISTS topup_requests (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        notes TEXT,
        status TEXT DEFAULT 'PENDING',
        requested_at TEXT DEFAULT (datetime('now')),
        approved_by TEXT,
        approved_at TEXT,
        FOREIGN KEY (student_id) REFERENCES students(id)
      );
      CREATE INDEX IF NOT EXISTS idx_topup_requests_student ON topup_requests(student_id);
      CREATE INDEX IF NOT EXISTS idx_topup_requests_status ON topup_requests(status);
      CREATE TABLE IF NOT EXISTS transfers (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT,
        sender_balance_before INTEGER NOT NULL,
        sender_balance_after INTEGER NOT NULL,
        receiver_balance_before INTEGER NOT NULL,
        receiver_balance_after INTEGER NOT NULL,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (sender_id) REFERENCES students(id),
        FOREIGN KEY (receiver_id) REFERENCES students(id)
      );
      CREATE INDEX IF NOT EXISTS idx_transfers_sender ON transfers(sender_id);
      CREATE INDEX IF NOT EXISTS idx_transfers_receiver ON transfers(receiver_id);
    `);
  }
  return _db;
};

// ── Query helpers ────────────────────────────────────────────
const run = (sql, params = []) => {
  const stmt = getDb().prepare(sql);
  return stmt.run(...params);
};

const get = (sql, params = []) => {
  const stmt = getDb().prepare(sql);
  return stmt.get(...params);
};

const all = (sql, params = []) => {
  const stmt = getDb().prepare(sql);
  return stmt.all(...params);
};

// Atomic transaction
const transaction = (fn) => {
  const db = getDb();
  db.exec('BEGIN');
  try {
    const result = fn();
    db.exec('COMMIT');
    return result;
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
};

const formatRupiah = (amount) =>
  `Rp ${parseInt(amount).toLocaleString('id-ID')}`;

// CUID-like ID generator
const cuid = () => {
  const ts  = Date.now().toString(36);
  const rnd = Math.random().toString(36).slice(2, 10);
  return `c${ts}${rnd}`;
};

module.exports = { getDb, run, get, all, transaction, formatRupiah, cuid };
