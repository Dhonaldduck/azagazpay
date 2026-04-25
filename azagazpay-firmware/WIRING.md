# AzagasPay — Diagram Wiring ESP32 + RFID-RC522 + LCD 16x2 I2C

## Ringkasan Pin ESP32 DevKit

```
GPIO  4  → RC522 SDA/CS
GPIO 18  → RC522 SCK  / SPI Clock
GPIO 19  → RC522 MISO
GPIO 23  → RC522 MOSI
GPIO 27  → RC522 RST
GPIO 21  → LCD SDA  (I2C)
GPIO 22  → LCD SCL  (I2C)
3.3V     → RC522 VCC
5V       → LCD VCC  (backlight butuh 5V)
GND      → RC522 GND, LCD GND
```

> RC522 menggunakan SPI (GPIO 18/19/23).
> LCD menggunakan I2C (GPIO 21/22) — bus terpisah, tidak ada konflik.

---

## LCD 16x2 I2C (modul PCF8574 backpack)

```
LCD I2C Module    ESP32 DevKit
──────────────    ────────────
VCC       ─────── 5V       (backlight membutuhkan 5V)
GND       ─────── GND
SDA       ─────── GPIO 21
SCL       ─────── GPIO 22
```

> **Alamat I2C default**: `0x27` (PCF8574T). Jika LCD tidak menyala,
> coba alamat `0x3F` (PCF8574AT) — ubah `LCD_I2C_ADDR` di `config.h`.
>
> Untuk mencari alamat: scan I2C dengan `Wire.begin(21,22); Wire.beginTransmission(addr)`.

---

## RFID-RC522 (SPI Mode)

```
RC522 Module      ESP32 DevKit
────────────      ────────────
VCC (3.3V) ────── 3.3V     (JANGAN 5V! RC522 rusak di 5V)
GND        ────── GND
SCK        ────── GPIO 18
MOSI       ────── GPIO 23
MISO       ────── GPIO 19
SDA (CS)   ────── GPIO 4
RST        ────── GPIO 27
IRQ        ────── (tidak digunakan, biarkan tidak tersambung)
```

> RC522 sudah dalam mode SPI secara default.
> Pastikan tegangan supply adalah **3.3V**, bukan 5V.

---

## Kartu NFC yang Didukung RC522

| Tipe Kartu           | UID    | Catatan                     |
|----------------------|--------|-----------------------------|
| MIFARE Classic 1K/4K | 4 byte | Paling umum di sekolah      |
| MIFARE Ultralight    | 7 byte | Kartu tipis / sticker       |
| NTAG213/215/216      | 7 byte | Kompatibel ISO 14443-A      |

> RC522 hanya mendukung ISO 14443-A. Kartu ISO 14443-B tidak didukung.

---

## Diagram Blok Sistem

```
  ┌────────────────────────────────────────────┐
  │            ESP32 DevKit                    │
  │                                            │
  │  ┌──────────┐   SPI    ┌──────────────┐   │
  │  │ RFID     │◄────────►│ GPIO 18/19/  │   │
  │  │ RC522    │  CS=4    │ 23 (SPI Bus) │   │
  │  └──────────┘  RST=27  └──────────────┘   │
  │                                            │
  │  ┌──────────┐   I2C    ┌──────────────┐   │
  │  │ LCD 16x2 │◄────────►│ GPIO 21/22   │   │
  │  │ (I2C)   │ 0x27     │ (I2C Bus)    │   │
  │  └──────────┘          └──────────────┘   │
  │                                            │
  │  WiFi: Built-in                            │
  └──────────────────┬─────────────────────────┘
                     │ HTTP/REST
                     ▼
  ┌────────────────────────────────────────────┐
  │   Backend Node.js  (port 3000)             │
  │   POST /api/transactions/nfc-pay           │
  │   POST /api/iot/heartbeat                  │
  │   POST /api/iot/register-card              │
  └────────────────────────────────────────────┘
```
