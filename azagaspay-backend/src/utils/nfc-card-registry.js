const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { get, run, transaction, cuid, formatRupiah } = require('../config/database');
const { hashUid, maskUid } = require('./nfc-crypto');

const AUTO_NISN_PREFIX = 'NFC-';

const normalizeUid = (uid) =>
  String(uid || '').toUpperCase().replace(/[^A-F0-9]/g, '');

const isAutoRegisteredNisn = (nisn) =>
  typeof nisn === 'string' && nisn.startsWith(AUTO_NISN_PREFIX);

const isAutoRegisteredStudent = (student) =>
  isAutoRegisteredNisn(student?.nisn);

const autoNisnForUidHash = (uidHash) =>
  `${AUTO_NISN_PREFIX}${uidHash.slice(0, 12).toUpperCase()}`;

const autoNameForUidMask = (uidMask) =>
  `Kartu NFC ${uidMask.slice(-4)}`;

const formatStudentForNfc = (student, card = null) => ({
  id: student.id,
  nisn: student.nisn,
  name: student.name,
  class: student.class,
  balance: student.balance,
  formattedBalance: formatRupiah(student.balance),
  activeCard: card?.uid_masked ?? null,
  isActive: student.is_active === undefined ? true : !!student.is_active,
  isAutoRegistered: isAutoRegisteredStudent(student),
});

const rowToRegistration = (row) => {
  if (!row) return null;
  return {
    card: {
      id: row.card_id,
      student_id: row.card_student_id,
      uid_hash: row.uid_hash,
      uid_masked: row.uid_masked,
      is_active: row.card_is_active,
      registered_at: row.registered_at,
      last_used_at: row.last_used_at,
    },
    student: {
      id: row.student_id,
      nisn: row.nisn,
      name: row.name,
      class: row.class,
      balance: row.balance,
      is_active: row.student_is_active,
    },
  };
};

const findRegistrationByUidHash = (uidHash, { activeOnly = true } = {}) => {
  const activeWhere = activeOnly ? 'AND c.is_active=1 AND s.is_active=1' : '';
  const row = get(`
    SELECT
      c.id card_id,
      c.student_id card_student_id,
      c.uid_hash,
      c.uid_masked,
      c.is_active card_is_active,
      c.registered_at,
      c.last_used_at,
      s.id student_id,
      s.nisn,
      s.name,
      s.class,
      s.balance,
      s.is_active student_is_active
    FROM nfc_cards c
    JOIN students s ON s.id = c.student_id
    WHERE c.uid_hash=?
    ${activeWhere}
    LIMIT 1
  `, [uidHash]);
  return rowToRegistration(row);
};

const findRegistrationByUid = (uid, opts = {}) => {
  const normalized = normalizeUid(uid);
  if (!normalized) return null;
  return findRegistrationByUidHash(hashUid(normalized), opts);
};

const registerUnknownCard = (uid) => {
  const normalized = normalizeUid(uid);
  if (!normalized) {
    throw new Error('UID kartu tidak valid');
  }

  const uidHash = hashUid(normalized);
  const uidMasked = maskUid(normalized);

  const active = findRegistrationByUidHash(uidHash);
  if (active) return { ...active, created: false };

  const existing = findRegistrationByUidHash(uidHash, { activeOnly: false });
  if (existing) {
    transaction(() => {
      run('UPDATE nfc_cards SET is_active=0 WHERE student_id=?', [existing.student.id]);
      run('UPDATE nfc_cards SET is_active=1 WHERE id=?', [existing.card.id]);
    });
    const restored = findRegistrationByUidHash(uidHash);
    if (!restored) throw new Error('Gagal mengaktifkan kartu NFC');
    return { ...restored, created: false };
  }

  const studentId = cuid();
  const cardId = cuid();
  const nisn = autoNisnForUidHash(uidHash);
  const name = autoNameForUidMask(uidMasked);
  const randomPin = crypto.randomBytes(16).toString('hex');
  const pinHash = bcrypt.hashSync(randomPin, 10);

  transaction(() => {
    run(
      'INSERT INTO students(id,nisn,name,class,pin_hash,balance) VALUES(?,?,?,?,?,0)',
      [studentId, nisn, name, 'Belum Terdata', pinHash],
    );
    run(
      'INSERT INTO nfc_cards(id,student_id,uid_hash,uid_masked,is_active,registered_at,last_used_at) VALUES(?,?,?,?,1,datetime(\'now\'),datetime(\'now\'))',
      [cardId, studentId, uidHash, uidMasked],
    );
  });

  const registration = findRegistrationByUidHash(uidHash);
  if (!registration) throw new Error('Gagal mendaftarkan kartu NFC');
  return { ...registration, created: true };
};

const findOrRegisterCard = (uid) => {
  const existing = findRegistrationByUid(uid);
  if (existing) return { ...existing, created: false };
  return registerUnknownCard(uid);
};

module.exports = {
  AUTO_NISN_PREFIX,
  normalizeUid,
  isAutoRegisteredNisn,
  isAutoRegisteredStudent,
  formatStudentForNfc,
  findRegistrationByUid,
  findOrRegisterCard,
  registerUnknownCard,
};
