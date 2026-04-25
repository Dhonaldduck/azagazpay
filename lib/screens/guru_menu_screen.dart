// lib/screens/guru_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import '../services/menu_service.dart';
import '../utils/app_exceptions.dart';
import '../theme/app_theme.dart';

class GuruMenuScreen extends StatefulWidget {
  const GuruMenuScreen({super.key});

  @override
  State<GuruMenuScreen> createState() => _GuruMenuScreenState();
}

class _GuruMenuScreenState extends State<GuruMenuScreen> {
  final _searchCtrl = TextEditingController();
  final _service    = MenuService.instance;

  List<MenuItem>    _all        = [];
  List<MenuCategory> _categories = [];
  bool   _loading = true;
  String? _error;
  String _filter = 'all';   // 'all' | 'available' | 'unavailable'
  String _search = '';

  List<MenuItem> get _filtered => _all.where((item) {
    final matchSearch = _search.isEmpty ||
        item.name.toLowerCase().contains(_search.toLowerCase());
    final matchFilter =
        _filter == 'all' ||
        (_filter == 'available' && item.isAvailable) ||
        (_filter == 'unavailable' && !item.isAvailable);
    return matchSearch && matchFilter;
  }).toList();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _search) setState(() => _search = q);
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getMenuAdmin(),
        _service.getCategoriesFull(),
      ]);
      if (!mounted) return;
      setState(() {
        _all        = results[0] as List<MenuItem>;
        _categories = results[1] as List<MenuCategory>;
        _loading    = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Gagal memuat data menu'; });
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuFormSheet(
        categories: _categories,
        onSave: (item) => setState(() => _all.insert(0, item)),
      ),
    );
  }

  void _openEditSheet(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuFormSheet(
        categories: _categories,
        existing: item,
        onSave: (updated) => setState(() {
          final i = _all.indexWhere((m) => m.id == updated.id);
          if (i != -1) _all[i] = updated;
        }),
        onDelete: (id) => setState(() => _all.removeWhere((m) => m.id == id)),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _toggleAvailable(MenuItem item) async {
    try {
      final updated = await _service.updateMenuItem(
        item.id, isAvailable: !item.isAvailable);
      if (!mounted) return;
      setState(() {
        final i = _all.indexWhere((m) => m.id == updated.id);
        if (i != -1) _all[i] = updated;
      });
      _showSnack(updated.isAvailable
          ? '${item.name} sekarang tersedia'
          : '${item.name} disembunyikan dari menu');
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (_) {
      if (mounted) _showSnack('Gagal mengubah status', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Tambah Menu',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ),
      body: Column(children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildFilterChips(),
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
            Text('Kelola Menu',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Tambah, edit & nonaktifkan menu',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ]),
          const Spacer(),
          if (!_loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20)),
              child: Text('${_all.length} menu',
                style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white)),
            ),
        ]),
      ),
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
          hintText: 'Cari nama menu...',
          hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                    color: AppColors.textMuted, size: 18),
                  onPressed: () => _searchCtrl.clear())
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        ),
      ),
    ),
  );

  Widget _buildFilterChips() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    child: Row(children: [
      _filterChip('all', 'Semua', _all.length),
      const SizedBox(width: 8),
      _filterChip('available', 'Tersedia',
          _all.where((m) => m.isAvailable).length),
      const SizedBox(width: 8),
      _filterChip('unavailable', 'Nonaktif',
          _all.where((m) => !m.isAvailable).length),
    ]),
  );

  Widget _filterChip(String value, String label, int count) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textMuted)),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.borderLight,
                borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                style: GoogleFonts.poppins(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textMuted))),
          ],
        ]),
      ),
    );
  }

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
          onPressed: _loadData,
          child: Text('Coba Lagi',
            style: GoogleFonts.poppins(
              color: AppColors.primary, fontWeight: FontWeight.w700))),
      ]));
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.restaurant_menu_rounded, size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('Tidak ada menu yang sesuai',
          style: GoogleFonts.poppins(color: AppColors.textMuted)),
      ]));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        itemBuilder: (_, i) => _menuCard(items[i]),
      ),
    );
  }

  Widget _menuCard(MenuItem item) => Container(
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
      // Emoji avatar
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: item.isAvailable
              ? AppColors.surfaceSecondary
              : AppColors.background,
          borderRadius: BorderRadius.circular(14)),
        child: Center(child: Text(item.emoji,
          style: TextStyle(
            fontSize: 26,
            color: item.isAvailable ? null : Colors.black.withValues(alpha: 0.3))))),
      const SizedBox(width: 12),

      // Info
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(item.name,
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: item.isAvailable
                    ? AppColors.textPrimary
                    : AppColors.textMuted),
              overflow: TextOverflow.ellipsis)),
            if (!item.isAvailable) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: Text('Nonaktif',
                  style: GoogleFonts.poppins(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.error))),
            ],
          ]),
          const SizedBox(height: 3),
          if (item.categoryLabel.isNotEmpty)
            Text(item.categoryLabel,
              style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Row(children: [
            Text(item.formattedPrice,
              style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
            const SizedBox(width: 10),
            _stockChip(item.stock),
          ]),
        ],
      )),
      const SizedBox(width: 8),

      // Actions
      Column(children: [
        // Toggle available
        GestureDetector(
          onTap: () => _toggleAvailable(item),
          child: Container(
            width: 36, height: 20,
            decoration: BoxDecoration(
              color: item.isAvailable
                  ? AppColors.success
                  : AppColors.borderLight,
              borderRadius: BorderRadius.circular(10)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: item.isAvailable
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Edit
        GestureDetector(
          onTap: () => _openEditSheet(item),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.edit_rounded,
              color: AppColors.primary, size: 16)),
        ),
      ]),
    ]),
  );

  Widget _stockChip(int stock) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: stock > 0
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6)),
    child: Text('Stok: $stock',
      style: GoogleFonts.poppins(
        fontSize: 9, fontWeight: FontWeight.w700,
        color: stock > 0 ? AppColors.success : AppColors.error)),
  );
}

