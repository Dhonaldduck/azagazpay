// lib/models/menu_item.dart

class MenuItem {
  final String id;
  final String name;
  final int price;
  final int stock;
  final String category;      // category name (slug)
  final String categoryLabel; // display label
  final String? categoryId;   // ID for admin CRUD
  final String emoji;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    this.categoryLabel = '',
    this.categoryId,
    required this.emoji,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      stock: json['stock'] as int,
      category: cat?['name'] as String? ?? 'lainnya',
      categoryLabel: cat?['label'] as String? ?? '',
      categoryId: cat?['id'] as String?,
      emoji: json['emoji'] as String? ?? '🍽️',
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  int get subtotal => menuItem.price * quantity;

  String get formattedSubtotal {
    final formatted = subtotal.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }
}
