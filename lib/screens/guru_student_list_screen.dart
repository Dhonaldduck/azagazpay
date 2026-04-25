// lib/screens/guru_student_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student.dart';
import '../services/topup_service.dart';
import '../theme/app_theme.dart';

class GuruStudentListScreen extends StatefulWidget {
  const GuruStudentListScreen({super.key});

  @override
  State<GuruStudentListScreen> createState() => _GuruStudentListScreenState();
}

class _GuruStudentListScreenState extends State<GuruStudentListScreen> {
  final _searchCtrl = TextEditingController();
  final _service    = TopupService.instance;

  List<Student> _students = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  DateTime? _lastSearch;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _searchCtrl.addListener(_onSearchChanged);
    _loadStudents();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _query) return;
    _query = q;
    _lastSearch = DateTime.now();
    final t = _lastSearch!;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _lastSearch == t) {
        _loadStudents(search: q.isEmpty ? null : q);
      }
    });
  }

  Future<void> _loadStudents({String? search}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getStudents(search: search, page: 1);
      if (!mounted) return;
      setState(() { _students = result; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Gagal memuat data siswa'; });
    }
  }

  void _showDetail(Student s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentDetailSheet(student: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildHeader() => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
            Text('Daftar Siswa',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Lihat data & saldo siswa',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ]),
          const Spacer(),
          if (!_loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20)),
              child: Text('${_students.length} siswa',
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white)),
            ),
        ]),
      ),
    ),
  );

  Widget _buildSearchBar() => Padding(
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
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _loadStudents();
                  })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        ),
      ),
    ),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(_error!, style: GoogleFonts.poppins(color: AppColors.textMuted)),
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
        Text(_query.isEmpty ? 'Belum ada data siswa' : 'Siswa tidak ditemukan',
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
    onTap: () => _showDetail(s),
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
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(13)),
          child: Center(child: Text(
            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: Colors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(s.name,
                style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              if (!s.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text('Nonaktif',
                    style: GoogleFonts.poppins(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: AppColors.error))),
            ]),
            const SizedBox(height: 2),
            Text('NISN: ${s.nisn}  ·  ${s.studentClass}',
              style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textMuted)),
          ],
        )),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(s.formattedBalance,
            style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.primary)),
          const SizedBox(height: 4),
          const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted, size: 18),
        ]),
      ]),
    ),
  );
}

// ── Detail bottom sheet ──────────────────────────────────────────
class _StudentDetailSheet extends StatelessWidget {
  final Student student;
  const _StudentDetailSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Avatar + name
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name,
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(student.studentClass,
                style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textMuted)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: student.isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Text(student.isActive ? 'Aktif' : 'Nonaktif',
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: student.isActive ? AppColors.success : AppColors.error))),
        ]),
        const SizedBox(height: 20),

        // Detail rows
        _row('NISN', student.nisn),
        _divider(),
        _row('Kelas', student.studentClass),
        _divider(),
        _row('Saldo', student.formattedBalance,
          valueColor: AppColors.primary, bold: true),
        _divider(),
        _row('Kartu NFC', student.displayCard,
          valueSize: 12),
      ]),
    );
  }

  Widget _row(String label, String value,
      {Color? valueColor, bool bold = false, double valueSize = 13}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textMuted)),
          Text(value, style: GoogleFonts.poppins(
            fontSize: valueSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );

  Widget _divider() => const Divider(height: 1, color: AppColors.borderLight);
}
