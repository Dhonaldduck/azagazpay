// src/utils/nfc-crypto.js
const crypto = require('crypto');

const ENCRYPTION_KEY = process.env.NFC_ENCRYPTION_KEY || 'a1b2c3d4e5f6g7h8';
const IV = process.env.NFC_ENCRYPTION_IV || '1234567890abcdef';

/**
 * Hash UID kartu NFC menggunakan SHA-256
 * Digunakan untuk menyimpan & mencari kartu di database
 * (tidak bisa di-reverse → aman)
 *
 * @param {string} uid - UID kartu raw, contoh: "A1:B2:C3:D4"
 * @returns {string} hex hash
 */
const hashUid = (uid) => {
  const normalized = uid.toUpperCase().replace(/[^A-F0-9]/g, '');
  return crypto.createHash('sha256').update(normalized).digest('hex');
};

/**
 * Mask UID untuk ditampilkan ke user
 * contoh: "A1:B2:C3:D4" → "**** **** **** A1B2"
 *
 * @param {string} uid
 * @returns {string}
 */
const maskUid = (uid) => {
  const normalized = uid.replace(/:/g, '').toUpperCase();
  const last4 = normalized.slice(-4);
  return `**** **** **** ${last4}`;
};

/**
 * Enkripsi UID untuk dikirim dari ESP32 ke server
 * (ESP32 menggunakan AES-128 sebelum kirim via HTTP)
 *
 * @param {string} uid
 * @returns {string} encrypted hex
 */
const encryptUid = (uid) => {
  const key = Buffer.from(ENCRYPTION_KEY.slice(0, 16), 'utf8');
  const iv = Buffer.from(IV.slice(0, 16), 'utf8');
  const cipher = crypto.createCipheriv('aes-128-cbc', key, iv);
  let encrypted = cipher.update(uid, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
};

/**
 * Dekripsi UID yang dikirim ESP32
 *
 * @param {string} encryptedHex
 * @returns {string} uid plaintext
 */
const decryptUid = (encryptedHex) => {
  const key = Buffer.from(ENCRYPTION_KEY.slice(0, 16), 'utf8');
  const iv = Buffer.from(IV.slice(0, 16), 'utf8');
  const decipher = crypto.createDecipheriv('aes-128-cbc', key, iv);
  let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
};

/**
 * Verifikasi device secret dari header ESP32
 * Header: X-Device-Secret: <HMAC-SHA256>
 */
const verifyDeviceSecret = (deviceCode, timestamp, secret) => {
  const expected = crypto
    .createHmac('sha256', process.env.IOT_DEVICE_SECRET || 'secret')
    .update(`${deviceCode}:${timestamp}`)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(expected, 'hex'),
    Buffer.from(secret, 'hex'),
  );
};

module.exports = { hashUid, maskUid, encryptUid, decryptUid, verifyDeviceSecret };
