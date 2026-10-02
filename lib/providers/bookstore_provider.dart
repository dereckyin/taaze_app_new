import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/bookstore.dart';

class BagItem {
  final BookstoreProduct product;
  int qty;

  BagItem(this.product, this.qty);

  int get lineTotal => product.price * qty;
}

enum BagAddResult { added, maxReached, unavailable }

/// 購物車：與線上購物車（CartProvider）完全分開，只存在記憶體，
/// 金額僅供顯示，實際以伺服器結帳回傳為準。
class BookstoreProvider extends ChangeNotifier {
  BookstoreStore? _store;
  PresenceSession? _presence;
  final LinkedHashMap<String, BagItem> _bag = LinkedHashMap();
  String _clientRequestId = _newRequestId();

  BookstoreStore? get store => _store;

  PresenceSession? get presence =>
      (_presence != null && _presence!.isValid && _presence!.store.id == _store?.id)
          ? _presence
          : null;

  bool get isInStore => presence != null;
  List<BagItem> get items => _bag.values.toList(growable: false);
  int get itemCount => _bag.values.fold(0, (s, i) => s + i.qty);
  int get estimatedSubtotal => _bag.values.fold(0, (s, i) => s + i.lineTotal);
  bool get isEmpty => _bag.isEmpty;
  String get clientRequestId => _clientRequestId;
  Map<String, int> get lines => {for (final e in _bag.entries) e.key: e.value.qty};

  int qtyOf(String productId) => _bag[productId]?.qty ?? 0;

  void enterStore(BookstoreStore store) {
    if (_store?.id != store.id) {
      _bag.clear();
      _touch();
    }
    _store = store;
    notifyListeners();
  }

  void setPresence(PresenceSession session) {
    enterStore(session.store);
    _presence = session;
    notifyListeners();
  }

  BagAddResult add(BookstoreProduct product) {
    if (!product.available) return BagAddResult.unavailable;
    final existing = _bag[product.id];
    if (existing != null) {
      if (existing.qty >= product.maxQty) return BagAddResult.maxReached;
      existing.qty += 1;
    } else {
      _bag[product.id] = BagItem(product, 1);
    }
    _touch();
    notifyListeners();
    return BagAddResult.added;
  }

  void setQty(String productId, int qty) {
    final item = _bag[productId];
    if (item == null) return;
    if (qty <= 0) {
      _bag.remove(productId);
    } else {
      item.qty = qty.clamp(1, max(1, item.product.maxQty));
    }
    _touch();
    notifyListeners();
  }

  void remove(String productId) => setQty(productId, 0);

  void clearBag() {
    _bag.clear();
    _touch();
    notifyListeners();
  }

  void leaveStore() {
    _bag.clear();
    _presence = null;
    _store = null;
    _touch();
    notifyListeners();
  }

  /// 袋子內容一變就換新的請求編號；同一袋重送結帳時伺服器會回同一筆，不會重複鎖庫存。
  void _touch() => _clientRequestId = _newRequestId();

  static String _newRequestId() {
    final rnd = Random.secure();
    return List.generate(24, (_) => rnd.nextInt(16).toRadixString(16)).join();
  }
}
