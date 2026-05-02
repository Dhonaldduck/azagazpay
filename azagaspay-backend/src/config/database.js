// src/config/database.js
// Menggunakan node:sqlite built-in Node.js 22 — tidak butuh library tambahan
const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const { schemaSql } = require('../database/schema');

const BACKEND_ROOT = path.resolve(__dirname, '../..');

const resolveDatabasePath = () => {
  // Jika di Docker/Cloud, gunakan folder /app/data
  if (process.env.NODE_ENV === 'production') {
    return '/app/data/azagaspay.db';
  }
  
  const databaseUrl = process.env.DATABASE_URL || 'file:./azagaspay.db';
  const dbPath = databaseUrl.startsWith('file:')
    ? databaseUrl.slice('file:'.length)
    : databaseUrl;

  return path.isAbsolute(dbPath)
    ? dbPath
    : path.resolve(BACKEND_ROOT, dbPath);
};

const DB_PATH = resolveDatabasePath();

const initializeDatabase = (db) => {
  db.exec('PRAGMA journal_mode = WAL');
  db.exec('PRAGMA foreign_keys = ON');
  db.exec(schemaSql);
};

let _db;
const getDb = () => {
  if (!_db) {
    _db = new DatabaseSync(DB_PATH);
    initializeDatabase(_db);
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

const closeDb = () => {
  if (_db) {
    _db.close();
    _db = null;
  }
};

module.exports = {
  DB_PATH,
  resolveDatabasePath,
  initializeDatabase,
  closeDb,
  getDb,
  run,
  get,
  all,
  transaction,
  formatRupiah,
  cuid,
};
