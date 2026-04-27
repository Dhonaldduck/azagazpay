#!/usr/bin/env node
const fs = require('fs');
const http = require('http');
const path = require('path');
const { spawn } = require('child_process');

const backendDir = path.resolve(__dirname, '..');
const port = Number(process.env.PORT || 3000);
const timeoutMs = Number(process.env.BACKEND_START_TIMEOUT_MS || 15000);
const logDir = path.join(backendDir, 'logs');
const logFile = path.join(logDir, 'backend.log');

const healthCheck = () => new Promise((resolve) => {
  const req = http.get({
    host: '127.0.0.1',
    port,
    path: '/health',
    timeout: 1000,
  }, (res) => {
    res.resume();
    resolve({
      reachable: true,
      healthy: res.statusCode >= 200 && res.statusCode < 300,
      statusCode: res.statusCode,
    });
  });

  req.on('timeout', () => {
    req.destroy();
    resolve({ reachable: false, healthy: false });
  });
  req.on('error', () => resolve({ reachable: false, healthy: false }));
});

const waitForHealth = async () => {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const health = await healthCheck();
    if (health.healthy) return true;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  return false;
};

const main = async () => {
  const currentHealth = await healthCheck();
  if (currentHealth.healthy) {
    console.log(`AzagasPay backend sudah berjalan di http://127.0.0.1:${port}`);
    return;
  }

  if (currentHealth.reachable) {
    console.error(
      `Port ${port} sudah dipakai, tapi /health belum sehat ` +
      `(status ${currentHealth.statusCode}). Tutup proses itu atau cek ${logFile}.`,
    );
    process.exit(1);
  }

  fs.mkdirSync(logDir, { recursive: true });
  const logFd = fs.openSync(logFile, 'a');
  const child = spawn(process.execPath, ['--experimental-sqlite', 'src/index.js'], {
    cwd: backendDir,
    detached: true,
    env: {
      ...process.env,
      NODE_ENV: process.env.NODE_ENV || 'development',
    },
    stdio: ['ignore', logFd, logFd],
  });

  child.unref();

  if (await waitForHealth()) {
    console.log(
      `AzagasPay backend otomatis berjalan di http://127.0.0.1:${port} ` +
      `(log: ${path.relative(backendDir, logFile)})`,
    );
    return;
  }

  console.error(`Gagal menyalakan AzagasPay backend dalam ${timeoutMs}ms. Cek log: ${logFile}`);
  process.exit(1);
};

main().catch((err) => {
  console.error('Gagal menyiapkan backend:', err);
  process.exit(1);
});
