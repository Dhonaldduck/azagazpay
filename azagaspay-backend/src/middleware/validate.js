// src/middleware/validate.js
const { validationResult } = require('express-validator');
const { error } = require('../utils/response');

/**
 * Wrapper untuk menjalankan express-validator rules
 * dan mengembalikan error terformat jika ada
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return error(
      res,
      'Validasi gagal',
      422,
      errors.array().map((e) => ({ field: e.path, message: e.msg })),
    );
  }
  next();
};

module.exports = { validate };
