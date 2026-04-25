// src/utils/response.js

/**
 * Format response sukses
 */
const success = (res, data = null, message = 'Berhasil', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Format response error
 */
const error = (res, message = 'Terjadi kesalahan', statusCode = 500, errors = null) => {
  const body = {
    success: false,
    message,
    timestamp: new Date().toISOString(),
  };
  if (errors) body.errors = errors;
  return res.status(statusCode).json(body);
};

/**
 * Format pagination metadata
 */
const paginate = (res, data, meta, message = 'Berhasil') => {
  return res.status(200).json({
    success: true,
    message,
    data,
    meta: {
      page: meta.page,
      limit: meta.limit,
      total: meta.total,
      totalPages: Math.ceil(meta.total / meta.limit),
    },
    timestamp: new Date().toISOString(),
  });
};

module.exports = { success, error, paginate };
