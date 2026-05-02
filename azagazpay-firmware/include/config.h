#pragma once

// ═══════════════════════════════════════════════════════════════════
//  AzagasPay Firmware — Konfigurasi
//  Edit bagian ini sesuai jaringan & backend Anda.
// ═══════════════════════════════════════════════════════════════════

// ── WiFi ───────────────────────────────────────────────────────────
#define WIFI_SSID         "Dhonaldduck"
#define WIFI_PASSWORD     "abcdefgh"

// ── Server URL ─────────────────────────────────────────────────────
// Menggunakan Cloudflare Tunnel agar koneksi stabil dan global
#define SERVER_URL        "https://utilization-paxil-suffering-asking.trycloudflare.com/api"

// ── Device Credentials ─────────────────────────────────────────────
// Harus sudah didaftarkan via Guru Dashboard → Perangkat IoT
#define DEVICE_CODE       "AZG-NFC-001"
#define DEVICE_SECRET     "secret_iot_azagaspay_2024"

// ── AES-128-CBC Keys ───────────────────────────────────────────────
// HARUS identik dengan nilai di .env backend:
//   NFC_ENCRYPTION_KEY=azagasnfc1234567
//   NFC_ENCRYPTION_IV=azagasiv12345678
#define AES_KEY           "azagasnfc12345678"  // tepat 16 karakter
#define AES_IV            "azagasiv12345678"  // tepat 16 karakter

// ── Firmware Version ───────────────────────────────────────────────
#define FIRMWARE_VERSION  "AzagasPay-FW-1.3.0"

// ── RFID-RC522 (SPI) ──────────────────────────────────────────────
// RC522 menggunakan ESP32 VSPI bus
#define RC522_SS_PIN    4    // SDA/CS pin RC522
#define RC522_RST_PIN  27    // RST pin RC522
#define RC522_SCK_PIN  18    // SPI Clock (VSPI default)
#define RC522_MISO_PIN 19    // SPI MISO  (VSPI default)
#define RC522_MOSI_PIN 23    // SPI MOSI  (VSPI default)

// ── LCD 16x2 I2C (PCF8574 backpack) ───────────────────────────────
// Wiring: VCC→5V, GND, SDA→GPIO21, SCL→GPIO22
// Jika layar tidak muncul, coba alamat 0x3F (PCF8574A)
#define LCD_I2C_ADDR   0x27
#define LCD_SDA_PIN    21
#define LCD_SCL_PIN    22

// ── Timing ─────────────────────────────────────────────────────────
#define HEARTBEAT_INTERVAL_MS      30000  // Heartbeat tiap 30 detik
#define REG_CHECK_INTERVAL_MS       5000  // Polling registrasi admin tiap 5 detik
#define NFC_SCAN_COOLDOWN_MS        3000  // Jeda min antar tap kartu
#define DISPLAY_RESULT_MS           3000  // Lama tampil hasil per fase (3 detik)
#define WIFI_RETRY_DELAY_MS         3000
#define WIFI_MAX_RETRIES              15
#define HTTP_TIMEOUT_MS             10000

// ── NTP (UTC+7 WIB) ────────────────────────────────────────────────
#define NTP_SERVER      "pool.ntp.org"
#define NTP_GMT_OFFSET  25200
#define NTP_DST_OFFSET  0
