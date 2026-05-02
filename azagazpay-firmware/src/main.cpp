// ═══════════════════════════════════════════════════════════════════
//  AzagasPay NFC Reader Firmware v1.3.0
//  Hardware : ESP32 DevKit + Expansion Board + RFID-RC522 + LCD 16x2 I2C
// ═══════════════════════════════════════════════════════════════════

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <mbedtls/md.h>
#include <mbedtls/aes.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SPI.h>
#include <MFRC522.h>
#include "config.h"

// ── MFRC522 & LCD Instances ────────────────────────────────────────
MFRC522           mfrc522(RC522_SS_PIN, RC522_RST_PIN);
LiquidCrystal_I2C lcd(LCD_I2C_ADDR, 16, 2);

// ── State Machine ──────────────────────────────────────────────────
enum DeviceState {
  STATE_BOOTING, STATE_READY, STATE_PROCESSING, STATE_RESULT
};
static DeviceState gState = STATE_BOOTING;

// ── Runtime Variables ──────────────────────────────────────────────
static String gDeviceId  = "";
static bool   gRegMode   = false;
static String gRegNisn   = "";
static unsigned long gLastHeartbeat = 0;
static unsigned long gLastCardTime  = 0;
static unsigned long gLastRegCheck  = 0;

// Antrian pesanan (isi via Serial sebelum siswa tap)
struct OrderItem { String menuItemId; int qty; };
static OrderItem gItems[20];
static int       gItemCount = 0;

// ── Forward Declarations ────────────────────────────────────────────
void     connectWifi();
bool     ensureWiFi();
bool     syncTime();
bool     sendHeartbeat();
void     checkPendingRegistration();
bool     processPayment(const String& encUid);
bool     processRegistration(const String& encUid, const String& nisn);
String   encryptAES128CBC(const String& plaintext);
String   hmacSHA256(const String& message, const String& key);
String   buildDeviceSecret(const String& ts);
void     addDeviceHeaders(HTTPClient& http);
String   uidBytesToString(byte* uid, byte len);
String   formatRupiah(long amount);
void     handleSerialCommand(const String& cmd);

// ── LCD helpers ─────────────────────────────────────────────────────
void     lcdRow(uint8_t row, const char* text);
void     lcdCenter(uint8_t row, const char* text);
void     dispIdle();
void     dispScanning();
void     dispIdentify(const char* name, const char* kelas, long balance);
void     dispPaySuccess(const char* name, long total, long balAfter);
void     dispRegMode(const char* nisn);
void     dispRegSuccess(const char* name, const char* nisn, const char* cardMasked, long balance);
void     dispError(const char* msg1, const char* msg2 = nullptr);

// ═══════════════════════════════════════════════════════════════════
//  DISPLAY — LCD 16x2 I2C
// ═══════════════════════════════════════════════════════════════════

// Print teks pada baris row, left-aligned, di-pad / dipotong ke 16 karakter
void lcdRow(uint8_t row, const char* text) {
  char buf[17];
  snprintf(buf, 17, "%-16s", text);
  lcd.setCursor(0, row);
  lcd.print(buf);
}

// Print teks pada baris row, rata tengah
void lcdCenter(uint8_t row, const char* text) {
  size_t len = strlen(text);
  if (len > 16) len = 16;
  int pad = (16 - (int)len) / 2;
  char buf[17];
  memset(buf, ' ', 16);
  buf[16] = '\0';
  memcpy(buf + pad, text, len);
  lcd.setCursor(0, row);
  lcd.print(buf);
}

void dispIdle() {
  lcd.clear();
  lcdCenter(0, "AzagasPay");
  lcdCenter(1, "Tempel Kartu");
}

void dispScanning() {
  lcd.clear();
  lcdCenter(0, "Memproses...");
  lcdCenter(1, "Mohon tunggu");
}

void dispIdentify(const char* name, const char* kelas, long balance) {
  lcd.clear();
  char nameBuf[17];
  snprintf(nameBuf, 17, "%s", name);
  lcdRow(0, nameBuf);
  String sal = "Saldo:" + formatRupiah(balance);
  char salBuf[17];
  snprintf(salBuf, 17, "%s", sal.c_str());
  lcdRow(1, salBuf);
}

