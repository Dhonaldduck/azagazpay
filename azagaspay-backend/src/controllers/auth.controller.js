// src/controllers/auth.controller.js
const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const crypto = require('crypto');
const { get, run, all, cuid } = require('../config/database');
const { success, error }       = require('../utils/response');
const { hashUid }              = require('../utils/nfc-crypto');
const logger                   = require('../config/logger');

const makeTokens = (payload) => ({
  accessToken: jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d' }),
  refreshToken: jwt.sign(payload,
    process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }),
});

const fmtStudent = (s, card) => ({
  id: s.id, nisn: s.nisn, name: s.name,
  class: s.class, balance: s.balance,
  formattedBalance: `Rp ${parseInt(s.balance).toLocaleString('id-ID')}`,
  activeCard: card?.uid_masked ?? null,
});

// POST /api/auth/login
const loginWithPin = async (req, res) => {
  try {
    const { nisn, pin } = req.body;
    const student = get('SELECT * FROM students WHERE nisn = ?', [nisn]);
    if (!student)           return error(res, 'NISN tidak ditemukan', 401);
    if (!student.is_active) return error(res, 'Akun dinonaktifkan', 403);

    const ok = await bcrypt.compare(pin, student.pin_hash);
    if (!ok) return error(res, 'PIN salah', 401);

    const card = get(
      'SELECT * FROM nfc_cards WHERE student_id = ? AND is_active = 1', [student.id]);
    const { accessToken, refreshToken } = makeTokens({
      id: student.id, nisn: student.nisn, role: 'student' });

    run(`INSERT INTO sessions(id,student_id,refresh_token,expires_at) VALUES(?,?,?,?)`,
      [cuid(), student.id, refreshToken,
       new Date(Date.now() + 30*24*60*60*1000).toISOString()]);

    return success(res, { student: fmtStudent(student, card), accessToken, refreshToken },
      'Login berhasil');
  } catch (e) {
    logger.error('loginWithPin:', e);
    return error(res, 'Terjadi kesalahan server', 500);
  }
};

// POST /api/auth/nfc-login
const loginWithNfc = async (req, res) => {
  try {
    const { uid } = req.body;
    const uidHash = hashUid(uid);
    const card    = get('SELECT * FROM nfc_cards WHERE uid_hash = ? AND is_active = 1', [uidHash]);
    if (!card) return error(res, 'Kartu NFC tidak terdaftar', 401);

    const student = get('SELECT * FROM students WHERE id = ? AND is_active = 1', [card.student_id]);
    if (!student) return error(res, 'Akun siswa dinonaktifkan', 403);

    run('UPDATE nfc_cards SET last_used_at = ? WHERE id = ?',
      [new Date().toISOString(), card.id]);

    const { accessToken, refreshToken } = makeTokens({
      id: student.id, nisn: student.nisn, role: 'student' });

    run(`INSERT INTO sessions(id,student_id,refresh_token,expires_at) VALUES(?,?,?,?)`,
      [cuid(), student.id, refreshToken,
       new Date(Date.now() + 30*24*60*60*1000).toISOString()]);

    return success(res, { student: fmtStudent(student, card), accessToken, refreshToken },
      'Login NFC berhasil');
  } catch (e) {
    logger.error('loginWithNfc:', e);
    return error(res, 'Terjadi kesalahan server', 500);
  }
};

// POST /api/auth/refresh
const refreshToken = (req, res) => {
  try {
    const { refreshToken: token } = req.body;
    if (!token) return error(res, 'Refresh token tidak ada', 400);
    const decoded = jwt.verify(token,
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);
    const session = get('SELECT * FROM sessions WHERE refresh_token = ?', [token]);
    if (!session || new Date(session.expires_at) < new Date())
      return error(res, 'Token tidak valid atau kadaluarsa', 401);
    const newToken = jwt.sign(
      { id: decoded.id, nisn: decoded.nisn, role: decoded.role },
      process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
    return success(res, { accessToken: newToken }, 'Token diperbarui');
  } catch {
    return error(res, 'Refresh token tidak valid', 401);
  }
};

// POST /api/auth/logout
const logout = (req, res) => {
  try {
    const { refreshToken: token } = req.body;
    if (token) run('DELETE FROM sessions WHERE refresh_token = ?', [token]);
    return success(res, null, 'Logout berhasil');
  } catch { return error(res, 'Terjadi kesalahan', 500); }
};

// POST /api/auth/admin/login
const adminLogin = async (req, res) => {
  try {
    const { username, password } = req.body;
    const admin = get('SELECT * FROM admins WHERE username = ? AND is_active = 1', [username]);
    if (!admin) return error(res, 'Username atau password salah', 401);
    const ok = await bcrypt.compare(password, admin.password_hash);
    if (!ok)   return error(res, 'Username atau password salah', 401);
    const accessToken = jwt.sign(
      { id: admin.id, username: admin.username, role: 'admin', adminRole: admin.role },
      process.env.JWT_SECRET, { expiresIn: '8h' });
    return success(res,
      { admin: { id: admin.id, username: admin.username, name: admin.name, role: admin.role },
        accessToken }, 'Login admin berhasil');
  } catch (e) {
    logger.error('adminLogin:', e);
    return error(res, 'Terjadi kesalahan server', 500);
  }
};

module.exports = { loginWithPin, loginWithNfc, refreshToken, logout, adminLogin };
