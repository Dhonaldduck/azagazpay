// src/controllers/iot.controller.js
const { get, run, all, transaction, cuid } = require('../config/database');
const { success, error }                 = require('../utils/response');
const { decryptUid, hashUid, maskUid }   = require('../utils/nfc-crypto');
const { isAutoRegisteredNisn }           = require('../utils/nfc-card-registry');
const logger                             = require('../config/logger');

const fmtDevice = (d) => ({
  id: d.id, deviceCode: d.device_code, name: d.name, location: d.location,
  firmwareVersion: d.firmware_version, ipAddress: d.ip_address,
  macAddress: d.mac_address, status: d.status, nfcProtocol: d.nfc_protocol,
  latencyMs: d.latency_ms, lastHeartbeatAt: d.last_heartbeat_at,
  isOnline: d.status === 'ONLINE',
  transactionsToday: d.tx_today ?? 0,
});

// GET /api/iot/devices
const getDevices = (req, res) => {
  try {
    const today = new Date(); today.setHours(0,0,0,0);
    const devices = all(`
      SELECT d.*,
        (SELECT COUNT(*) FROM transactions t
         WHERE t.device_id=d.id AND t.status='SUCCESS'
         AND t.created_at >= ?) tx_today
      FROM nfc_devices d WHERE d.is_active=1 ORDER BY d.device_code`,
      [today.toISOString()]);
    return success(res, devices.map(fmtDevice), 'Data perangkat berhasil diambil');
  } catch (e) {
    logger.error('getDevices:', e);
    return error(res, 'Gagal mengambil data perangkat', 500);
  }
};

// POST /api/iot/devices
const registerDevice = (req, res) => {
  try {
    const { deviceCode, name, location, firmwareVersion, ipAddress, macAddress } = req.body;
    const existing = get('SELECT id FROM nfc_devices WHERE device_code=?', [deviceCode]);
    if (existing) return error(res, 'Device code sudah digunakan', 409);
    const id = cuid();
    run(`INSERT INTO nfc_devices(id,device_code,name,location,firmware_version,ip_address,mac_address)
         VALUES(?,?,?,?,?,?,?)`,
        [id, deviceCode, name, location, firmwareVersion||'PN532 v1.6', ipAddress||null, macAddress||null]);
    const device = get('SELECT * FROM nfc_devices WHERE id=?', [id]);
    return success(res, fmtDevice(device), 'Perangkat berhasil didaftarkan', 201);
  } catch (e) {
    return error(res, 'Gagal mendaftarkan perangkat', 500);
  }
};

// PUT /api/iot/devices/:id
const updateDevice = (req, res) => {
  try {
    const { name, location, ipAddress, isActive } = req.body;
    const fields = []; const vals = [];
    if (name      !== undefined) { fields.push('name=?');       vals.push(name); }
    if (location  !== undefined) { fields.push('location=?');   vals.push(location); }
    if (ipAddress !== undefined) { fields.push('ip_address=?'); vals.push(ipAddress); }
    if (isActive  !== undefined) { fields.push('is_active=?');  vals.push(isActive?1:0); }
    if (!fields.length) return error(res, 'Tidak ada data', 400);
    fields.push("updated_at=datetime('now')");
    run(`UPDATE nfc_devices SET ${fields.join(',')} WHERE id=?`, [...vals, req.params.id]);
    const device = get('SELECT * FROM nfc_devices WHERE id=?', [req.params.id]);
    if (!device) return error(res, 'Perangkat tidak ditemukan', 404);
    return success(res, fmtDevice(device), 'Perangkat berhasil diupdate');
  } catch { return error(res, 'Gagal mengupdate perangkat', 500); }
};

