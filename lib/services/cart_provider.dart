// lib/services/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/app_exceptions.dart';

enum PaymentStatus { idle, processing, success, failed }

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  PaymentStatus _paymentStatus = PaymentStatus.idle;
  Transaction?  _lastTransaction;
  String?       _paymentError;

  final _txService = TransactionService.instance;

  Map<String, CartItem> get items   => Map.unmodifiable(_items);
  PaymentStatus get paymentStatus   => _paymentStatus;
  Transaction?  get lastTransaction => _lastTransaction;
  String?       get paymentError    => _paymentError;
  bool get isProcessing             => _paymentStatus == PaymentStatus.processing;
  bool get hasItems                 => _items.isNotEmpty;

  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  int get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);
  String get formattedTotal {
    final s = totalPrice.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return 'Rp $s';
  }

  int quantityOf(String id) => _items[id]?.quantity ?? 0;

  void addItem(MenuItem item) {
    _items.containsKey(item.id)
        ? _items[item.id]!.quantity++
        : _items[item.id] = CartItem(menuItem: item);
    notifyListeners();
  }

  void removeItem(String id) {
    if (!_items.containsKey(id)) return;
    _items[id]!.quantity > 1 ? _items[id]!.quantity-- : _items.remove(id);
    notifyListeners();
  }

  void clearCart() { _items.clear(); notifyListeners(); }
  void resetPayment() {
    _paymentStatus = PaymentStatus.idle;
    _paymentError = null;
    notifyListeners();
  }

  Future<Transaction?> processPayment({String? uid}) async {
    if (_items.isEmpty) return null;
    _paymentStatus = PaymentStatus.processing;
    _paymentError = null;
    notifyListeners();

    try {
      final tx = await _txService.createTransaction(
        cartItems: _items,
        uid: uid,
        paymentMethod: uid != null ? 'NFC_CARD' : 'PIN',
      );
      _lastTransaction = tx;
      _paymentStatus   = PaymentStatus.success;
      clearCart();
      return tx;
    } on ApiException catch (e) {
      _paymentStatus = PaymentStatus.failed;
      _paymentError  = e.message;
      notifyListeners();
      return null;
    } on NetworkException catch (e) {
      _paymentStatus = PaymentStatus.failed;
      _paymentError  = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _paymentStatus = PaymentStatus.failed;
      _paymentError  = 'Pembayaran gagal, coba lagi';
      notifyListeners();
      return null;
    }
  }
}
