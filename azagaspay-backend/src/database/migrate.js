// src/database/migrate.js
// Jalankan: node src/database/migrate.js
require('dotenv').config();
const { DatabaseSync } = require('node:sqlite');
const { DB_PATH, initializeDatabase } = require('../config/database');

const db = new DatabaseSync(DB_PATH);

console.log('🔨 Membuat tabel database SQLite...\n');
initializeDatabase(db);

db.close();
console.log('✅ Semua tabel berhasil dibuat!\n');
