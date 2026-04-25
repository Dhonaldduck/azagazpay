// prisma/seed.js
require('dotenv').config();
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { run, get, all, cuid } = require('../src/config/database');

const hashUid = (uid) =>
  crypto.createHash('sha256')
    .update(uid.toUpperCase().replace(/[^A-F0-9]/g,''))
    .digest('hex');

async function main() {
  console.log('🌱 Seeding database AzagasPay...\n');

  // ── Kategori
  console.log('📂 Kategori...');
  const cats = [
    { name:'makanan', label:'Makanan', order:1 },
    { name:'minuman', label:'Minuman', order:2 },
    { name:'snack',   label:'Snack',   order:3 },
  ];
  for (const c of cats) {
    const ex = get('SELECT id FROM categories WHERE name=?', [c.name]);
    if (!ex) run('INSERT INTO categories(id,name,label,sort_order) VALUES(?,?,?,?)',
      [cuid(), c.name, c.label, c.order]);
  }
  const [mk, mn, sn] = cats.map(c => get('SELECT id FROM categories WHERE name=?', [c.name]));

  // ── Menu
  console.log('🍽️  Menu...');
  const menus = [
    { name:'Nasi Goreng Spesial', price:12000, stock:15, emoji:'🍳', catId:mk.id },
    { name:'Mie Ayam Bakso',      price:10000, stock:8,  emoji:'🍜', catId:mk.id },
    { name:'Roti Bakar Coklat',   price:7000,  stock:20, emoji:'🍞', catId:mk.id },
    { name:'Nasi Uduk',           price:8000,  stock:12, emoji:'🍚', catId:mk.id },
    { name:'Es Teh Manis',        price:3000,  stock:30, emoji:'🧋', catId:mn.id },
    { name:'Jus Jeruk',           price:5000,  stock:12, emoji:'🍊', catId:mn.id },
    { name:'Es Cincau',           price:4000,  stock:18, emoji:'🥤', catId:mn.id },
    { name:'Air Mineral',         price:2000,  stock:50, emoji:'💧', catId:mn.id },
    { name:'Gorengan Mix',        price:2000,  stock:50, emoji:'🥐', catId:sn.id },
    { name:'Bakso Bakar',         price:5000,  stock:25, emoji:'🍢', catId:sn.id },
    { name:'Keripik',             price:3000,  stock:30, emoji:'🫘', catId:sn.id },
  ];
  for (const m of menus) {
    const ex = get('SELECT id FROM menu_items WHERE name=?', [m.name]);
    if (!ex) run('INSERT INTO menu_items(id,category_id,name,price,stock,emoji) VALUES(?,?,?,?,?,?)',
      [cuid(), m.catId, m.name, m.price, m.stock, m.emoji]);
  }

  // ── Siswa
  console.log('👨‍🎓 Siswa...');
  const pin = await bcrypt.hash('123456', 10);
  let s1 = get('SELECT id FROM students WHERE nisn=?', ['1234567890']);
  if (!s1) {
    run('INSERT INTO students(id,nisn,name,class,pin_hash,balance) VALUES(?,?,?,?,?,?)',
      [cuid(),'1234567890','Budi Santoso','8A',pin,85000]);
    s1 = get('SELECT id FROM students WHERE nisn=?', ['1234567890']);
  }
  const uid1Hash = hashUid('A1:B2:C3:D4');
  if (!get('SELECT id FROM nfc_cards WHERE uid_hash=?', [uid1Hash]))
    run('INSERT INTO nfc_cards(id,student_id,uid_hash,uid_masked) VALUES(?,?,?,?)',
      [cuid(), s1.id, uid1Hash, '**** **** **** 4821']);

  let s2 = get('SELECT id FROM students WHERE nisn=?', ['0987654321']);
  if (!s2) run('INSERT INTO students(id,nisn,name,class,pin_hash,balance) VALUES(?,?,?,?,?,?)',
    [cuid(),'0987654321','Siti Rahayu','7B',pin,50000]);

  // ── Admin
  console.log('👤 Admin...');
  const admHash = await bcrypt.hash('admin123', 10);
  if (!get('SELECT id FROM admins WHERE username=?', ['admin']))
    run('INSERT INTO admins(id,username,password_hash,name,role) VALUES(?,?,?,?,?)',
      [cuid(),'admin',admHash,'Administrator','SUPER_ADMIN']);
  const kasHash = await bcrypt.hash('kasir123', 10);
  if (!get('SELECT id FROM admins WHERE username=?', ['kasir1']))
    run('INSERT INTO admins(id,username,password_hash,name,role) VALUES(?,?,?,?,?)',
      [cuid(),'kasir1',kasHash,'Kasir Satu','CASHIER']);

  // ── Perangkat NFC
  console.log('📡 Perangkat NFC...');
  if (!get('SELECT id FROM nfc_devices WHERE device_code=?', ['AZG-NFC-001']))
    run(`INSERT INTO nfc_devices(id,device_code,name,location,firmware_version,ip_address,mac_address,status,latency_ms,last_heartbeat_at)
         VALUES(?,?,?,?,?,?,?,?,?,datetime('now'))`,
      [cuid(),'AZG-NFC-001','NFC Reader — Kasir 1','Kasir Utama',
       'PN532 v1.6','192.168.1.101','AA:BB:CC:DD:EE:01','ONLINE',12]);
  if (!get('SELECT id FROM nfc_devices WHERE device_code=?', ['AZG-NFC-002']))
    run('INSERT INTO nfc_devices(id,device_code,name,location,firmware_version,ip_address,status) VALUES(?,?,?,?,?,?,?)',
      [cuid(),'AZG-NFC-002','NFC Reader — Kasir 2','Kasir Cadangan',
       'PN532 v1.6','192.168.1.102','OFFLINE']);

  console.log('\n✅ Seeding selesai!');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📌 Login Siswa → NISN: 1234567890 | PIN: 123456');
  console.log('📌 Login Admin → Username: admin | Password: admin123');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

main().catch(e => { console.error('❌', e); process.exit(1); });