void dispPaySuccess(const char* name, long total, long balAfter) {
  lcd.clear();
  char nameBuf[17];
  snprintf(nameBuf, 17, "%s", name);
  lcdRow(0, nameBuf);
  String sal = "Sisa:" + formatRupiah(balAfter);
  char salBuf[17];
  snprintf(salBuf, 17, "%s", sal.c_str());
  lcdRow(1, salBuf);
}

void dispRegMode(const char* nisn) {
  lcd.clear();
  lcdCenter(0, "Mode Registrasi");
  char buf[17];
  snprintf(buf, 17, "NISN:%.11s", nisn);
  lcdRow(1, buf);
}

// Layar sukses registrasi — 2 fase: konfirmasi → detail saldo
void dispRegSuccess(const char* name, const char* nisn, const char* cardMasked, long balance) {
  char nameBuf[17];
  snprintf(nameBuf, 17, "%s", name);

  // Fase 1: Konfirmasi pendaftaran berhasil
  lcd.clear();
  lcdCenter(0, "Kartu Terdaftar!");
  lcdRow(1, nameBuf);
  delay(DISPLAY_RESULT_MS);

  // Fase 2: Detail saldo siswa
  lcd.clear();
  lcdRow(0, nameBuf);
  String sal = "Saldo:" + formatRupiah(balance);
  char salBuf[17];
  snprintf(salBuf, 17, "%s", sal.c_str());
  lcdRow(1, salBuf);
  // Fase 2 tetap tampil selama DISPLAY_RESULT_MS yang dipanggil di loop()
}

void dispError(const char* msg1, const char* msg2) {
  lcd.clear();
  char buf1[17];
  snprintf(buf1, 17, "%s", msg1);
  lcdRow(0, buf1);
  if (msg2 != nullptr) {
    char buf2[17];
    snprintf(buf2, 17, "%s", msg2);
    lcdRow(1, buf2);
  } else {
    lcdRow(1, "Hubungi admin");
  }
}

// ═══════════════════════════════════════════════════════════════════
//  KRIPTOGRAFI (cocok dengan nfc-crypto.js backend)
// ═══════════════════════════════════════════════════════════════════

String encryptAES128CBC(const String& plaintext) {
  uint8_t key[16], iv[16];
  memcpy(key, AES_KEY, 16);
  memcpy(iv,  AES_IV,  16);

  size_t  len    = plaintext.length();
  size_t  padded = ((len / 16) + 1) * 16;
  uint8_t* buf   = (uint8_t*)malloc(padded);
  memcpy(buf, plaintext.c_str(), len);
  uint8_t padVal = (uint8_t)(padded - len);
  for (size_t i = len; i < padded; i++) buf[i] = padVal;

  uint8_t* out    = (uint8_t*)malloc(padded);
  uint8_t  ivCopy[16];
  memcpy(ivCopy, iv, 16);

  mbedtls_aes_context aes;
  mbedtls_aes_init(&aes);
  mbedtls_aes_setkey_enc(&aes, key, 128);
  mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_ENCRYPT, padded, ivCopy, buf, out);
  mbedtls_aes_free(&aes);

  String hex = "";
  hex.reserve(padded * 2);
  for (size_t i = 0; i < padded; i++) {
    char h[3];
    sprintf(h, "%02x", out[i]);
    hex += h;
  }
  free(buf);
  free(out);
  return hex;
}

String hmacSHA256(const String& message, const String& key) {
  uint8_t out[32];
  mbedtls_md_context_t ctx;
  const mbedtls_md_info_t* info = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
  mbedtls_md_init(&ctx);
  mbedtls_md_setup(&ctx, info, 1);
  mbedtls_md_hmac_starts(&ctx, (const uint8_t*)key.c_str(), key.length());
  mbedtls_md_hmac_update(&ctx, (const uint8_t*)message.c_str(), message.length());
  mbedtls_md_hmac_finish(&ctx, out);
  mbedtls_md_free(&ctx);

  String hex = "";
  hex.reserve(64);
  for (int i = 0; i < 32; i++) {
    char h[3];
    sprintf(h, "%02x", out[i]);
    hex += h;
  }
  return hex;
}

String buildDeviceSecret(const String& ts) {
  return hmacSHA256(String(DEVICE_CODE) + ":" + ts, DEVICE_SECRET);
}

// ═══════════════════════════════════════════════════════════════════
//  HTTP REQUESTS
// ═══════════════════════════════════════════════════════════════════

