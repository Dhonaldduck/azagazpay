// lib/models/nfc_device.dart
enum NfcDeviceStatus { online, offline, connecting }

class NfcDevice {
  final String id;
  final String deviceCode;
  final String name;
  final String location;
  final String firmwareVersion;
  final NfcDeviceStatus status;
  final int latencyMs;
  final int dailyTransactions;
  final String nfcProtocol;
  final String ipAddress;

  const NfcDevice({
    required this.id,
    required this.deviceCode,
    required this.name,
    required this.location,
    required this.firmwareVersion,
    required this.status,
    this.latencyMs = 0,
    this.dailyTransactions = 0,
    this.nfcProtocol = 'ISO 14443',
    this.ipAddress = '',
  });

  bool get isOnline => status == NfcDeviceStatus.online;
}
