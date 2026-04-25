// lib/screens/guru_topup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student.dart';
import '../models/topup_request.dart';
import '../services/topup_service.dart';
import '../utils/app_exceptions.dart';
import '../theme/app_theme.dart';

class GuruTopupScreen extends StatefulWidget {
  const GuruTopupScreen({super.key});

  @override
  State<GuruTopupScreen> createState() => _GuruTopupScreenState();
}

class _GuruTopupScreenState extends State<GuruTopupScreen>
    with SingleTickerProviderStateMixin {
  final _service    = TopupService.instance;
  late final TabController _tabs;

  // ── Tab 0: Top-up Langsung ─────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<Student> _students = [];
  bool _studLoading = true;
  String? _studError;
  String _query = '';
  DateTime? _lastSearch;

  // ── Tab 1: Permintaan ──────────────────────────────────────────
  List<TopupRequest> _requests = [];
  bool _reqLoading = false;
  bool _reqLoaded  = false;
  String? _reqError;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabs.index == 1 && !_reqLoaded && !_reqLoading) {
          _loadRequests();
        }
      });
    _searchCtrl.addListener(_onSearchChanged);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Tab 0 logic ────────────────────────────────────────────────
  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _query) return;
    _query = q;
    _lastSearch = DateTime.now();
    final t = _lastSearch!;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _lastSearch == t) _loadStudents(search: q.isEmpty ? null : q);
    });
  }

  Future<void> _loadStudents({String? search}) async {
    setState(() { _studLoading = true; _studError = null; });
    try {
      final result = await _service.getStudents(search: search);
      if (!mounted) return;
      setState(() { _students = result; _studLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _studLoading = false; _studError = 'Gagal memuat data siswa'; });
    }
  }

  void _onStudentTap(Student student) async {
    final newBalance = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopupSheet(student: student),
    );
    if (newBalance != null && mounted) {
      setState(() {
        final idx = _students.indexWhere((s) => s.id == student.id);
        if (idx != -1) _students[idx] = _students[idx].copyWith(balance: newBalance);
      });
      final formatted = newBalance.toString()
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Top-up berhasil! Saldo baru: Rp $formatted',
            style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ── Tab 1 logic ────────────────────────────────────────────────
  Future<void> _loadRequests() async {
    setState(() { _reqLoading = true; _reqError = null; });
    try {
      final result = await _service.getTopupRequests();
      if (!mounted) return;
      setState(() { _requests = result; _reqLoading = false; _reqLoaded = true; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _reqLoading = false; _reqError = 'Gagal memuat permintaan'; });
    }
  }

  Future<void> _onApprove(TopupRequest req) async {
    try {
      await _service.approveTopupRequest(req.id);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == req.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Top-up ${req.formattedAmount} untuk ${req.studentName} disetujui',
          style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menyetujui permintaan', isError: true);
    }
  }

  Future<void> _onReject(TopupRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tolak Permintaan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Tolak permintaan top-up ${req.formattedAmount} dari ${req.studentName}?',
          style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Tolak',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.rejectTopupRequest(req.id);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == req.id));
      _showSnack('Permintaan ditolak');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menolak permintaan', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(child: TabBarView(
          controller: _tabs,
          children: [
            _buildDirectTopupTab(),
            _buildRequestsTab(),
          ],
        )),
      ]),
    );
  }

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
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Top-up Saldo',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Kelola saldo siswa',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ]),
        ]),
      ),
    ),
  );

  Widget _buildTabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabs,
      labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      tabs: [
        const Tab(text: 'Top-up Langsung'),
        Tab(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Permintaan'),
            if (_reqLoaded && _requests.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10)),
                child: Text('${_requests.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white))),
            ],
          ]),
        ),
      ],
    ),
  );

  // ── Tab 0: Top-up Langsung ─────────────────────────────────────
  Widget _buildDirectTopupTab() => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2))]),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Cari nama atau NISN...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          ),
        ),
      ),
    ),
    Expanded(child: _buildStudentBody()),
  ]);

  Widget _buildStudentBody() {
    if (_studLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_studError != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(_studError!, style: GoogleFonts.poppins(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _loadStudents(search: _query.isNotEmpty ? _query : null),
          child: Text('Coba Lagi',
            style: GoogleFonts.poppins(
              color: AppColors.primary, fontWeight: FontWeight.w700))),
      ]));
    }
    if (_students.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline_rounded, size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text(_query.isEmpty ? 'Tidak ada siswa' : 'Siswa tidak ditemukan',
          style: GoogleFonts.poppins(color: AppColors.textMuted)),
      ]));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadStudents(search: _query.isNotEmpty ? _query : null),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _students.length,
        itemBuilder: (_, i) => _studentCard(_students[i]),
      ),
    );
  }

  Widget _studentCard(Student s) => GestureDetector(
    onTap: () => _onStudentTap(s),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(
            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name,
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('NISN: ${s.nisn} · ${s.studentClass}',
              style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textMuted)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(s.formattedBalance,
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.primary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
            child: Text('Top-up',
              style: GoogleFonts.poppins(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: AppColors.primary))),
        ]),
      ]),
    ),
  );

  // ── Tab 1: Permintaan ──────────────────────────────────────────
  Widget _buildRequestsTab() {
    if (_reqLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_reqError != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(_reqError!, style: GoogleFonts.poppins(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loadRequests,
          child: Text('Coba Lagi',
            style: GoogleFonts.poppins(
              color: AppColors.primary, fontWeight: FontWeight.w700))),
      ]));
    }
    if (_reqLoaded && _requests.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('Tidak ada permintaan pending',
          style: GoogleFonts.poppins(color: AppColors.textMuted)),
      ]));
    }
    if (!_reqLoaded) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.pending_actions_rounded, size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('Geser ke tab ini untuk memuat permintaan',
          style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12)),
      ]));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _requests.length,
        itemBuilder: (_, i) => _requestCard(_requests[i]),
      ),
    );
  }

  Widget _requestCard(TopupRequest req) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.05),
        blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(
            req.studentName[0].toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: AppColors.primary))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(req.studentName,
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
            Text('NISN: ${req.nisn} · ${req.studentClass}',
              style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textMuted)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(req.formattedAmount,
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: AppColors.primary)),
          Text('Saldo: ${req.formattedBalance}',
            style: GoogleFonts.poppins(
              fontSize: 9, color: AppColors.textMuted)),
        ]),
      ]),
      if (req.notes != null && req.notes!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.notes_rounded,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(child: Text(req.notes!,
              style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textMuted))),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => _onReject(req),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10)),
          child: Text('Tolak',
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton(
          onPressed: () => _onApprove(req),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10)),
          child: Text('Setujui',
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700)),
        )),
      ]),
    ]),
  );
}

