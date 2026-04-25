// lib/services/transaction_service.dart
import '../models/menu_item.dart';
import '../models/transaction.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class TransactionService {
  TransactionService._();
  static final TransactionService instance = TransactionService._();

  final _api = ApiClient.instance;

  // ── Buat transaksi baru ───────────────────────────────────────
  // [uid] = UID kartu NFC yang ditap (boleh null jika bayar via PIN)
  Future<Transaction> createTransaction({
    required Map<String, CartItem> cartItems,
    String? uid,
    String paymentMethod = 'NFC_CARD',
  }) async {
    final items = cartItems.values
        .map((ci) => {
              'menuItemId': ci.menuItem.id,
              'quantity': ci.quantity,
            })
        .toList();

    final body = <String, dynamic>{
      'items': items,
      'paymentMethod': paymentMethod,
    };
    if (uid != null) body['uid'] = uid;

    final response = await _api.post(AppConstants.transactionsEndpoint, body);

    return Transaction.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  // ── Ambil riwayat transaksi ───────────────────────────────────
  Future<List<Transaction>> getHistory({int page = 1, int limit = 10}) async {
    final response = await _api.get(
      AppConstants.transactionsEndpoint,
      queryParams: {'page': '$page', 'limit': '$limit'},
    );

    final data = response['data'] as List<dynamic>;
    return data
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  // ── Detail satu transaksi ─────────────────────────────────────
  Future<Transaction> getById(String id) async {
    final response = await _api.get('${AppConstants.transactionsEndpoint}/$id');
    return Transaction.fromJson(response['data'] as Map<String, dynamic>);
  }
}
