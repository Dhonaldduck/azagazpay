
const { DatabaseSync } = require('node:sqlite');
const bcrypt = require('bcryptjs');
const path = require('path');

const DB_PATH = '/home/dhonaldduck/Documents/azagaspay-project/azagaspay/azagaspay-backend/azagaspay.db';
const db = new DatabaseSync(DB_PATH);

const cuid = () => {
  const ts  = Date.now().toString(36);
  const rnd = Math.random().toString(36).slice(2, 10);
  return `c${ts}${rnd}`;
};

const addStudent = (nisn, name, className, pin) => {
  const id = cuid();
  const pinHash = bcrypt.hashSync(pin, 10);
  
  const stmt = db.prepare('INSERT INTO students (id, nisn, name, class, pin_hash, balance) VALUES (?, ?, ?, ?, ?, 0)');
  try {
    stmt.run(id, nisn, name, className, pinHash);
    console.log(`Berhasil menambahkan siswa: ${name} (NISN: ${nisn})`);
    console.log(`PIN Default: ${pin}`);
  } catch (err) {
    console.error('Gagal menambahkan siswa:', err.message);
  }
};

addStudent('123454321', 'Radityaaryo', '12-IPA-1', '123456');