// ── Bottom sheet top-up form ──────────────────────────────────────
class _TopupSheet extends StatefulWidget {
  final Student student;
  const _TopupSheet({required this.student});

  @override
  State<_TopupSheet> createState() => _TopupSheetState();
}

class _TopupSheetState extends State<_TopupSheet> {
  final _amountCtrl = TextEditingController();
  final _service    = TopupService.instance;
  bool _loading     = false;

  static const _quickAmounts = [5000, 10000, 20000, 50000, 100000];

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  String _fmt(String val) {
    final digits = val.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    final n = int.tryParse(digits) ?? 0;
    return n.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  void _setQuick(int amount) {
    final text = amount.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    _amountCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length));
  }

  Future<void> _onTopup() async {
    final digits = _amountCtrl.text.replaceAll('.', '');
    final amount = int.tryParse(digits);
    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Masukkan nominal minimal Rp 1.000',
          style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await _service.topupStudent(
        studentId: widget.student.id,
        amount: amount,
      );
      if (!mounted) return;
      final newBalance = (data['newBalance'] as int?) ??
          (data['balance'] as int?) ??
          widget.student.balance + amount;
      Navigator.pop(context, newBalance);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan, coba lagi',
          style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              widget.student.name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.student.name,
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text('Saldo: ${widget.student.formattedBalance}',
                style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textMuted)),
            ],
          )),
        ]),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerLeft,
          child: Text('Nominal Cepat',
            style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textMuted))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6,
          children: _quickAmounts.map((a) {
            final label = a.toString()
                .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
            return GestureDetector(
              onTap: () => setState(() => _setQuick(a)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight, width: 1)),
                child: Text('Rp $label',
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.primary))),
            );
          }).toList()),
        const SizedBox(height: 16),

        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          onChanged: (v) {
            final formatted = _fmt(v);
            if (formatted != v) {
              _amountCtrl.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length));
            }
          },
          decoration: InputDecoration(
            hintText: '0',
            prefixText: 'Rp ',
            prefixStyle: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
            hintStyle: GoogleFonts.poppins(
              fontSize: 16, color: AppColors.textMuted),
          ),
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _onTopup,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : Text('Top-up Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
