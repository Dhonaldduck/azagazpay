// lib/screens/iot_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/nfc_device.dart';
import '../widgets/common_widgets.dart';
import '../services/api_client.dart';
import '../utils/app_constants.dart';
import '../utils/app_exceptions.dart';

class IotSetupScreen extends StatefulWidget {
  const IotSetupScreen({super.key});

  @override
  State<IotSetupScreen> createState() => _IotSetupScreenState();
}

class _IotSetupScreenState extends State<IotSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  List<NfcDevice> _devices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fetchDevices();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _fetchDevices() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.get(AppConstants.devicesEndpoint);
      final list = res['data'] as List<dynamic>;
      setState(() {
        _devices = list.map((d) => _deviceFromJson(d as Map<String,dynamic>)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } on NetworkException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Gagal memuat perangkat'; _loading = false; });
    }
  }

  NfcDevice _deviceFromJson(Map<String,dynamic> j) => NfcDevice(
    id: j['id'] as String,
    deviceCode: j['deviceCode'] as String,
    name: j['name'] as String,
    location: j['location'] as String,
    firmwareVersion: j['firmwareVersion'] as String,
    status: j['status'] == 'ONLINE'
        ? NfcDeviceStatus.online : NfcDeviceStatus.offline,
    latencyMs: j['latencyMs'] as int? ?? 0,
    dailyTransactions: j['transactionsToday'] as int? ?? 0,
    nfcProtocol: j['nfcProtocol'] as String? ?? 'ISO 14443',
    ipAddress: j['ipAddress'] as String? ?? '',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _ctrl,
        child: Column(children: [
          _buildHeader(),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _networkStatus(),
                    const SizedBox(height: 14),
                    _devicesSection(),
                    const SizedBox(height: 10),
                    _addDeviceButton(),
                    const SizedBox(height: 16),
                    _infoSection(),
                  ]),
                )),
        ]),
      ),
    );
  }

  Widget _buildError() => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
      const SizedBox(height: 12),
      Text(_error!, style: GoogleFonts.poppins(color: AppColors.textMuted)),
      const SizedBox(height: 16),
      GradientButton(label: 'Coba Lagi', width: 140, onTap: _fetchDevices),
    ],
  ));

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konfigurasi NFC',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              Text('Manajemen Perangkat IoT',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60)),
            ])),
          GestureDetector(
            onTap: _fetchDevices,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.5)),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18))),
        ]),
      ),
    ),
  );

  Widget _networkStatus() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.successLight,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.success.withOpacity(0.35), width: 1.5)),
    child: Row(children: [
      Container(width: 9, height: 9,
        decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.success)),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Terhubung ke Jaringan',
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: const Color(0xFF065F46))),
          Text('WiFi: Kantin-AzagasPay · Sinyal kuat',
            style: GoogleFonts.poppins(
              fontSize: 10, color: const Color(0xFF059669))),
        ])),
      const Icon(Icons.signal_wifi_4_bar_rounded,
        color: AppColors.success, size: 20),
    ]),
  );

  Widget _devicesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('PERANGKAT TERDAFTAR',
        style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: AppColors.textMuted)),
      const SizedBox(height: 8),
      ..._devices.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _deviceCard(d))),
      if (_devices.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Belum ada perangkat terdaftar',
            style: GoogleFonts.poppins(color: AppColors.textMuted)))),
    ],
  );

  Widget _deviceCard(NfcDevice device) {
    final online = device.status == NfcDeviceStatus.online;
    return Opacity(
      opacity: online ? 1.0 : 0.55,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        border: Border.all(
          color: online ? AppColors.borderLight : AppColors.border,
          width: online ? 1.5 : 1),
        color: online ? Colors.white : const Color(0xFFF8FAFC),
        child: Column(children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: online ? AppColors.surfaceSecondary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: online ? AppColors.borderLight : AppColors.border, width: 1.5)),
              child: Icon(Icons.nfc_rounded,
                color: online ? AppColors.primary : AppColors.textMuted, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name,
                  style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: online ? AppColors.textPrimary : AppColors.textMuted)),
                Text('${device.deviceCode} · ${device.firmwareVersion}',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted)),
              ])),
            online ? StatusChip.online() : StatusChip.offline(),
          ]),
          if (online) ...[
            const SizedBox(height: 10),
            Row(children: [
              _stat('Mode', device.nfcProtocol),
              const SizedBox(width: 6),
              _stat('Latency', '${device.latencyMs}ms', valueColor: AppColors.primary),
              const SizedBox(width: 6),
              _stat('Tx Hari ini', '${device.dailyTransactions}'),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? valueColor}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background, borderRadius: BorderRadius.circular(9)),
      child: Column(children: [
        Text(label, style: GoogleFonts.poppins(
          fontSize: 8, color: AppColors.textMuted)),
        const SizedBox(height: 1),
        Text(value, style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: valueColor ?? AppColors.textPrimary)),
      ]),
    ),
  );

  Widget _addDeviceButton() => GestureDetector(
    onTap: () => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDeviceSheet(onAdd: (d) {
        setState(() => _devices.add(d));
      }),
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3), width: 2,
          style: BorderStyle.solid)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.add, color: Colors.white, size: 16)),
        const SizedBox(width: 8),
        Text('Pasangkan Perangkat Baru',
          style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.primary)),
      ]),
    ),
  );

  Widget _infoSection() => AppCard(
    padding: const EdgeInsets.all(14),
    color: const Color(0xFFF0F9FF),
    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 16),
        const SizedBox(width: 6),
        Text('Informasi Hardware',
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: const Color(0xFF0C4A6E))),
      ]),
      const SizedBox(height: 8),
      Text(
        'Perangkat NFC menggunakan modul PN532 terhubung ke ESP32 via I2C/SPI. '
        'ESP32 bertindak sebagai NFC Gateway yang mengirim data ke server via WiFi.',
        style: GoogleFonts.poppins(
          fontSize: 10, color: const Color(0xFF075985), height: 1.6)),
      const SizedBox(height: 8),
      _infoRow('Protokol', 'ISO 14443-A/B (MIFARE)'),
      _infoRow('Komunikasi', 'WiFi → REST API / MQTT'),
      _infoRow('Enkripsi', 'AES-128 (UID kartu)'),
    ]),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 10, color: const Color(0xFF0284C7),
          fontWeight: FontWeight.w600))),
      Text(': $value',
        style: GoogleFonts.poppins(
          fontSize: 10, color: const Color(0xFF075985))),
    ]),
  );
}

