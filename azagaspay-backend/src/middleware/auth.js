// src/middleware/auth.js
const jwt = require('jsonwebtoken');
const { get } = require('../config/database');
const { error } = require('../utils/response');

const authStudent = (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) return error(res, 'Token tidak ditemukan', 401);
    const decoded = jwt.verify(header.split(' ')[1], process.env.JWT_SECRET);
    if (decoded.role !== 'student') return error(res, 'Akses ditolak', 403);
    const student = get(
      'SELECT id,nisn,name,class,balance,is_active FROM students WHERE id=?', [decoded.id]);
    if (!student || !student.is_active) return error(res, 'Akun tidak aktif', 401);
    req.student = student;
    next();
  } catch (e) {
    return error(res, e.name === 'TokenExpiredError' ? 'Token kadaluarsa' : 'Token tidak valid', 401);
  }
};

const authAdmin = (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) return error(res, 'Token tidak ditemukan', 401);
    const decoded = jwt.verify(header.split(' ')[1], process.env.JWT_SECRET);
    if (decoded.role !== 'admin') return error(res, 'Akses ditolak — hanya admin', 403);
    req.admin = decoded;
    next();
  } catch { return error(res, 'Token tidak valid', 401); }
};

const authDevice = (req, res, next) => {
  try {
    const deviceCode = req.headers['x-device-code'];
    const secret     = req.headers['x-device-secret'];
    const timestamp  = req.headers['x-timestamp'];
    if (!deviceCode || !secret || !timestamp)
      return error(res, 'Header autentikasi perangkat tidak lengkap', 401);
    const now = Math.floor(Date.now()/1000);
    if (Math.abs(now - parseInt(timestamp)) > 300)
      return error(res, 'Timestamp tidak valid', 401);
    const { verifyDeviceSecret } = require('../utils/nfc-crypto');
    if (!verifyDeviceSecret(deviceCode, timestamp, secret))
      return error(res, 'Secret perangkat tidak valid', 401);
    const device = get('SELECT * FROM nfc_devices WHERE device_code=? AND is_active=1', [deviceCode]);
    if (!device) return error(res, 'Perangkat tidak terdaftar', 401);
    req.device = device;
    next();
  } catch { return error(res, 'Autentikasi perangkat gagal', 401); }
};

const authStudentOrAdmin = (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) return error(res, 'Token tidak ditemukan', 401);
    const decoded = jwt.verify(header.split(' ')[1], process.env.JWT_SECRET);
    if (decoded.role === 'student') {
      const student = get(
        'SELECT id,nisn,name,class,balance,is_active FROM students WHERE id=?', [decoded.id]);
      if (!student || !student.is_active) return error(res, 'Akun tidak aktif', 401);
      req.student = student;
    } else if (decoded.role === 'admin') {
      req.admin = decoded;
    } else {
      return error(res, 'Akses ditolak', 403);
    }
    next();
  } catch (e) {
    return error(res, e.name === 'TokenExpiredError' ? 'Token kadaluarsa' : 'Token tidak valid', 401);
  }
};

module.exports = { authStudent, authAdmin, authDevice, authStudentOrAdmin };
