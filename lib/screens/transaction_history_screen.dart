// lib/screens/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/mutation.dart';
import '../providers/auth_provider.dart';
import '../services/topup_service.dart';
import '../theme/app_theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _service = TopupService.instance;
  final _scroll  = ScrollController();

  List<Mutation> _all = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _tabs = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 120 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() { _page = 1; _hasMore = true; _loading = true; _error = null; _all = []; });
    }
    try {
      final result = await _service.getMutations(page: _page);
      if (!mounted) return;
      setState(() {
        _all.addAll(result);
        _hasMore = result.length >= 20;
        _loading = false;
        _page++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.getMutations(page: _page);
      if (!mounted) return;
      setState(() {
        _all.addAll(result);
        _hasMore = result.length >= 20;
        _loadingMore = false;
        _page++;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Mutation> get _filtered {
    switch (_tabs.index) {
      case 1: return _all.where((m) => m.isDebit).toList();
      case 2: return _all.where((m) => m.isCredit).toList();
      default: return _all;
    }
  }

  bool _differentDay(DateTime a, DateTime b) {
    final la = a.toLocal(); final lb = b.toLocal();
    return la.year != lb.year || la.month != lb.month || la.day != lb.day;
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().student;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(student?.formattedBalance ?? 'Rp 0'),
        _buildTabBar(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildHeader(String balance) => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16)),
            ),
            const SizedBox(width: 12),
            Text('Riwayat Mutasi',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Saldo Saat Ini',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
                  Text(balance,
                    style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22)),
              ],
            ),
          ),
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
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [Tab(text: 'Semua'), Tab(text: 'Keluar'), Tab(text: 'Masuk')],
    ),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null && _all.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('Gagal memuat data',
          style: GoogleFonts.poppins(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _load(refresh: true),
          child: Text('Coba Lagi',
            style: GoogleFonts.poppins(
              color: AppColors.primary, fontWeight: FontWeight.w700))),
      ]));
    }

    final items = _filtered;
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 56,
          color: AppColors.textMuted.withOpacity(0.4)),
        const SizedBox(height: 12),
        Text('Belum ada transaksi',
          style: GoogleFonts.poppins(color: AppColors.textMuted)),
      ]));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
            );
          }
          return _mutationCard(items[i], i, items);
        },
      ),
    );
  }

  Widget _mutationCard(Mutation m, int idx, List<Mutation> all) {
    final showDate = idx == 0 || _differentDay(all[idx - 1].createdAt, m.createdAt);
    final dt = m.createdAt.toLocal();
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showDate) _dateDivider(dt),
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: m.isCredit
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(
              m.isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: m.isCredit ? AppColors.success : AppColors.error,
              size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.typeLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('$h:$mi',
                style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textMuted)),
              if (m.balanceAfter != null) ...[
                const SizedBox(height: 1),
                Text('Sisa: ${m.formattedBalanceAfter}',
                  style: GoogleFonts.poppins(
                    fontSize: 9, color: AppColors.textMuted)),
              ],
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(m.formattedAmount,
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: m.isCredit ? AppColors.success : AppColors.error)),
            if (m.isPending) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: Text('Menunggu',
                  style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.warning))),
            ],
          ]),
        ]),
      ),
    ]);
  }

  Widget _dateDivider(DateTime dt) {
    final now = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dDate     = DateTime(dt.year, dt.month, dt.day);

    String label;
    if (dDate == today) {
      label = 'Hari ini';
    } else if (dDate == yesterday) {
      label = 'Kemarin';
    } else {
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
      label = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textMuted)),
    );
  }
}