void addDeviceHeaders(HTTPClient& http) {
  String ts     = String((long)time(nullptr));
  String secret = buildDeviceSecret(ts);
  http.addHeader("Content-Type",    "application/json");
  http.addHeader("X-Device-Code",   DEVICE_CODE);
  http.addHeader("X-Device-Secret", secret);
  http.addHeader("X-Timestamp",     ts);
}

bool sendHeartbeat() {
  if (WiFi.status() != WL_CONNECTED) return false;
  unsigned long t0 = millis();

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  http.begin(client, String(SERVER_URL) + "/iot/heartbeat");
  http.setTimeout(HTTP_TIMEOUT_MS);
  addDeviceHeaders(http);

  JsonDocument doc;
  doc["latencyMs"]       = 0;
  doc["firmwareVersion"] = FIRMWARE_VERSION;
  doc["ipAddress"]       = WiFi.localIP().toString();
  String body;
  serializeJson(doc, body);

  int code = http.POST(body);
  int lat  = (int)(millis() - t0);
  http.end();

  if (code == 200) {
    Serial.printf("[HB] OK %d ms\n", lat);
    return true;
  }
  Serial.printf("[HB] FAIL Code: %d | ESP IP: %s | Target: %s\n", 
    code, WiFi.localIP().toString().c_str(), SERVER_URL);
  return false;
}

// ── Polling registrasi dari admin panel ────────────────────────────
//
// Backend endpoint yang dibutuhkan:
//   GET /api/iot/pending-reg
//   Headers: X-Device-Code, X-Device-Secret, X-Timestamp
//   Response 200: { "data": { "nisn": "1234567890" } }
//   Response 404: tidak ada pendaftaran pending untuk perangkat ini
//
// Flow admin panel:
//   1. Guru buka dashboard → klik "Daftarkan Kartu" → masukkan NISN
//   2. Backend simpan { deviceCode, nisn, status: "PENDING" }
//   3. Firmware detect via polling ini → masuk mode registrasi otomatis
//   4. Siswa tap kartu → firmware kirim ke /iot/register-card
//   5. Backend link UID kartu ke akun siswa → set status "DONE"
// ───────────────────────────────────────────────────────────────────
void checkPendingRegistration() {
  if (gRegMode) return;
  if (gState != STATE_READY) return;
  if (WiFi.status() != WL_CONNECTED) return;

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  http.begin(client, String(SERVER_URL) + "/iot/pending-reg");
  http.setTimeout(5000);
  addDeviceHeaders(http);

  int code = http.GET();
  if (code == 200) {
    String resp = http.getString();
    http.end();

    JsonDocument r;
    deserializeJson(r, resp);
    const char* nisn = r["data"]["nisn"] | "";
    if (strlen(nisn) >= 6) {
      gRegMode = true;
      gRegNisn = nisn;
      dispRegMode(nisn);
      Serial.printf("[REG] Perintah dari admin panel — NISN: %s\n", nisn);
      Serial.println("[REG] Tempel kartu NFC siswa pada reader.");
    }
  } else {
    http.end();
  }
}

bool processPayment(const String& encUid) {
  if (!ensureWiFi()) {
    dispError("WiFi Gagal", "Cek Koneksi");
    return false;
  }
  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  http.begin(client, String(SERVER_URL) + "/transactions/nfc-pay");
  http.setTimeout(HTTP_TIMEOUT_MS);
  addDeviceHeaders(http);

  JsonDocument doc;
  doc["uid"]      = encUid;
  doc["deviceId"] = gDeviceId;
  JsonArray items = doc["items"].to<JsonArray>();
  for (int i = 0; i < gItemCount; i++) {
    JsonObject item = items.add<JsonObject>();
    item["menuItemId"] = gItems[i].menuItemId;
    item["quantity"]   = gItems[i].qty;
  }
  String body;
  serializeJson(doc, body);

  int    code = http.POST(body);
  String resp = http.getString();
  http.end();

  Serial.printf("[PAY] %d: %s\n", code, resp.c_str());

  if (code == 200 || code == 201) {
    JsonDocument r;
    deserializeJson(r, resp);
    const char* mode = r["data"]["mode"] | "";

    if (strcmp(mode, "REGISTERED") == 0) {
      const char* name       = r["data"]["student"]["name"]     | "Kartu Baru";
      const char* nisn       = r["data"]["student"]["nisn"]     | "-";
      const char* cardMasked = r["data"]["cardMasked"]          | "****";
      long        balance    = r["data"]["student"]["balance"]  | 0L;
      dispRegSuccess(name, nisn, cardMasked, balance);
      Serial.printf("[CARD] Kartu baru terdaftar: %s | Saldo: %ld\n", cardMasked, balance);
    } else if (strcmp(mode, "IDENTIFICATION") == 0) {
      const char* name    = r["data"]["student"]["name"]    | "?";
      const char* kelas   = r["data"]["student"]["class"]   | "";
      long        balance = r["data"]["student"]["balance"]  | 0L;
      dispIdentify(name, kelas, balance);
    } else {
      const char* name     = r["data"]["student"]["name"]   | "?";
      long        total    = r["data"]["totalAmount"]        | 0L;
      long        balAfter = r["data"]["balanceAfter"]       | 0L;
      dispPaySuccess(name, total, balAfter);
      gItemCount = 0;
    }
    return true;
  }

  JsonDocument r;
  deserializeJson(r, resp);
  const char* msg = r["message"] | "Kartu tidak dikenal";
  dispError(msg);
  return false;
}

