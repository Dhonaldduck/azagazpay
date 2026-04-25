// lib/providers/menu_provider.dart
import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';
import '../utils/app_exceptions.dart';

enum MenuStatus { initial, loading, loaded, error }

class MenuProvider extends ChangeNotifier {
  MenuStatus        _status     = MenuStatus.initial;
  List<MenuItem>    _allItems   = [];
  List<String>      _categories = ['Semua'];
  String            _selected   = 'Semua';
  String?           _error;

  final _service = MenuService.instance;

  MenuStatus     get status     => _status;
  List<String>   get categories => _categories;
  String         get selected   => _selected;
  String?        get error      => _error;
  bool           get isLoading  => _status == MenuStatus.loading;

  List<MenuItem> get items {
    if (_selected == 'Semua') return _allItems;
    return _allItems
        .where((i) => i.category.toLowerCase() == _selected.toLowerCase())
        .toList();
  }

  // ── Fetch menu + kategori dari API ────────────────────────────
  Future<void> fetchMenu() async {
    _status = MenuStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getMenu(),
        _service.getCategories(),
      ]);

      _allItems   = results[0] as List<MenuItem>;
      _categories = results[1] as List<String>;
      _status     = MenuStatus.loaded;
    } on ApiException catch (e) {
      _error  = e.message;
      _status = MenuStatus.error;
    } on NetworkException catch (e) {
      _error  = e.message;
      _status = MenuStatus.error;
    } catch (_) {
      _error  = 'Gagal memuat menu';
      _status = MenuStatus.error;
    }
    notifyListeners();
  }

  void setCategory(String cat) {
    _selected = cat;
    notifyListeners();
  }
}
