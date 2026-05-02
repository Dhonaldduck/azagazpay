// src/controllers/student.controller.js
const bcrypt = require('bcryptjs');
const { get, run, all, transaction, cuid, formatRupiah } = require('../config/database');
const { success, error } = require('../utils/response');
const { hashUid, maskUid } = require('../utils/nfc-crypto');
const { isAutoRegisteredNisn } = require('../utils/nfc-card-registry');
const logger = require('../config/logger');

// GET /api/students/me
const getProfile = (req, res) => {
  try {
    const student = get('SELECT * FROM students WHERE id=?', [req.student.id]);
    const cards   = all('SELECT uid_masked,registered_at,last_used_at FROM nfc_cards WHERE student_id=? AND is_active=1', [student.id]);
    const [{ total }] = all('SELECT COUNT(*) total FROM transactions WHERE student_id=?', [student.id]);
    return success(res, {
      id: student.id, nisn: student.nisn, name: student.name,
      class: student.class, balance: student.balance,
      formattedBalance: `Rp ${parseInt(student.balance).toLocaleString('id-ID')}`,
      activeCard: cards[0]?.uid_masked ?? null,
      nfcCards: cards, totalTransactions: total });
  } catch { return error(res, 'Gagal mengambil profil', 500); }
};

// POST /api/students/nfc-cards
const registerNfcCard = (req, res) => {
  try {
    const { uid } = req.body;
    const uidHash  = hashUid(uid);
    const uidMasked = maskUid(uid);
    const existing = get(`
      SELECT c.id card_id, c.student_id, s.name, s.nisn
      FROM nfc_cards c
      JOIN students s ON s.id=c.student_id
      WHERE c.uid_hash=?
    `, [uidHash]);
    const canClaimAutoCard = existing &&
      existing.student_id !== req.student.id &&
      isAutoRegisteredNisn(existing.nisn);
    if (existing && existing.student_id !== req.student.id && !canClaimAutoCard) {
      return error(res, 'Kartu NFC sudah terdaftar', 409);
    }

    transaction(() => {
      run('UPDATE nfc_cards SET is_active=0 WHERE student_id=?', [req.student.id]);
      if (existing) {
        run(
          "UPDATE nfc_cards SET student_id=?, is_active=1, registered_at=datetime('now') WHERE id=?",
          [req.student.id, existing.card_id],
        );
        if (canClaimAutoCard) {
          run("UPDATE students SET is_active=0, updated_at=datetime('now') WHERE id=?", [existing.student_id]);
        }
      } else {
        const id = cuid();
        run('INSERT INTO nfc_cards(id,student_id,uid_hash,uid_masked) VALUES(?,?,?,?)',
            [id, req.student.id, uidHash, uidMasked]);
      }
    });
    return success(res, { uidMasked, registeredAt: new Date().toISOString() },
      'Kartu NFC berhasil didaftarkan', 201);
  } catch (e) {
    logger.error('registerNfcCard:', e);
    return error(res, 'Gagal mendaftarkan kartu', 500);
  }
};

// PUT /api/students/me/pin
const changePin = async (req, res) => {
  try {
    const { oldPin, newPin } = req.body;
    const student = get('SELECT * FROM students WHERE id=?', [req.student.id]);
    const ok = await bcrypt.compare(oldPin, student.pin_hash);
    if (!ok) return error(res, 'PIN lama salah', 401);
    if (!/^\d{6}$/.test(newPin)) return error(res, 'PIN baru harus 6 digit angka', 400);
    const hash = await bcrypt.hash(newPin, 10);
    run("UPDATE students SET pin_hash=?,updated_at=datetime('now') WHERE id=?",
        [hash, req.student.id]);
    return success(res, null, 'PIN berhasil diubah');
  } catch { return error(res, 'Gagal mengubah PIN', 500); }
};

// POST /api/students/:id/topup (admin)
const topUp = (req, res) => {
  try {
    const { amount, note } = req.body;
    const studentId = req.params.id;
    const student = get('SELECT * FROM students WHERE id=?', [studentId]);
    if (!student) return error(res, 'Siswa tidak ditemukan', 404);
    const newBalance = student.balance + parseInt(amount);
    run("UPDATE students SET balance=?,updated_at=datetime('now') WHERE id=?",
        [newBalance, studentId]);
    run('INSERT INTO top_ups(id,student_id,amount,admin_id,note) VALUES(?,?,?,?,?)',
        [cuid(), studentId, parseInt(amount), req.admin?.id||null, note||null]);
    return success(res, {
      newBalance, formattedBalance: `Rp ${newBalance.toLocaleString('id-ID')}` },
      `Top-up Rp ${parseInt(amount).toLocaleString('id-ID')} berhasil`);
  } catch { return error(res, 'Gagal melakukan top-up', 500); }
};