// ── Registrasi kartu NFC siswa ──────────────────────────────────────
//
// Backend endpoint:
//   POST /api/iot/register-card
//   Body: { "uid": "<AES-encrypted-hex>", "nisn": "<NISN>" }
//   Response: {
//     "data": {
//       "student": { "name": "...", "nisn": "...", "balance": 50000 },
//       "cardMasked": "****ABCD"
//     }
//   }
// ───────────────────────────────────────────────────────────────────
bool processRegistration(const String& encUid, const String& nisn) {
  if (!ensureWiFi()) {
    dispError("WiFi Gagal", "Cek Koneksi");
    return false;
  }
  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  http.begin(client, String(SERVER_URL) + "/iot/register-card");
  http.setTimeout(HTTP_TIMEOUT_MS);
  addDeviceHeaders(http);

  JsonDocument doc;
  doc["uid"]  = encUid;
  doc["nisn"] = nisn;
  String body;
  serializeJson(doc, body);

  int    code = http.POST(body);
  String resp = http.getString();
  http.end();

  Serial.printf("[REG] %d: %s\n", code, resp.c_str());

  if (code == 200 || code == 201) {
    JsonDocument r;
    deserializeJson(r, resp);
    const char* name       = r["data"]["student"]["name"]    | "?";
    const char* rNisn      = r["data"]["student"]["nisn"]    | nisn.c_str();
    const char* cardMasked = r["data"]["cardMasked"]          | "****";
    long        balance    = r["data"]["student"]["balance"]  | 0L;
    dispRegSuccess(name, rNisn, cardMasked, balance);
    Serial.printf("[REG] Berhasil: %s | Saldo: %ld | Kartu: %s\n", name, balance, cardMasked);
    return true;
  }

  JsonDocument r;
  deserializeJson(r, resp);
  const char* msg = r["message"] | "Siswa tidak ditemukan";
  dispError(msg, "Cek NISN & coba");
  return false;
}

// ═══════════════════════════════════════════════════════════════════
//  WiFi & NTP
// ═══════════════════════════════════════════════════════════════════

void connectWifi() {
  lcd.clear();
  lcdCenter(0, "Sambung WiFi...");
  char ssidBuf[17];
  snprintf(ssidBuf, 17, "%.16s", WIFI_SSID);
  lcdRow(1, ssidBuf);

  Serial.printf("WiFi: %s ...", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true); 
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < WIFI_MAX_RETRIES) {
    delay(WIFI_RETRY_DELAY_MS);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf(" OK — %s\n", WiFi.localIP().toString().c_str());
    lcd.clear();
    lcdCenter(0, "WiFi Terhubung!");
    lcdRow(1, WiFi.localIP().toString().c_str());
    delay(800);
  } else {
    lcd.clear();
    lcdRow(0, "WiFi Gagal!");
    lcdRow(1, "Restart...");
    Serial.println(" GAGAL. Restart.");
    delay(2000);
    ESP.restart();
  }
}

bool ensureWiFi() {
  if (WiFi.status() == WL_CONNECTED) return true;
  
  Serial.print("[WiFi] Terputus. Mencoba hubungkan kembali...");
  lcd.clear();
  lcdRow(0, "WiFi Terputus");
  lcdRow(1, "Reconnecting...");
  
  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 5) {
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    delay(1000);
    retry++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(" OK");
    return true;
  }
  Serial.println(" GAGAL");
  return false;
}

