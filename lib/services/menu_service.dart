// lib/services/menu_service.dart
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class MenuService {
  MenuService._();
  static final MenuService instance = MenuService._();

  final _api = ApiClient.instance;

  // ── Ambil semua menu (bisa filter kategori) ───────────────────
  Future<List<MenuItem>> getMenu({String? category}) async {
    final params = <String, String>{'limit': '100'};
    if (category != null && category != 'Semua') {
      params['category'] = category.toLowerCase();
    }

    final response = await _api.get(
      AppConstants.menuEndpoint,
      queryParams: params,
    );

    final items = response['data'] as List<dynamic>;
    return items
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Ambil semua menu termasuk tidak tersedia (admin) ──────────
  Future<List<MenuItem>> getMenuAdmin() async {
    final response = await _api.get(
      AppConstants.menuEndpoint,
      queryParams: {'limit': '200'},
    );
    final items = response['data'] as List<dynamic>;
    return items
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Ambil daftar kategori (label saja, untuk filter siswa) ────
  Future<List<String>> getCategories() async {
    final response = await _api.get(AppConstants.categoriesEndpoint);
    final data = response['data'] as List<dynamic>;
    final labels = data
        .map((c) => (c as Map<String, dynamic>)['label'] as String)
        .toList();
    return ['Semua', ...labels];
  }

  // ── Ambil daftar kategori lengkap (id + label, untuk admin) ──
  Future<List<MenuCategory>> getCategoriesFull() async {
    final response = await _api.get(AppConstants.categoriesEndpoint);
    final data = response['data'] as List<dynamic>;
    return data
        .map((c) => MenuCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ── Tambah menu baru (admin) ───────────────────────────────────
  Future<MenuItem> createMenuItem({
    required String name,
    required int price,
    required int stock,
    required String categoryId,
    required String emoji,
  }) async {
    final response = await _api.post(
      AppConstants.menuEndpoint,
      {
        'name': name,
        'price': price,
        'stock': stock,
        'categoryId': categoryId,
        'emoji': emoji,
      },
    );
    return MenuItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Update menu (admin) ───────────────────────────────────────
  Future<MenuItem> updateMenuItem(
    String id, {
    String? name,
    int? price,
    int? stock,
    String? emoji,
    bool? isAvailable,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (price != null) body['price'] = price;
    if (stock != null) body['stock'] = stock;
    if (emoji != null) body['emoji'] = emoji;
    if (isAvailable != null) body['isAvailable'] = isAvailable;

    final response = await _api.put('${AppConstants.menuEndpoint}/$id', body);
    return MenuItem.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Nonaktifkan menu (admin) ──────────────────────────────────
  Future<void> deleteMenuItem(String id) async {
    await _api.delete('${AppConstants.menuEndpoint}/$id');
  }
}
