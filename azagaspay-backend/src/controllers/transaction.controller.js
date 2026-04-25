// src/controllers/transaction.controller.js
const { get, run, all, transaction, cuid, formatRupiah } = require('../config/database');
const { success, error, paginate } = require('../utils/response');
const { hashUid, decryptUid } = require('../utils/nfc-crypto');
const logger = require('../config/logger');

const fmtTx = (tx) => {
  const items = all('SELECT * FROM transaction_items WHERE transaction_id=?', [tx.id]);
  return {
    id: tx.id,
    totalAmount: tx.total_amount,
    formattedTotal: formatRupiah(tx.total_amount),
    balanceBefore: tx.balance_before,
    balanceAfter:  tx.balance_after,
    formattedBalanceAfter: formatRupiah(tx.balance_after),
    status: tx.status,
    paymentMethod: tx.payment_method,
    createdAt:   tx.created_at,
    completedAt: tx.completed_at,
    items: items.map(i => ({
      name: i.menu_name,
      price: i.menu_price,
      formattedPrice: formatRupiah(i.menu_price),
      quantity: i.quantity,
      subtotal: i.menu_price * i.quantity,
      formattedSubtotal: formatRupiah(i.menu_price * i.quantity),
    })),
  };
};

// POST /api/transactions
const createTransaction = (req, res) => {
  const { items, paymentMethod = 'NFC_CARD', uid, deviceId } = req.body;
  const studentId = req.student.id;
  try {
    // Validasi & hitung total
    let totalAmount = 0;
    const itemDetails = [];
    for (const oi of items) {
      const menu = get(
        'SELECT * FROM menu_items WHERE id=? AND is_available=1', [oi.menuItemId]);
      if (!menu) return error(res, `Menu tidak tersedia`, 400);
      if (menu.stock < oi.quantity)
        return error(res, `Stok ${menu.name} tidak cukup`, 400);
      totalAmount += menu.price * oi.quantity;
      itemDetails.push({ menu, quantity: oi.quantity });
    }

    const student = get('SELECT balance FROM students WHERE id=?', [studentId]);
    if (student.balance < totalAmount)
      return error(res, `Saldo tidak cukup. Saldo: ${formatRupiah(student.balance)}, Total: ${formatRupiah(totalAmount)}`, 400);

    const txId = cuid();
    const newBalance = student.balance - totalAmount;
    const nfcUidHash = uid ? hashUid(uid) : null;

    transaction(() => {
      run('UPDATE students SET balance=? WHERE id=?', [newBalance, studentId]);
      for (const { menu, quantity } of itemDetails) {
        run('UPDATE menu_items SET stock=stock-? WHERE id=?', [quantity, menu.id]);
      }
      run(`INSERT INTO transactions(id,student_id,device_id,total_amount,balance_before,balance_after,status,payment_method,nfc_uid_hash,completed_at)
           VALUES(?,?,?,?,?,?,'SUCCESS',?,?,datetime('now'))`,
          [txId, studentId, deviceId||null, totalAmount,
           student.balance, newBalance, paymentMethod, nfcUidHash]);
      for (const { menu, quantity } of itemDetails) {
        run(`INSERT INTO transaction_items(id,transaction_id,menu_item_id,menu_name,menu_price,quantity)
             VALUES(?,?,?,?,?,?)`,
            [cuid(), txId, menu.id, menu.name, menu.price, quantity]);
      }
    });

    const tx = get('SELECT * FROM transactions WHERE id=?', [txId]);
    logger.info(`Transaksi berhasil — Total: ${formatRupiah(totalAmount)}`);
    return success(res, fmtTx(tx), 'Pembayaran berhasil', 201);
  } catch (e) {
    logger.error('createTransaction:', e);
    return error(res, 'Transaksi gagal', 500);
  }
};

// POST /api/transactions/nfc-pay
const nfcPay = (req, res) => {
  const { uid: encryptedUid, items } = req.body;
  const device = req.device;
  try {
    // Dekripsi UID terenkripsi dari ESP32 sebelum di-hash
    const uid     = decryptUid(encryptedUid);
    const uidHash = hashUid(uid);

    const card = get('SELECT * FROM nfc_cards WHERE uid_hash=? AND is_active=1', [uidHash]);
    if (!card) return error(res, 'Kartu NFC tidak valid', 401);

    const student = get('SELECT * FROM students WHERE id=? AND is_active=1', [card.student_id]);
    if (!student) return error(res, 'Akun siswa dinonaktifkan', 403);

    run('UPDATE nfc_cards SET last_used_at=? WHERE id=?', [new Date().toISOString(), card.id]);
    run("UPDATE nfc_devices SET last_heartbeat_at=datetime('now'),status='ONLINE' WHERE id=?",
      [device.id]);

    // Identifikasi saja (tanpa items) — tampilkan info siswa ke ESP32
    if (!items || !Array.isArray(items) || items.length === 0) {
      return success(res, {
        mode: 'IDENTIFICATION',
        student: {
          name:             student.name,
          nisn:             student.nisn,
          class:            student.class,
          balance:          student.balance,
          formattedBalance: formatRupiah(student.balance),
        },
      }, `Siswa teridentifikasi: ${student.name}`);
    }

    // Mode pembayaran — lanjut ke createTransaction
    req.student       = student;
    req.body.deviceId = device.id;
    req.body.uid      = uid;  // kirim UID plaintext (sudah di-hash di createTransaction)
    return createTransaction(req, res);
  } catch (e) {
    logger.error('nfcPay:', e);
    return error(res, 'Pembayaran NFC gagal', 500);
  }
};

// GET /api/transactions
const getTransactions = (req, res) => {
  try {
    const { page=1, limit=10, status } = req.query;
    const offset = (parseInt(page)-1)*parseInt(limit);
    const studentId = req.student.id;
    let where = 'student_id=?';
    const params = [studentId];
    if (status) { where += ' AND status=?'; params.push(status); }
    const txs   = all(`SELECT * FROM transactions WHERE ${where} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]);
    const [{ total }] = all(`SELECT COUNT(*) total FROM transactions WHERE ${where}`, params);
    return paginate(res, txs.map(fmtTx),
      { page:parseInt(page), limit:parseInt(limit), total });
  } catch { return error(res, 'Gagal mengambil riwayat', 500); }
};

// GET /api/transactions/:id
const getTransactionById = (req, res) => {
  try {
    const tx = get('SELECT * FROM transactions WHERE id=? AND student_id=?',
      [req.params.id, req.student.id]);
    if (!tx) return error(res, 'Transaksi tidak ditemukan', 404);
    return success(res, fmtTx(tx));
  } catch { return error(res, 'Gagal mengambil detail transaksi', 500); }
};

module.exports = { createTransaction, nfcPay, getTransactions, getTransactionById };