bool syncTime() {
  configTime(NTP_GMT_OFFSET, NTP_DST_OFFSET, NTP_SERVER);
  Serial.print("NTP sync");
  time_t now = 0;
  for (int i = 0; i < 10 && now < 1000000000L; i++) {
    delay(500); time(&now); Serial.print(".");
  }
  if (now > 1000000000L) { Serial.println(" OK"); return true; }
  Serial.println(" TIMEOUT");
  return false;
}

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════

String uidBytesToString(byte* uid, byte len) {
  String s = "";
  for (byte i = 0; i < len; i++) {
    char b[3]; sprintf(b, "%02X", uid[i]); s += b;
    if (i < len - 1) s += ":";
  }
  return s;
}

String formatRupiah(long amount) {
  String s = String(amount);
  String r = "";
  int    l = s.length();
  for (int i = 0; i < l; i++) {
    if (i > 0 && (l - i) % 3 == 0) r += ".";
    r += s[i];
  }
  return "Rp" + r;
}

// ═══════════════════════════════════════════════════════════════════
//  SERIAL COMMAND INTERFACE
// ═══════════════════════════════════════════════════════════════════
//
//  add <menuItemId> <qty>   Tambah item pesanan
//  clear                    Kosongkan pesanan
//  items                    Lihat daftar pesanan
//  reg <NISN>               Aktifkan mode registrasi kartu (guru)
//  stopreg                  Nonaktifkan mode registrasi
//  device                   Info perangkat
//  heartbeat                Kirim heartbeat sekarang
//  help                     Daftar perintah
// ═══════════════════════════════════════════════════════════════════

