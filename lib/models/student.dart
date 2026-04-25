// lib/models/student.dart

class Student {
  final String id;
  final String nisn;
  final String name;
  final String studentClass;
  final int balance;
  final String? activeCard;
  final bool isActive;

  const Student({
    required this.id,
    required this.nisn,
    required this.name,
    required this.studentClass,
    required this.balance,
    this.activeCard,
    this.isActive = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      nisn: json['nisn'] as String,
      name: json['name'] as String,
      studentClass: json['class'] as String,
      balance: json['balance'] as int,
      activeCard: json['activeCard'] as String?,
      isActive: json['isActive'] as bool? ?? (json['is_active'] == 1),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nisn': nisn,
    'name': name,
    'class': studentClass,
    'balance': balance,
    'activeCard': activeCard,
    'isActive': isActive,
  };

  Student copyWith({
    int? balance,
    String? activeCard,
    bool? isActive,
  }) {
    return Student(
      id: id,
      nisn: nisn,
      name: name,
      studentClass: studentClass,
      balance: balance ?? this.balance,
      activeCard: activeCard ?? this.activeCard,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedBalance =>
      'Rp ${balance.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      )}';

  String get displayCard => activeCard ?? '**** **** **** ????';
}
