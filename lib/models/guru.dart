// lib/models/guru.dart

class Guru {
  final String id;
  final String username;
  final String name;
  final String role;

  const Guru({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  factory Guru.fromJson(Map<String, dynamic> json) => Guru(
    id: json['id'] as String,
    username: json['username'] as String,
    name: json['name'] as String,
    role: json['role'] as String? ?? 'CASHIER',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'role': role,
  };

  String get displayRole {
    switch (role.toUpperCase()) {
      case 'ADMIN': return 'Administrator';
      case 'CASHIER': return 'Kasir';
      default: return role;
    }
  }
}
