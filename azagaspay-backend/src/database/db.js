// src/database/db.js
// Menggunakan node:sqlite bawaan Node.js 22 — tidak perlu install library apapun!
const { DatabaseSync } = require('node:sqlite');
const path = require('path');

const DB_PATH = process.env.DATABASE_URL
  ? process.env.DATABASE_URL.replace('file:', '')
  : path.join(process.cwd(), 'azagaspay.db');

// Singleton — satu koneksi untuk seluruh aplikasi
const db = new DatabaseSync(DB_PATH);

// Aktifkan WAL mode & foreign keys untuk performa + integritas
db.exec('PRAGMA journal_mode = WAL');
db.exec('PRAGMA foreign_keys = ON');

// ── Helper: jalankan query dengan error handling rapi ──────────
const run = (sql, params = []) => {
  const stmt = db.prepare(sql);
  return stmt.run(...params);
};

const get = (sql, params = []) => {
  const stmt = db.prepare(sql);
  return stmt.get(...params);
};

const all = (sql, params = []) => {
  const stmt = db.prepare(sql);
  return stmt.all(...params);
};

// ── Transaksi database (atomic) ────────────────────────────────
const transaction = (fn) => {
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

// ── Format angka ke Rupiah ─────────────────────────────────────
const formatRupiah = (amount) =>
  `Rp ${parseInt(amount).toLocaleString('id-ID')}`;

module.exports = { db, run, get, all, transaction, formatRupiah };
