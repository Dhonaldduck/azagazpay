// src/routes/index.js
const express = require('express');
const { body, param, query } = require('express-validator');
const router = express.Router();

const { validate } = require('../middleware/validate');
const { authStudent, authAdmin, authDevice, authStudentOrAdmin } = require('../middleware/auth');

const authCtrl = require('../controllers/auth.controller');
const menuCtrl = require('../controllers/menu.controller');
const txCtrl = require('../controllers/transaction.controller');
const iotCtrl = require('../controllers/iot.controller');
const studentCtrl = require('../controllers/student.controller');

// ════════════════════════════════════════════════════════════
// AUTH ROUTES
// ════════════════════════════════════════════════════════════

// POST /api/auth/login — login siswa dengan NISN + PIN
router.post('/auth/login',
  [
    body('nisn').notEmpty().isLength({ min: 8, max: 20 }).withMessage('NISN tidak valid'),
    body('pin').notEmpty().isLength({ min: 4, max: 6 }).withMessage('PIN tidak valid'),
    validate,
  ],
  authCtrl.loginWithPin,
);

// POST /api/auth/nfc-login — login siswa dengan kartu NFC
router.post('/auth/nfc-login',
  [
    body('uid').notEmpty().withMessage('UID kartu wajib diisi'),
    validate,
  ],
  authCtrl.loginWithNfc,
);

// POST /api/auth/admin/login — login admin/kasir
router.post('/auth/admin/login',
  [
    body('username').notEmpty(),
    body('password').notEmpty(),
    validate,
  ],
  authCtrl.adminLogin,
);

// POST /api/auth/refresh — refresh access token
router.post('/auth/refresh',
  body('refreshToken').notEmpty(),
  validate,
  authCtrl.refreshToken,
);

// POST /api/auth/logout
router.post('/auth/logout', authCtrl.logout);

// ════════════════════════════════════════════════════════════
// MENU ROUTES
// ════════════════════════════════════════════════════════════

// GET /api/menu — ambil daftar menu (siswa atau admin)
router.get('/menu', authStudentOrAdmin, menuCtrl.getMenu);

// GET /api/menu/categories — daftar kategori (siswa atau admin)
router.get('/menu/categories', authStudentOrAdmin, menuCtrl.getCategories);

// GET /api/menu/:id — detail satu menu
router.get('/menu/:id', authStudentOrAdmin, menuCtrl.getMenuById);

// POST /api/menu — tambah menu (admin)
router.post('/menu',
  authAdmin,
  [
    body('name').notEmpty().isLength({ max: 100 }),
    body('price').isInt({ min: 0 }),
    body('stock').isInt({ min: 0 }),
    body('categoryId').notEmpty(),
    validate,
  ],
  menuCtrl.createMenu,
);

// PUT /api/menu/:id — update menu (admin)
router.put('/menu/:id', authAdmin, menuCtrl.updateMenu);

// DELETE /api/menu/:id — nonaktifkan menu (admin)
router.delete('/menu/:id', authAdmin, menuCtrl.deleteMenu);

// ════════════════════════════════════════════════════════════
// TRANSACTION ROUTES
// ════════════════════════════════════════════════════════════

// POST /api/transactions — buat transaksi (siswa login via app)
router.post('/transactions',
  authStudent,
  [
    body('items').isArray({ min: 1 }).withMessage('Items tidak boleh kosong'),
    body('items.*.menuItemId').notEmpty(),
    body('items.*.quantity').isInt({ min: 1 }),
    validate,
  ],
  txCtrl.createTransaction,
);

// POST /api/transactions/nfc-pay — bayar via ESP32 NFC reader (IoT)
router.post('/transactions/nfc-pay',
  authDevice,
  [
    body('uid').notEmpty().withMessage('UID kartu wajib diisi'),
    body('items').optional().isArray().withMessage('Items harus berupa array'),
    body('items.*.menuItemId').if(body('items').exists()).notEmpty(),
    body('items.*.quantity').if(body('items').exists()).isInt({ min: 1 }),
    validate,
  ],
  txCtrl.nfcPay,
);

// GET /api/transactions — riwayat transaksi siswa
router.get('/transactions', authStudent, txCtrl.getTransactions);

// GET /api/transactions/:id — detail transaksi
router.get('/transactions/:id', authStudent, txCtrl.getTransactionById);

// ════════════════════════════════════════════════════════════
// STUDENT ROUTES
// ════════════════════════════════════════════════════════════

// GET /api/students/me — profil siswa
router.get('/students/me', authStudent, studentCtrl.getProfile);

// POST /api/students/nfc-cards — daftarkan kartu NFC
router.post('/students/nfc-cards',
  authStudent,
  [body('uid').notEmpty(), validate],
  studentCtrl.registerNfcCard,
);

