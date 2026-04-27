// src/index.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

const routes = require('./routes');
const { error } = require('./utils/response');
const logger = require('./config/logger');
const database = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Security middleware ────────────────────────────────────────
app.use(helmet());

app.use(cors({
  origin: (origin, callback) => {
    const allowed = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',');
    // Izinkan no-origin (Postman, app mobile) dan allowed origins
    if (!origin || allowed.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('CORS tidak diizinkan'));
    }
  },
  credentials: true,
}));

// ── Rate limiting ─────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 menit
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Terlalu banyak request, coba lagi nanti' },
});

// Rate limit ketat untuk endpoint login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, message: 'Terlalu banyak percobaan login' },
});

app.use('/api/auth/login', loginLimiter);
app.use('/api/auth/nfc-login', loginLimiter);
app.use(limiter);

// ── Body parsing & compression ────────────────────────────────
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));
app.use(compression());

// ── Request logging ───────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined', {
    stream: { write: (msg) => logger.http(msg.trim()) },
  }));
}

// ── Trust proxy (untuk Nginx reverse proxy) ───────────────────
app.set('trust proxy', 1);

// ── Health check ──────────────────────────────────────────────
app.get('/health', (req, res) => {
  try {
    database.get('SELECT 1 AS ok');
    res.json({
      status: 'ok',
      service: 'AzagasPay API',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: 'connected',
    });
  } catch (err) {
    logger.error('Health check gagal:', err);
    res.status(503).json({ status: 'error', database: 'disconnected' });
  }
});

// ── API routes ────────────────────────────────────────────────
app.use('/api', routes);

// ── 404 handler ───────────────────────────────────────────────
app.use('*', (req, res) => {
  return error(res, `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`, 404);
});

// ── Global error handler ──────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  return error(
    res,
    process.env.NODE_ENV === 'production' ? 'Terjadi kesalahan server' : err.message,
    err.status || 500,
  );
});

// ── Start server ──────────────────────────────────────────────
const server = app.listen(PORT, () => {
  logger.info(`\n🚀 AzagasPay API berjalan di http://localhost:${PORT}`);
  logger.info(`📄 Dokumentasi: http://localhost:${PORT}/api-docs`);
  logger.info(`🔧 Environment: ${process.env.NODE_ENV || 'development'}\n`);
});

// ── Graceful shutdown ─────────────────────────────────────────
const gracefulShutdown = async (signal) => {
  logger.info(`${signal} diterima — menutup server...`);
  server.close(async () => {
    database.closeDb();
    logger.info('Server dan database ditutup');
    process.exit(0);
  });
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

module.exports = app;
