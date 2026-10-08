import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/bookstore.dart';
import 'package:my_app/providers/bookstore_provider.dart';
import 'package:my_app/services/bookstore_service.dart';

BookstoreProduct _product({String id = 'p1', String status = 'in_stock', int maxQty = 2}) =>
    BookstoreProduct.fromJson({
      'id': id,
      'name': '測試書',
      'price_cents': 380,
      'list_price_cents': 420,
      'stock_status': status,
      'max_qty': maxQty,
    });

void main() {
  test('parses checkout with exit pass', () {
    final c = BookstoreCheckout.fromJson({
      'id': 'c1',
      'store_id': 's1',
      'store_name': '台南大遠百店',
      'status': 'paid',
      'subtotal_cents': 362,
      'tax_cents': 18,
      'total_cents': 380,
      'exit_pass': {'token': 't.s', 'code': '123456', 'expires_at': '2030-01-01T00:00:00Z'},
      'lines': [
        {'product_id': 'p1', 'product_name': '測試書', 'qty': 1, 'unit_price_cents': 380, 'line_total_cents': 380},
      ],
    });
    expect(c.isPaid, isTrue);
    expect(c.exitPass!.code, '123456');
    expect(c.itemCount, 1);
    expect(c.statusLabel, '已付款');
  });

  test('bag enforces max qty and rejects sold out', () {
    final bag = BookstoreProvider();
    bag.enterStore(const BookstoreStore(id: 's1', code: 'TN', name: '台南'));
    final p = _product();
    expect(bag.add(p), BagAddResult.added);
    expect(bag.add(p), BagAddResult.added);
    expect(bag.add(p), BagAddResult.maxReached);
    expect(bag.add(_product(id: 'p2', status: 'out_of_stock', maxQty: 0)), BagAddResult.unavailable);
    expect(bag.itemCount, 2);
    expect(bag.estimatedSubtotal, 760);
    expect(bag.lines, {'p1': 2});
  });

  test('request id changes with bag contents and bag resets on store switch', () {
    final bag = BookstoreProvider();
    bag.enterStore(const BookstoreStore(id: 's1', code: 'A', name: 'A'));
    final before = bag.clientRequestId;
    bag.add(_product());
    expect(bag.clientRequestId, isNot(before));
    expect(RegExp(r'^[a-f0-9]{24}$').hasMatch(bag.clientRequestId), isTrue);
    bag.enterStore(const BookstoreStore(id: 's2', code: 'B', name: 'B'));
    expect(bag.isEmpty, isTrue);
    expect(bag.isInStore, isFalse);
  });

  test('parses member wallet', () {
    final w = MemberWallet.fromJson({'bonus': 80, 'acc': '20'});
    expect(w.bonus, 80);
    expect(w.acc, 20);
    expect(w.enabled, isFalse);
    expect(MemberWallet.fromJson({'bonus': 1, 'acc': 0, 'enabled': true}).enabled, isTrue);
  });

  test('store member sync defaults off', () {
    expect(BookstoreStore.fromJson({'id': 's1'}).memberSyncEnabled, isFalse);
    expect(
      BookstoreStore.fromJson({'id': 's1', 'member_sync_enabled': true}).memberSyncEnabled,
      isTrue,
    );
  });

  test('server error detail becomes friendly message', () {
    final e = BookstoreException.fromResponse(403, {
      'detail': {'code': 'presence_required', 'message': '請先掃描門口 QR Code 再結帳'},
    });
    expect(e.needsPresence, isTrue);
    expect(e.message, contains('門口'));
    expect(BookstoreException.fromResponse(502, null).message, contains('暫時無法使用'));
  });

  test('store cash discount and cash checkout parsing', () {
    final store = BookstoreStore.fromJson({
      'id': 's1',
      'code': 'TN01',
      'name': '台南大遠百',
      'cash_price_pct': 95,
      'online_payment_enabled': false,
    });
    expect(store.hasCashDiscount, isTrue);
    expect(store.cashDiscountLabel, '95 折');
    expect(store.cashPriceOf(550), 522);
    expect(store.onlinePaymentEnabled, isFalse);
    expect(BookstoreStore.fromJson({'id': 's2', 'cash_price_pct': 90}).cashDiscountLabel, '9 折');
    expect(BookstoreStore.fromJson({'id': 's3'}).hasCashDiscount, isFalse);

    final c = BookstoreCheckout.fromJson({
      'id': 'c1',
      'store_id': 's1',
      'store_name': '台南大遠百',
      'status': 'pending',
      'subtotal_cents': 550,
      'discount_cents': 28,
      'tax_cents': 25,
      'total_cents': 522,
      'payment_method': 'cash',
      'cash_payment': {'token': 'TAAZECASH1:a.b', 'code': '123456', 'expires_at': '2026-09-30T10:00:00Z'},
      'lines': [],
    });
    expect(c.isCash, isTrue);
    expect(c.discount, 28);
    expect(c.cashPayment?.code, '123456');
  });
}