void handleSerialCommand(const String& cmd) {
  if (cmd.startsWith("add ")) {
    String rest = cmd.substring(4);
    int    sep  = rest.lastIndexOf(' ');
    if (sep < 0) { Serial.println("Format: add <menuItemId> <qty>"); return; }
    String id  = rest.substring(0, sep);
    int    qty = rest.substring(sep + 1).toInt();
    id.trim();
    if (id.isEmpty() || qty <= 0) { Serial.println("ID atau qty tidak valid."); return; }
    if (gItemCount >= 20) { Serial.println("Antrian penuh."); return; }
    gItems[gItemCount++] = { id, qty };
    Serial.printf("[+] %s x%d (%d item total)\n", id.c_str(), qty, gItemCount);

  } else if (cmd == "clear") {
    gItemCount = 0;
    Serial.println("[OK] Pesanan dikosongkan.");

  } else if (cmd == "items") {
    if (gItemCount == 0) { Serial.println("[Pesanan] Kosong."); return; }
    Serial.printf("[Pesanan] %d item:\n", gItemCount);
    for (int i = 0; i < gItemCount; i++)
      Serial.printf("  %d. %s x%d\n", i+1, gItems[i].menuItemId.c_str(), gItems[i].qty);

  } else if (cmd.startsWith("reg ")) {
    String nisn = cmd.substring(4);
    nisn.trim();
    if (nisn.length() < 6) { Serial.println("NISN tidak valid (min 6 digit)."); return; }
    gRegMode = true;
    gRegNisn = nisn;
    dispRegMode(nisn.c_str());
    Serial.printf("[REG] Mode aktif — NISN: %s\n", nisn.c_str());
    Serial.println("[REG] Tempel kartu NFC siswa pada reader.");

  } else if (cmd == "stopreg") {
    gRegMode = false;
    gRegNisn = "";
    dispIdle();
    Serial.println("[OK] Mode registrasi dibatalkan.");

  } else if (cmd == "device") {
    Serial.println("── Info Perangkat ──────────────────");
    Serial.printf("Device Code : %s\n", DEVICE_CODE);
    Serial.printf("Firmware    : %s\n", FIRMWARE_VERSION);
    Serial.printf("IP          : %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("RSSI        : %d dBm\n", WiFi.RSSI());
    Serial.printf("Uptime      : %lu s\n", millis() / 1000);
    Serial.printf("Reg mode    : %s\n", gRegMode ? gRegNisn.c_str() : "OFF");
    Serial.printf("Item queue  : %d\n", gItemCount);
    time_t now; time(&now);
    Serial.printf("UNIX time   : %ld\n", (long)now);
    Serial.println("────────────────────────────────────");

  } else if (cmd == "heartbeat") {
    sendHeartbeat();

  } else if (cmd == "help") {
    Serial.println("── Perintah ────────────────────────────");
    Serial.println("  add <id> <qty>  Tambah item pesanan");
    Serial.println("  clear           Kosongkan pesanan");
    Serial.println("  items           Lihat pesanan");
    Serial.println("  reg <NISN>      Mode registrasi kartu guru");
    Serial.println("  stopreg         Batalkan mode registrasi");
    Serial.println("  device          Info perangkat");
    Serial.println("  heartbeat       Kirim heartbeat");
    Serial.println("────────────────────────────────────────");

  } else {
    Serial.printf("[?] Perintah tidak dikenal: '%s'\n", cmd.c_str());
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════════════════════════

void setup() {
  Serial.begin(115200);
  delay(300);
  
  gDeviceId = DEVICE_CODE;

  // LCD I2C init
  Wire.begin(LCD_SDA_PIN, LCD_SCL_PIN);
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcdCenter(0, "AzagasPay");
  lcdCenter(1, "Memulai...");

  Serial.println("╔══════════════════════════════════╗");
  Serial.println("║  AzagasPay NFC Reader v1.3.1    ║");
  Serial.println("╚══════════════════════════════════╝");

  // WiFi & NTP
  connectWifi();
  if (!syncTime()) {
    Serial.println("[WARNING] NTP Sync Gagal! Timestamp akan tidak valid.");
  }

  // MFRC522 SPI init — Sertakan SS Pin eksplisit
  SPI.begin(RC522_SCK_PIN, RC522_MISO_PIN, RC522_MOSI_PIN, RC522_SS_PIN);
  mfrc522.PCD_Init();
  byte ver = mfrc522.PCD_ReadRegister(MFRC522::VersionReg);
  if (ver == 0x00 || ver == 0xFF) {
    Serial.println("[ERROR] RC522 tidak terdeteksi!");
    dispError("Hardware Error", "RC522 Hilang");
    while (true) delay(1000);
  }
  Serial.printf("MFRC522 OK — Version: 0x%02X\n", ver);

  dispIdle();
  gState = STATE_READY;

  Serial.println("[READY] Tempel kartu atau ketik 'help'");
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN LOOP
// ═══════════════════════════════════════════════════════════════════

void loop() {
  // Serial commands dari operator
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (cmd.length() > 0) handleSerialCommand(cmd);
  }

  // Heartbeat ke backend
  if (millis() - gLastHeartbeat > HEARTBEAT_INTERVAL_MS) {
    sendHeartbeat();
    gLastHeartbeat = millis();
  }

  // Polling registrasi dari admin panel (setiap 5 detik)
  if (millis() - gLastRegCheck > REG_CHECK_INTERVAL_MS) {
    checkPendingRegistration();
    gLastRegCheck = millis();
  }

  // Cooldown antar tap
  if (millis() - gLastCardTime < NFC_SCAN_COOLDOWN_MS) {
    delay(50);
    return;
  }

  // Scan RC522 — non-blocking
  if (!mfrc522.PICC_IsNewCardPresent()) return;
  if (!mfrc522.PICC_ReadCardSerial())   return;

  gLastCardTime = millis();
  String uidStr = uidBytesToString(mfrc522.uid.uidByte, mfrc522.uid.size);

  // Halt card dan lepas SPI RC522 sebelum HTTP
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();

  String normalized = uidStr;
  normalized.replace(":", "");
  normalized.toUpperCase();

  Serial.printf("\nKartu: %s\n", uidStr.c_str());

  String encUid = encryptAES128CBC(normalized);

  gState = STATE_PROCESSING;
  dispScanning();

  bool ok;
  if (gRegMode) {
    ok = processRegistration(encUid, gRegNisn);
    if (ok) {
      gRegMode = false;
      gRegNisn = "";
    }
  } else {
    ok = processPayment(encUid);
  }

  // Tahan result screen (fase 2 dari dispRegSuccess, atau hasil pembayaran)
  delay(DISPLAY_RESULT_MS);
  gState = STATE_READY;

  if (gRegMode) {
    dispRegMode(gRegNisn.c_str());
  } else {
    dispIdle();
  }
}
