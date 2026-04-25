# AzagasPay Backend API — Dokumentasi Lengkap

**Base URL:** `http://localhost:3000/api`  
**Format:** JSON  
**Auth:** Bearer Token (JWT)

---

## 🔐 AUTH

### Login Siswa (NISN + PIN)
```
POST /auth/login
```
```json
// Request
{ "nisn": "1234567890", "pin": "123456" }

// Response 200
{
  "success": true,
  "data": {
    "student": {
      "id": "clx...", "nisn": "1234567890",
      "name": "Budi Santoso", "class": "8A",
      "balance": 85000, "formattedBalance": "Rp 85.000",
      "activeCard": "**** **** **** 4821"
    },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

### Login via Kartu NFC (dari Flutter)
```
POST /auth/nfc-login
```
```json
// Request — UID dikirim Flutter setelah tap
{ "uid": "A1:B2:C3:D4" }
```

### Login Admin
```
POST /auth/admin/login
```
```json
{ "username": "admin", "password": "admin123" }
```

### Refresh Token
```
POST /auth/refresh
```
```json
{ "refreshToken": "eyJ..." }
```

---

## 🍽️ MENU

Semua endpoint menu memerlukan: `Authorization: Bearer <token>`

### Ambil Semua Menu
```
GET /menu?category=makanan&available=true&page=1&limit=20
```
```json
// Response
{
  "data": [
    {
      "id": "clx...", "name": "Nasi Goreng Spesial",
      "price": 12000, "formattedPrice": "Rp 12.000",
      "stock": 15, "emoji": "🍳", "isAvailable": true,
      "category": { "name": "makanan", "label": "Makanan" }
    }
  ],
  "meta": { "page": 1, "limit": 20, "total": 11, "totalPages": 1 }
}
```

### Ambil Kategori
```
GET /menu/categories
```

### Tambah Menu (Admin)
```
POST /menu
Authorization: Bearer <admin_token>
```
```json
{
  "name": "Soto Ayam", "price": 10000,
  "stock": 20, "emoji": "🍲",
  "categoryId": "clx..."
}
```

### Update Menu (Admin)
```
PUT /menu/:id
```
```json
{ "stock": 25, "isAvailable": true }
```

---

## 💳 TRANSAKSI

### Buat Transaksi (Bayar via App)
```
POST /transactions
Authorization: Bearer <student_token>
```
```json
// Request
{
  "items": [
    { "menuItemId": "clx...", "quantity": 1 },
    { "menuItemId": "clx...", "quantity": 2 }
  ],
  "paymentMethod": "NFC_CARD",
  "uid": "A1:B2:C3:D4"
}

// Response 201
{
  "data": {
    "id": "clx...",
    "totalAmount": 18000,
    "formattedTotal": "Rp 18.000",
    "balanceBefore": 85000, "balanceAfter": 67000,
    "formattedBalanceAfter": "Rp 67.000",
    "status": "SUCCESS",
    "items": [
      {
        "name": "Nasi Goreng Spesial", "price": 12000,
        "quantity": 1, "subtotal": 12000,
        "formattedSubtotal": "Rp 12.000"
      }
    ],
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

### Bayar via ESP32 NFC Reader (IoT)
```
POST /transactions/nfc-pay
X-Device-Code: AZG-NFC-001
X-Device-Secret: <hmac>
X-Timestamp: <unix>
```
```json
{
  "uid": "A1:B2:C3:D4",
  "items": [
    { "menuItemId": "clx...", "quantity": 1 }
  ]
}
```

### Riwayat Transaksi
```
GET /transactions?page=1&limit=10&status=SUCCESS
Authorization: Bearer <student_token>
```

### Detail Transaksi
```
GET /transactions/:id
```

---

## 👤 STUDENT

### Profil & Saldo
```
GET /students/me
Authorization: Bearer <student_token>
```

### Daftarkan Kartu NFC
```
POST /students/nfc-cards
Authorization: Bearer <student_token>
```
```json
{ "uid": "E5:F6:G7:H8" }
```

### Ganti PIN
```
PUT /students/me/pin
```
```json
{ "oldPin": "123456", "newPin": "654321" }
```

### Top-Up Saldo (Admin)
```
POST /students/:id/topup
Authorization: Bearer <admin_token>
```
```json
{ "amount": 50000, "note": "Top-up mingguan" }
```

### Daftar Semua Siswa (Admin)
```
GET /students?page=1&limit=20&search=budi
```

---

## 📡 IoT DEVICE

### Daftar Perangkat (Admin)
```
GET /iot/devices
Authorization: Bearer <admin_token>
```

### Daftarkan Perangkat (Admin)
```
POST /iot/devices
```
```json
{
  "deviceCode": "AZG-NFC-003",
  "name": "NFC Reader — Kasir 3",
  "location": "Kasir Belakang",
  "ipAddress": "192.168.1.103"
}
```

### Heartbeat dari ESP32
```
POST /iot/heartbeat
X-Device-Code: AZG-NFC-001
X-Device-Secret: <hmac>
X-Timestamp: <unix>
```
```json
{ "latencyMs": 14, "ipAddress": "192.168.1.101" }
```

### Statistik Perangkat (Admin)
```
GET /iot/devices/:id/stats
```

---

## 🔒 Cara Generate X-Device-Secret (di ESP32/Arduino)

```cpp
// HMAC-SHA256(deviceCode + ":" + timestamp, IOT_DEVICE_SECRET)
#include <mbedtls/md.h>

String generateSecret(String deviceCode, String timestamp) {
  String message = deviceCode + ":" + timestamp;
  const char* key = "secret_iot_device_azagaspay";
  
  byte hmac[32];
  mbedtls_md_context_t ctx;
  mbedtls_md_init(&ctx);
  mbedtls_md_setup(&ctx, mbedtls_md_info_from_type(MBEDTLS_MD_SHA256), 1);
  mbedtls_md_hmac_starts(&ctx, (const byte*)key, strlen(key));
  mbedtls_md_hmac_update(&ctx, (const byte*)message.c_str(), message.length());
  mbedtls_md_hmac_finish(&ctx, hmac);
  mbedtls_md_free(&ctx);
  
  String result = "";
  for (int i = 0; i < 32; i++) {
    if (hmac[i] < 16) result += "0";
    result += String(hmac[i], HEX);
  }
  return result;
}
```

---

## ⚡ Error Codes

| Code | Arti |
|------|------|
| 400 | Request tidak valid / validasi gagal |
| 401 | Token tidak ada / kadaluarsa |
| 403 | Tidak punya izin |
| 404 | Data tidak ditemukan |
| 409 | Konflik (duplikat data) |
| 422 | Validasi field gagal |
| 429 | Terlalu banyak request |
| 500 | Kesalahan server |