// POST /api/iot/heartbeat
const heartbeat = (req, res) => {
  try {
    const { latencyMs, firmwareVersion, ipAddress } = req.body;
    const device = req.device;
    const fields = ["status='ONLINE'", "last_heartbeat_at=datetime('now')"];
    const vals   = [];
    if (latencyMs       !== undefined) { fields.push('latency_ms=?');        vals.push(parseInt(latencyMs)); }
    if (firmwareVersion !== undefined) { fields.push('firmware_version=?');  vals.push(firmwareVersion); }
    if (ipAddress       !== undefined) { fields.push('ip_address=?');        vals.push(ipAddress); }
    run(`UPDATE nfc_devices SET ${fields.join(',')} WHERE id=?`, [...vals, device.id]);
    return success(res, {
      deviceCode: device.device_code, status: 'ONLINE',
      serverTime: new Date().toISOString() }, 'Heartbeat diterima');
  } catch (e) {
    logger.error('heartbeat:', e);
    return error(res, 'Gagal memproses heartbeat', 500);
  }
};

// GET /api/iot/devices/:id/stats
const getDeviceStats = (req, res) => {
  try {
    const device = get('SELECT * FROM nfc_devices WHERE id=?', [req.params.id]);
    if (!device) return error(res, 'Perangkat tidak ditemukan', 404);
    const today = new Date(); today.setHours(0,0,0,0);
    const [total]   = all('SELECT COUNT(*) v FROM transactions WHERE device_id=? AND status=?',
                           [device.id,'SUCCESS']);
    const [todayTx] = all('SELECT COUNT(*) v FROM transactions WHERE device_id=? AND status=? AND created_at>=?',
                           [device.id,'SUCCESS',today.toISOString()]);
    const [rev]     = all('SELECT COALESCE(SUM(total_amount),0) v FROM transactions WHERE device_id=? AND status=?',
                           [device.id,'SUCCESS']);
    return success(res, {
      device: fmtDevice(device),
      stats: {
        transactionsTotal: total.v, transactionsToday: todayTx.v,
        revenueTotal: rev.v, formattedRevenue: `Rp ${parseInt(rev.v).toLocaleString('id-ID')}`,
      } });
  } catch { return error(res, 'Gagal mengambil statistik', 500); }
};

// GET /api/iot/pending-reg — polling dari ESP32 (authDevice)
const getPendingReg = (req, res) => {
  try {
    const device = req.device;
    const pending = get(
      "SELECT nisn FROM pending_registrations WHERE device_code=? AND status='PENDING' ORDER BY created_at DESC LIMIT 1",
      [device.device_code]);
    
    if (!pending) return res.status(404).json({ message: 'No pending registration' });
    
    return success(res, { nisn: pending.nisn }, 'Pending registration found');
  } catch (e) {
    logger.error('getPendingReg:', e);
    return error(res, 'Gagal mengambil data registrasi', 500);
  }
};

// POST /api/iot/start-reg — dipanggil dari dashboard guru (authAdmin)
const startRegistration = (req, res) => {
  const { deviceCode, nisn } = req.body;
  if (!deviceCode || !nisn) return error(res, 'Device code dan NISN wajib diisi', 400);

  try {
    const device = get('SELECT id FROM nfc_devices WHERE device_code=? AND is_active=1', [deviceCode]);
    if (!device) return error(res, 'Perangkat tidak ditemukan atau tidak aktif', 404);

    const student = get('SELECT id FROM students WHERE nisn=? AND is_active=1', [nisn]);
    if (!student) return error(res, 'Siswa tidak ditemukan atau tidak aktif', 404);

    transaction(() => {
      // Tandai semua registrasi sebelumnya untuk device ini sebagai CANCELLED
      run("UPDATE pending_registrations SET status='CANCELLED' WHERE device_code=? AND status='PENDING'", [deviceCode]);
      
      run('INSERT INTO pending_registrations(id, device_code, nisn) VALUES(?,?,?)',
        [cuid(), deviceCode, nisn]);
    });

    return success(res, null, `Mode registrasi untuk NISN ${nisn} dimulai pada perangkat ${deviceCode}`);
  } catch (e) {
    logger.error('startRegistration:', e);
    return error(res, 'Gagal memulai mode registrasi', 500);
  }
};

