// lib/models/mutation.dart

class Mutation {
  final String id;
  final String type;       // 'PURCHASE' | 'TOPUP'
  final int amount;
  final int? balanceBefore;
  final int? balanceAfter;
  final String status;     // 'SUCCESS' | 'PENDING' | 'FAILED'
  final String? description;
  final DateTime createdAt;

  const Mutation({
    required this.id,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory Mutation.fromJson(Map<String, dynamic> json) {
    return Mutation(
      id: json['id'] as String,
      type: (json['type'] as String? ?? 'PURCHASE').toUpperCase(),
      amount: (json['amount'] as int?) ?? (json['totalAmount'] as int?) ?? 0,
      balanceBefore: json['balanceBefore'] as int?,
      balanceAfter: json['balanceAfter'] as int?,
      status: (json['status'] as String? ?? 'SUCCESS').toUpperCase(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isCredit => type == 'TOPUP' || type == 'TRANSFER_IN';
  bool get isDebit  => type == 'PURCHASE' || type == 'TRANSFER_OUT';
  bool get isSuccess => status == 'SUCCESS';
  bool get isPending => status == 'PENDING';

  String get typeLabel {
    switch (type) {
      case 'TOPUP': return 'Top-up Saldo';
      case 'TRANSFER_IN': return 'Transfer Masuk';
      case 'TRANSFER_OUT': return 'Transfer Keluar';
      default: return 'Pembelian Kantin';
    }
  }

  String get formattedAmount {
    final formatted = amount.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return isCredit ? '+Rp $formatted' : '-Rp $formatted';
  }

  String get formattedBalanceAfter {
    if (balanceAfter == null) return '';
    return 'Rp ${balanceAfter!.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }
}
