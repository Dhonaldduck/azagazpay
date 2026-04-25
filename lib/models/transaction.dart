// lib/models/transaction.dart

class TransactionItem {
  final String name;
  final int price;
  final int quantity;
  final int subtotal;

  const TransactionItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      name: json['name'] as String,
      price: json['price'] as int,
      quantity: json['quantity'] as int,
      subtotal: json['subtotal'] as int? ?? (json['price'] as int) * (json['quantity'] as int),
    );
  }

  String get formattedPrice =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  String get formattedSubtotal =>
      'Rp ${subtotal.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

class Transaction {
  final String id;
  final int totalAmount;
  final int balanceBefore;
  final int balanceAfter;
  final String status;
  final String paymentMethod;
  final List<TransactionItem> items;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Transaction({
    required this.id,
    required this.totalAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.paymentMethod,
    required this.items,
    required this.createdAt,
    this.completedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      totalAmount: json['totalAmount'] as int,
      balanceBefore: json['balanceBefore'] as int,
      balanceAfter: json['balanceAfter'] as int,
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => TransactionItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  String get formattedTotal =>
      'Rp ${totalAmount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  String get formattedBalanceAfter =>
      'Rp ${balanceAfter.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  bool get isSuccess => status == 'SUCCESS';
}
