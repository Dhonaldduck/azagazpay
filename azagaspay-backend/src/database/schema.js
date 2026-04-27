const schemaSql = `
CREATE TABLE IF NOT EXISTS students (
  id TEXT PRIMARY KEY,
  nisn TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  class TEXT NOT NULL,
  pin_hash TEXT NOT NULL,
  balance INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS nfc_cards (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  uid_hash TEXT UNIQUE NOT NULL,
  uid_masked TEXT NOT NULL,
  is_active INTEGER DEFAULT 1,
  registered_at TEXT DEFAULT (datetime('now')),
  last_used_at TEXT,
  FOREIGN KEY (student_id) REFERENCES students(id)
);

CREATE TABLE IF NOT EXISTS admins (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'CASHIER',
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  refresh_token TEXT UNIQUE NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (student_id) REFERENCES students(id)
);

CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS menu_items (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  name TEXT NOT NULL,
  price INTEGER NOT NULL,
  stock INTEGER DEFAULT 0,
  emoji TEXT DEFAULT '🍽️',
  image_url TEXT,
  is_available INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE IF NOT EXISTS nfc_devices (
  id TEXT PRIMARY KEY,
  device_code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  firmware_version TEXT NOT NULL,
  ip_address TEXT,
  mac_address TEXT,
  status TEXT DEFAULT 'OFFLINE',
  nfc_protocol TEXT DEFAULT 'ISO 14443',
  latency_ms INTEGER DEFAULT 0,
  last_heartbeat_at TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  device_id TEXT,
  total_amount INTEGER NOT NULL,
  balance_before INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  status TEXT DEFAULT 'PENDING',
  payment_method TEXT DEFAULT 'NFC_CARD',
  nfc_uid_hash TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  completed_at TEXT,
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (device_id) REFERENCES nfc_devices(id)
);

CREATE TABLE IF NOT EXISTS transaction_items (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  menu_item_id TEXT NOT NULL,
  menu_name TEXT NOT NULL,
  menu_price INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
);

CREATE TABLE IF NOT EXISTS top_ups (
  id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  admin_id TEXT,
  note TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (student_id) REFERENCES students(id)
);

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

CREATE INDEX IF NOT EXISTS idx_students_nisn ON students(nisn);
CREATE INDEX IF NOT EXISTS idx_nfc_cards_uid ON nfc_cards(uid_hash);
CREATE INDEX IF NOT EXISTS idx_transactions_student ON transactions(student_id, created_at);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_top_ups_student ON top_ups(student_id);
CREATE INDEX IF NOT EXISTS idx_topup_requests_student ON topup_requests(student_id);
CREATE INDEX IF NOT EXISTS idx_topup_requests_status ON topup_requests(status);
CREATE INDEX IF NOT EXISTS idx_transfers_sender ON transfers(sender_id);
CREATE INDEX IF NOT EXISTS idx_transfers_receiver ON transfers(receiver_id);
`;

module.exports = { schemaSql };