// POST /api/iot/offline-check
const markOfflineDevices = (req, res) => {
  try {
    const threshold = new Date(Date.now() - 2*60*1000).toISOString();
    const result = run(
      "UPDATE nfc_devices SET status='OFFLINE' WHERE status='ONLINE' AND last_heartbeat_at < ?",
      [threshold]);
    return success(res, { markedOffline: result.changes });
  } catch { return error(res, 'Gagal menandai offline', 500); }
};

// POST /api/iot/register-card — daftarkan kartu NFC untuk siswa (oleh perangkat ESP32)
const registerCardForStudent = (req, res) => {
  const { nisn, uid: encryptedUid } = req.body;
  if (!nisn || !encryptedUid)
    return error(res, 'NISN dan UID wajib diisi', 400);

  try {
    // Cari siswa berdasarkan NISN
    const student = get('SELECT * FROM students WHERE nisn=? AND is_active=1', [nisn]);
    if (!student) return error(res, 'Siswa tidak ditemukan atau tidak aktif', 404);

    // Dekripsi & hash UID dari ESP32
    const uid     = decryptUid(encryptedUid);
    const uidHash = hashUid(uid);
    const uidMask = maskUid(uid);

    // Tolak jika kartu sudah terdaftar ke siswa lain yang bukan akun otomatis.
    // Akun otomatis dibuat saat kartu baru pertama kali ditap di RFID.
    const existing = get(
      `SELECT c.id card_id, c.student_id, s.name, s.nisn
       FROM nfc_cards c
       JOIN students s ON c.student_id=s.id
       WHERE c.uid_hash=?`,
      [uidHash]);
    const canReassignAutoCard = existing &&
      existing.student_id !== student.id &&
      isAutoRegisteredNisn(existing.nisn);
    if (existing && existing.student_id !== student.id && !canReassignAutoCard)
      return error(res, `Kartu sudah terdaftar ke siswa lain: ${existing.name}`, 409);

    transaction(() => {
      // Nonaktifkan kartu lama siswa ini
      run('UPDATE nfc_cards SET is_active=0 WHERE student_id=?', [student.id]);

      if (existing) {
        run(
          "UPDATE nfc_cards SET student_id=?, is_active=1, registered_at=datetime('now') WHERE id=?",
          [student.id, existing.card_id],
        );
        if (canReassignAutoCard) {
          run("UPDATE students SET is_active=0, updated_at=datetime('now') WHERE id=?", [existing.student_id]);
        }
      } else {
        const cardId = cuid();
        run(`INSERT INTO nfc_cards(id,student_id,uid_hash,uid_masked,is_active,registered_at)
             VALUES(?,?,?,?,1,datetime('now'))`,
            [cardId, student.id, uidHash, uidMask]);
      }

      // Tandai registrasi pending sebagai DONE untuk device ini dan NISN ini
      run("UPDATE pending_registrations SET status='DONE', updated_at=datetime('now') WHERE device_code=? AND nisn=? AND status='PENDING'",
        [req.device.device_code, nisn]);
    });

    // Update device heartbeat
    run("UPDATE nfc_devices SET last_heartbeat_at=datetime('now'),status='ONLINE' WHERE id=?",
        [req.device.id]);

    logger.info(`Kartu terdaftar — siswa: ${student.name} (${nisn}), card: ${uidMask}`);
    return success(res, {
      student: {
        name: student.name,
        nisn: student.nisn,
        class: student.class,
        balance: student.balance,
      },
      cardMasked: uidMask,
    }, `Kartu berhasil didaftarkan untuk ${student.name}`, 201);
  } catch (e) {
    logger.error('registerCardForStudent:', e);
    return error(res, 'Gagal mendaftarkan kartu', 500);
  }
};

module.exports = {
  getDevices, registerDevice, updateDevice,
  heartbeat, getDeviceStats, markOfflineDevices,
  registerCardForStudent, getPendingReg, startRegistration,
};