// ── Bottom sheet: tambah perangkat ────────────────────────────
class _AddDeviceSheet extends StatefulWidget {
  final Function(NfcDevice) onAdd;
  const _AddDeviceSheet({required this.onAdd});

  @override
  State<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends State<_AddDeviceSheet> {
  final _nameCtrl = TextEditingController();
  final _ipCtrl   = TextEditingController();
  bool _scanning  = false;
  bool _saving    = false;

  @override
  void dispose() { _nameCtrl.dispose(); _ipCtrl.dispose(); super.dispose(); }

  void _onScan() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _ipCtrl.text = '192.168.1.10${DateTime.now().second % 9 + 3}';
    });
  }

  Future<void> _onSave() async {
    if (_nameCtrl.text.isEmpty || _ipCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await ApiClient.instance.post(
        AppConstants.devicesEndpoint, {
          'deviceCode': 'AZG-NFC-00${DateTime.now().millisecond % 9 + 3}',
          'name': _nameCtrl.text.trim(),
          'location': 'Kasir Baru',
          'ipAddress': _ipCtrl.text.trim(),
        });
      final d = res['data'] as Map<String, dynamic>;
      widget.onAdd(NfcDevice(
        id: d['id'] as String,
        deviceCode: d['deviceCode'] as String,
        name: d['name'] as String,
        location: d['location'] as String,
        firmwareVersion: d['firmwareVersion'] as String? ?? 'PN532 v1.6',
        status: NfcDeviceStatus.offline,
        ipAddress: d['ipAddress'] as String? ?? '',
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Pasangkan Perangkat Baru',
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Pastikan ESP32 sudah menyala dan terhubung WiFi yang sama',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Nama perangkat (mis: Kasir 3)',
            prefixIcon: Icon(Icons.label_outline_rounded,
              color: AppColors.textMuted, size: 20))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _ipCtrl,
            decoration: const InputDecoration(
              hintText: 'Alamat IP ESP32',
              prefixIcon: Icon(Icons.wifi_outlined,
                color: AppColors.textMuted, size: 20)))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onScan,
            child: Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12)),
              child: _scanning
                ? const Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)))
                : const Icon(Icons.search_rounded, color: Colors.white, size: 22))),
        ]),
        const SizedBox(height: 16),
        GradientButton(
          label: 'Sambungkan Perangkat',
          onTap: _onSave,
          isLoading: _saving),
      ]),
    );
  }
}