// ── Menu Form Bottom Sheet ───────────────────────────────────────
class _MenuFormSheet extends StatefulWidget {
  final List<MenuCategory> categories;
  final MenuItem? existing;
  final void Function(MenuItem) onSave;
  final void Function(String)? onDelete;

  const _MenuFormSheet({
    required this.categories,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_MenuFormSheet> createState() => _MenuFormSheetState();
}

class _MenuFormSheetState extends State<_MenuFormSheet> {
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  String? _categoryId;
  bool _isAvailable = true;
  bool _loading = false;
  bool _deleteLoading = false;

  final _service = MenuService.instance;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _emojiCtrl = TextEditingController(text: e?.emoji ?? '🍽️');
    _nameCtrl  = TextEditingController(text: e?.name ?? '');
    _priceCtrl = TextEditingController(
      text: e != null ? _fmt(e.price.toString()) : '');
    _stockCtrl = TextEditingController(
      text: e?.stock.toString() ?? '');
    _categoryId  = e?.categoryId ?? widget.categories.firstOrNull?.id;
    _isAvailable = e?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _emojiCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  String _fmt(String val) {
    final digits = val.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    final n = int.tryParse(digits) ?? 0;
    return n.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  Future<void> _onSave() async {
    final name  = _nameCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.replaceAll('.', ''));
    final stock = int.tryParse(_stockCtrl.text.trim());
    final emoji = _emojiCtrl.text.trim();

    if (name.isEmpty) {
      _snack('Nama menu tidak boleh kosong', isError: true); return;
    }
    if (price == null || price < 0) {
      _snack('Harga tidak valid', isError: true); return;
    }
    if (stock == null || stock < 0) {
      _snack('Stok tidak valid', isError: true); return;
    }
    if (_categoryId == null) {
      _snack('Pilih kategori', isError: true); return;
    }

    setState(() => _loading = true);
    try {
      final MenuItem result;
      if (_isEdit) {
        result = await _service.updateMenuItem(
          widget.existing!.id,
          name: name, price: price, stock: stock,
          emoji: emoji, isAvailable: _isAvailable,
        );
      } else {
        result = await _service.createMenuItem(
          name: name, price: price, stock: stock,
          categoryId: _categoryId!, emoji: emoji,
        );
      }
      if (!mounted) return;
      widget.onSave(result);
      Navigator.pop(context);
      _snack(_isEdit ? 'Menu berhasil diperbarui' : 'Menu berhasil ditambahkan');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Terjadi kesalahan, coba lagi', isError: true);
    }
  }

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nonaktifkan Menu',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Nonaktifkan "${widget.existing!.name}"?\nMenu tidak akan tampil ke siswa.',
          style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
              style: GoogleFonts.poppins(color: AppColors.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Nonaktifkan',
              style: GoogleFonts.poppins(
                color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleteLoading = true);
    try {
      await _service.deleteMenuItem(widget.existing!.id);
      if (!mounted) return;
      widget.onDelete?.call(widget.existing!.id);
      Navigator.pop(context);
      _snack('Menu berhasil dinonaktifkan');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleteLoading = false);
      _snack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleteLoading = false);
      _snack('Gagal menonaktifkan menu', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEdit ? 'Edit Menu' : 'Tambah Menu',
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                if (_isEdit)
                  GestureDetector(
                    onTap: _deleteLoading ? null : _onDelete,
                    child: _deleteLoading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.error))
                        : const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 22)),
              ],
            ),
            const SizedBox(height: 20),

            // Emoji + Name row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Emoji
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('EMOJI'),
                const SizedBox(height: 6),
                Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 1.5)),
                  child: TextField(
                    controller: _emojiCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26),
                    maxLength: 2,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ]),
              const SizedBox(width: 12),
              // Name
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('NAMA MENU'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Nasi Goreng',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textMuted),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 14),

            // Category dropdown
            _label('KATEGORI'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.border, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.border, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary, width: 2)),
                filled: true,
                fillColor: AppColors.background,
              ),
              style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary),
              items: widget.categories.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.label,
                  style: GoogleFonts.poppins(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),

            // Price + Stock row
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('HARGA (Rp)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final f = _fmt(v);
                      if (f != v) {
                        _priceCtrl.value = TextEditingValue(
                          text: f,
                          selection: TextSelection.collapsed(offset: f.length));
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textMuted),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('STOK'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textMuted),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              )),
            ]),

            // Available toggle (edit only)
            if (_isEdit) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight, width: 1.5)),
                child: Row(children: [
                  const Icon(Icons.visibility_rounded,
                    color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Tampilkan ke siswa',
                    style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textPrimary))),
                  Switch(
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeThumbColor: AppColors.primary,
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Menu',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: GoogleFonts.poppins(
      fontSize: 10, fontWeight: FontWeight.w700,
      letterSpacing: 0.5, color: AppColors.textMuted));
}
