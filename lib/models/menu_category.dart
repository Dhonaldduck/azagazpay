// lib/models/menu_category.dart

class MenuCategory {
  final String id;
  final String name;
  final String label;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.label,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    label: json['label'] as String,
  );
}