// GET /api/students (admin)
const getAllStudents = (req, res) => {
  try {
    const { page=1, limit=20, search } = req.query;
    const offset = (parseInt(page)-1)*parseInt(limit);
    let where = '1=1'; const params = [];
    if (search) { where += ' AND (name LIKE ? OR nisn LIKE ?)'; params.push(`%${search}%`,`%${search}%`); }
    const students = all(`SELECT id,nisn,name,class,balance,is_active,created_at FROM students WHERE ${where} ORDER BY name LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), offset]);
    const [{ total }] = all(`SELECT COUNT(*) total FROM students WHERE ${where}`, params);
    return res.json({ success:true,
      data: students.map(s=>({...s, isActive:!!s.is_active,
        formattedBalance:`Rp ${parseInt(s.balance).toLocaleString('id-ID')}`})),
      meta:{ page:parseInt(page), limit:parseInt(limit), total,
             totalPages:Math.ceil(total/parseInt(limit)) } });
  } catch { return error(res, 'Gagal mengambil data siswa', 500); }
};

// POST /api/students/me/topup-request (siswa)
const requestTopup = (req, res) => {
  try {
    const { amount, notes } = req.body;
    const id = cuid();
    run('INSERT INTO topup_requests(id,student_id,amount,notes) VALUES(?,?,?,?)',
        [id, req.student.id, parseInt(amount), notes || null]);
    return success(res, { id, amount: parseInt(amount) },
      'Permintaan top-up berhasil dikirim', 201);
  } catch (e) {
    logger.error('requestTopup:', e);
    return error(res, 'Gagal mengirim permintaan top-up', 500);
  }
};

// GET /api/students/me/mutations (siswa) — gabungan transaksi + top-up + transfer
const getMutations = (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const sid = req.student.id;

    const mutations = all(`
      SELECT * FROM (
        SELECT id, 'PURCHASE' AS type, total_amount AS amount,
               balance_before AS balanceBefore, balance_after AS balanceAfter,
               status, NULL AS description, created_at AS createdAt
        FROM transactions WHERE student_id=?
        UNION ALL
        SELECT id, 'TOPUP' AS type, amount,
               NULL AS balanceBefore, NULL AS balanceAfter,
               'SUCCESS' AS status, note AS description, created_at AS createdAt
        FROM top_ups WHERE student_id=?
        UNION ALL
        SELECT id, 'TOPUP' AS type, amount,
               NULL AS balanceBefore, NULL AS balanceAfter,
               status, notes AS description, requested_at AS createdAt
        FROM topup_requests WHERE student_id=? AND status='PENDING'
        UNION ALL
        SELECT t.id, 'TRANSFER_OUT' AS type, t.amount,
               t.sender_balance_before AS balanceBefore, t.sender_balance_after AS balanceAfter,
               'SUCCESS' AS status,
               'Transfer ke ' || s2.name AS description, t.created_at AS createdAt
        FROM transfers t
        JOIN students s2 ON s2.id = t.receiver_id
        WHERE t.sender_id = ?
        UNION ALL
        SELECT t.id, 'TRANSFER_IN' AS type, t.amount,
               t.receiver_balance_before AS balanceBefore, t.receiver_balance_after AS balanceAfter,
               'SUCCESS' AS status,
               'Transfer dari ' || s1.name AS description, t.created_at AS createdAt
        FROM transfers t
        JOIN students s1 ON s1.id = t.sender_id
        WHERE t.receiver_id = ?
      )
      ORDER BY createdAt DESC
      LIMIT ? OFFSET ?
    `, [sid, sid, sid, sid, sid, parseInt(limit), offset]);

    return res.json({ success: true, data: mutations });
  } catch (e) {
    logger.error('getMutations:', e);
    return error(res, 'Gagal mengambil riwayat mutasi', 500);
  }
};

// GET /api/students/lookup?nisn=xxx (siswa — untuk preview penerima transfer)
const lookupStudent = (req, res) => {
  try {
    const { nisn } = req.query;
    if (!nisn) return error(res, 'NISN wajib diisi', 400);
    const student = get(
      'SELECT id, name, class FROM students WHERE nisn=? AND is_active=1',
      [nisn]);
    if (!student) return error(res, 'Siswa tidak ditemukan', 404);
    if (student.id === req.student.id)
      return error(res, 'Tidak dapat transfer ke diri sendiri', 400);
    return success(res, { id: student.id, name: student.name, studentClass: student.class });
  } catch (e) {
    logger.error('lookupStudent:', e);
    return error(res, 'Gagal mencari siswa', 500);
  }
};

// POST /api/students/me/transfer (siswa)
const transferBalance = (req, res) => {
  try {
    const { receiverNisn, amount, note } = req.body;
    const parsedAmount = parseInt(amount);
    const senderId = req.student.id;

    const sender = get('SELECT * FROM students WHERE id=?', [senderId]);
    const receiver = get(
      'SELECT * FROM students WHERE nisn=? AND is_active=1',
      [receiverNisn]);

    if (!receiver) return error(res, 'Siswa penerima tidak ditemukan', 404);
    if (receiver.id === senderId)
      return error(res, 'Tidak dapat transfer ke diri sendiri', 400);
    if (sender.balance < parsedAmount)
      return error(res, 'Saldo tidak mencukupi', 400);

    const result = transaction(() => {
      const senderBalanceBefore = sender.balance;
      const senderBalanceAfter  = senderBalanceBefore - parsedAmount;
      const receiverBalanceBefore = receiver.balance;
      const receiverBalanceAfter  = receiverBalanceBefore + parsedAmount;

      run("UPDATE students SET balance=?,updated_at=datetime('now') WHERE id=?",
          [senderBalanceAfter, senderId]);
      run("UPDATE students SET balance=?,updated_at=datetime('now') WHERE id=?",
          [receiverBalanceAfter, receiver.id]);

      const transferId = cuid();
      run(`INSERT INTO transfers(id,sender_id,receiver_id,amount,note,
             sender_balance_before,sender_balance_after,
             receiver_balance_before,receiver_balance_after)
           VALUES(?,?,?,?,?,?,?,?,?)`,
        [transferId, senderId, receiver.id, parsedAmount, note || null,
         senderBalanceBefore, senderBalanceAfter,
         receiverBalanceBefore, receiverBalanceAfter]);

      return { transferId, senderBalanceAfter, receiverName: receiver.name };
    });

    return success(res, {
      id: result.transferId,
      newBalance: result.senderBalanceAfter,
      formattedBalance: formatRupiah(result.senderBalanceAfter),
      receiverName: result.receiverName,
    }, `Transfer ${formatRupiah(parsedAmount)} ke ${result.receiverName} berhasil`);
  } catch (e) {
    logger.error('transferBalance:', e);
    return error(res, 'Gagal melakukan transfer', 500);
  }
};

// GET /api/students/topup-requests (guru/admin)
const getTopupRequests = (req, res) => {
  try {
    const { page = 1, limit = 20, status = 'PENDING' } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const requests = all(`
      SELECT tr.id, tr.amount, tr.notes, tr.status, tr.requested_at,
             s.id AS studentId, s.name AS studentName, s.nisn,
             s.class AS studentClass, s.balance AS studentBalance
      FROM topup_requests tr
      JOIN students s ON tr.student_id = s.id
      WHERE tr.status = ?
      ORDER BY tr.requested_at DESC
      LIMIT ? OFFSET ?
    `, [status.toUpperCase(), parseInt(limit), offset]);

    const [{ total }] = all(
      'SELECT COUNT(*) AS total FROM topup_requests WHERE status=?',
      [status.toUpperCase()]);

    return res.json({
      success: true, data: requests,
      meta: { page: parseInt(page), limit: parseInt(limit), total,
              totalPages: Math.ceil(total / parseInt(limit)) },
    });
  } catch (e) {
    logger.error('getTopupRequests:', e);
    return error(res, 'Gagal mengambil daftar permintaan top-up', 500);
  }
};

// POST /api/students/topup-requests/:id/approve (guru/admin)
const approveTopupRequest = (req, res) => {
  try {
    const request = get('SELECT * FROM topup_requests WHERE id=?', [req.params.id]);
    if (!request) return error(res, 'Permintaan tidak ditemukan', 404);
    if (request.status !== 'PENDING') return error(res, 'Permintaan sudah diproses', 400);

    const student = get('SELECT * FROM students WHERE id=?', [request.student_id]);
    if (!student) return error(res, 'Siswa tidak ditemukan', 404);

    const newBalance = student.balance + parseInt(request.amount);

    transaction(() => {
      run("UPDATE students SET balance=?,updated_at=datetime('now') WHERE id=?",
          [newBalance, student.id]);
      run("UPDATE topup_requests SET status='APPROVED',approved_by=?,approved_at=datetime('now') WHERE id=?",
          [req.admin?.id || null, req.params.id]);
      run('INSERT INTO top_ups(id,student_id,amount,admin_id,note) VALUES(?,?,?,?,?)',
          [cuid(), student.id, parseInt(request.amount),
           req.admin?.id || null, 'Disetujui dari permintaan siswa']);
    });

    return success(res,
      { newBalance, formattedBalance: formatRupiah(newBalance) },
      `Top-up ${formatRupiah(request.amount)} berhasil disetujui`);
  } catch (e) {
    logger.error('approveTopupRequest:', e);
    return error(res, 'Gagal menyetujui permintaan', 500);
  }
};

// POST /api/students/topup-requests/:id/reject (guru/admin)
const rejectTopupRequest = (req, res) => {
  try {
    const request = get('SELECT * FROM topup_requests WHERE id=?', [req.params.id]);
    if (!request) return error(res, 'Permintaan tidak ditemukan', 404);
    if (request.status !== 'PENDING') return error(res, 'Permintaan sudah diproses', 400);

    run("UPDATE topup_requests SET status='REJECTED',approved_by=?,approved_at=datetime('now') WHERE id=?",
        [req.admin?.id || null, req.params.id]);

    return success(res, null, 'Permintaan top-up ditolak');
  } catch (e) {
    logger.error('rejectTopupRequest:', e);
    return error(res, 'Gagal menolak permintaan', 500);
  }
};

module.exports = {
  getProfile, registerNfcCard, changePin, topUp, getAllStudents,
  requestTopup, getMutations, getTopupRequests, approveTopupRequest, rejectTopupRequest,
  lookupStudent, transferBalance,
};
