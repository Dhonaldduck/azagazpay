// lib/models/topup_request.dart

class TopupRequest {
  final String id;
  final int amount;
  final String? notes;
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime requestedAt;
  final String studentId;
  final String studentName;
  final String nisn;
  final String studentClass;
  final int studentBalance;

  const TopupRequest({
    required this.id,
    required this.amount,
    this.notes,
    required this.status,
    required this.requestedAt,
    required this.studentId,
    required this.studentName,
    required this.nisn,
    required this.studentClass,
    required this.studentBalance,
  });

  factory TopupRequest.fromJson(Map<String, dynamic> json) {
    return TopupRequest(
      id: json['id'] as String,
      amount: json['amount'] as int,
      notes: json['notes'] as String?,
      status: (json['status'] as String? ?? 'PENDING').toUpperCase(),
      requestedAt: DateTime.parse(
        (json['requestedAt'] ?? json['requested_at']) as String),
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      nisn: json['nisn'] as String,
      studentClass: json['studentClass'] as String,
      studentBalance: json['studentBalance'] as int,
    );
  }

  String get formattedAmount => 'Rp ${amount.toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  String get formattedBalance => 'Rp ${studentBalance.toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
}