// PUT /api/students/me/pin — ganti PIN
router.put('/students/me/pin',
  authStudent,
  [
    body('oldPin').notEmpty(),
    body('newPin').isLength({ min: 6, max: 6 }).isNumeric(),
    validate,
  ],
  studentCtrl.changePin,
);

// POST /api/students/me/topup-request — siswa kirim permintaan top-up
router.post('/students/me/topup-request',
  authStudent,
  [
    body('amount').isInt({ min: 1000, max: 1000000 })
      .withMessage('Jumlah top-up antara 1.000 dan 1.000.000'),
    validate,
  ],
  studentCtrl.requestTopup,
);

// GET /api/students/me/mutations — riwayat mutasi siswa (debit + kredit)
router.get('/students/me/mutations', authStudent, studentCtrl.getMutations);

// GET /api/students/lookup?nisn=xxx — cari siswa untuk preview transfer (siswa)
router.get('/students/lookup', authStudent, studentCtrl.lookupStudent);

// POST /api/students/me/transfer — transfer saldo antar siswa
router.post('/students/me/transfer',
  authStudent,
  [
    body('receiverNisn').notEmpty().withMessage('NISN penerima wajib diisi'),
    body('amount').isInt({ min: 1000, max: 1000000 })
      .withMessage('Jumlah transfer antara 1.000 dan 1.000.000'),
    validate,
  ],
  studentCtrl.transferBalance,
);

// GET /api/students/topup-requests — daftar permintaan top-up (guru/admin)
router.get('/students/topup-requests', authAdmin, studentCtrl.getTopupRequests);

// POST /api/students/topup-requests/:id/approve — setujui permintaan (guru/admin)
router.post('/students/topup-requests/:id/approve', authAdmin, studentCtrl.approveTopupRequest);

// POST /api/students/topup-requests/:id/reject — tolak permintaan (guru/admin)
router.post('/students/topup-requests/:id/reject', authAdmin, studentCtrl.rejectTopupRequest);

// POST /api/students/:id/topup — top-up saldo (admin)
router.post('/students/:id/topup',
  authAdmin,
  [
    body('amount').isInt({ min: 1000, max: 1000000 })
      .withMessage('Jumlah top-up antara 1.000 dan 1.000.000'),
    validate,
  ],
  studentCtrl.topUp,
);

// GET /api/students — daftar semua siswa (admin)
router.get('/students', authAdmin, studentCtrl.getAllStudents);

// ════════════════════════════════════════════════════════════
// IOT DEVICE ROUTES
// ════════════════════════════════════════════════════════════

// GET /api/iot/devices — daftar perangkat (admin)
router.get('/iot/devices', authAdmin, iotCtrl.getDevices);

// POST /api/iot/devices — daftarkan perangkat baru (admin)
router.post('/iot/devices',
  authAdmin,
  [
    body('deviceCode').notEmpty().matches(/^AZG-NFC-\d{3}$/)
      .withMessage('Format: AZG-NFC-001'),
    body('name').notEmpty(),
    body('location').notEmpty(),
    validate,
  ],
  iotCtrl.registerDevice,
);

// PUT /api/iot/devices/:id — update perangkat (admin)
router.put('/iot/devices/:id', authAdmin, iotCtrl.updateDevice);

// GET /api/iot/devices/:id/stats — statistik perangkat (admin)
router.get('/iot/devices/:id/stats', authAdmin, iotCtrl.getDeviceStats);

// POST /api/iot/heartbeat — ping dari ESP32 (authDevice)
router.post('/iot/heartbeat', authDevice, iotCtrl.heartbeat);

// GET /api/iot/pending-reg — polling registrasi dari ESP32 (authDevice)
router.get('/iot/pending-reg', authDevice, iotCtrl.getPendingReg);

// POST /api/iot/start-reg — admin mulai mode registrasi (authAdmin)
router.post('/iot/start-reg',
  authAdmin,
  [
    body('deviceCode').notEmpty(),
    body('nisn').notEmpty(),
    validate,
  ],
  iotCtrl.startRegistration,
);

// POST /api/iot/register-card — daftarkan kartu NFC siswa via ESP32 (guru tap kartu)
router.post('/iot/register-card', authDevice, iotCtrl.registerCardForStudent);

// POST /api/iot/offline-check — background job cek offline
router.post('/iot/offline-check',
  (req, res, next) => {
    // Hanya bisa dipanggil dari localhost
    if (req.ip !== '127.0.0.1' && req.ip !== '::1' && req.ip !== '::ffff:127.0.0.1') {
      return res.status(403).json({ message: 'Forbidden' });
    }
    next();
  },
  iotCtrl.markOfflineDevices,
);

module.exports = router;
