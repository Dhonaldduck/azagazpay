import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

enum NfcReadState { idle, scanning, success, error }

class NfcService extends ChangeNotifier {
  NfcReadState _state = NfcReadState.idle;
  String? _cardUid;
  String? _errorMessage;

  NfcReadState get state => _state;
  String? get cardUid => _cardUid;
  String? get errorMessage => _errorMessage;
  bool get isScanning => _state == NfcReadState.scanning;

  /// Format UID kartu untuk ditampilkan
  /// contoh: "A1B2C3D4" → "**** **** **** 4821"
  String get maskedCardUid {
    if (_cardUid == null) return '**** **** **** ????';
    final last4 = _cardUid!.replaceAll(':', '').toUpperCase();
    final display = last4.length >= 4
        ? last4.substring(last4.length - 4)
        : last4;
    return '**** **** **** $display';
  }

  // ── NFC Read ─────────────────────────────────────────────

  /// Mulai scan kartu NFC
  /// Mengembalikan UID kartu jika berhasil, null jika gagal
  Future<String?> startScan() async {
    _setState(NfcReadState.scanning);
    _cardUid = null;
    _errorMessage = null;

    try {
      // Cek ketersediaan NFC di perangkat
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        _errorMessage = 'NFC tidak tersedia atau dinonaktifkan';
        _setState(NfcReadState.error);
        return null;
      }

      // Mulai polling kartu NFC (timeout 30 detik)
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 30),
        iosMultipleTagMessage: 'Tempelkan satu kartu saja',
        iosAlertMessage: 'Tempelkan kartu AzagasPay',
      );

      _cardUid = tag.id; // UID kartu dalam format hex
      _setState(NfcReadState.success);
      return _cardUid;
    } catch (e) {
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        _errorMessage = 'Scan dibatalkan';
      } else {
        _errorMessage = 'Gagal membaca kartu: ${e.toString()}';
      }
      _setState(NfcReadState.error);
      return null;
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  /// Batalkan scan yang sedang berjalan
  Future<void> cancelScan() async {
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
    _setState(NfcReadState.idle);
  }

  void reset() {
    _cardUid = null;
    _errorMessage = null;
    _setState(NfcReadState.idle);
  }

  void _setState(NfcReadState state) {
    _state = state;
    notifyListeners();
  }

  // ── Simulasi untuk development/testing ───────────────────
  /// Gunakan ini saat develop di emulator yang tidak punya NFC
  Future<String?> simulateScan({int delaySeconds = 3}) async {
    _setState(NfcReadState.scanning);
    await Future.delayed(Duration(seconds: delaySeconds));
    _cardUid = 'A1:B2:C3:D4'; // UID dummy
    _setState(NfcReadState.success);
    return _cardUid;
  }
}
