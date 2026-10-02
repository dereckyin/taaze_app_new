/// 實體書店專區資料模型（金額單位為新台幣元，欄位名沿用後端 *_cents）
library;

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

String? _str(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

class BookstoreStore {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final bool isOpen;
  final bool cashEnabled;

  /// 現金價佔原價百分比：95 = 95 折，100 = 不打折
  final int cashPricePct;
  final bool onlinePaymentEnabled;

  const BookstoreStore({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    this.isOpen = true,
    this.cashEnabled = true,
    this.cashPricePct = 100,
    this.onlinePaymentEnabled = false,
  });

  bool get hasCashDiscount => cashEnabled && cashPricePct < 100;

  /// 「95 折」「9 折」
  String get cashDiscountLabel {
    final pct = cashPricePct;
    return pct % 10 == 0 ? '${pct ~/ 10} 折' : '$pct 折';
  }

  /// 僅供預覽；實際金額以伺服器計算為準（零頭無條件捨去）
  int cashPriceOf(int amount) => amount * cashPricePct ~/ 100;

  factory BookstoreStore.fromJson(Map<String, dynamic> j) => BookstoreStore(
        id: j['id'].toString(),
        code: j['code']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        address: _str(j['address']),
        phone: _str(j['phone']),
        isOpen: j['is_open'] != false,
        cashEnabled: j['cash_enabled'] != false,
        cashPricePct: j['cash_price_pct'] == null ? 100 : _int(j['cash_price_pct']).clamp(1, 100),
        onlinePaymentEnabled: j['online_payment_enabled'] == true,
      );
}

class BookstoreCategory {
  final String id;
  final String name;

  const BookstoreCategory({required this.id, required this.name});

  factory BookstoreCategory.fromJson(Map<String, dynamic> j) =>
      BookstoreCategory(id: j['id'].toString(), name: j['name']?.toString() ?? '');
}

enum StockStatus { inStock, lastOne, outOfStock }

class BookstoreProduct {
  final String id;
  final String name;
  final String? author;
  final String? publisher;
  final String? isbn;
  final String? imageUrl;
  final String? description;
  final String? categoryName;
  final int price;
  final int? listPrice;
  final StockStatus stockStatus;
  final int maxQty;

  const BookstoreProduct({
    required this.id,
    required this.name,
    this.author,
    this.publisher,
    this.isbn,
    this.imageUrl,
    this.description,
    this.categoryName,
    required this.price,
    this.listPrice,
    required this.stockStatus,
    required this.maxQty,
  });

  bool get available => stockStatus != StockStatus.outOfStock && maxQty > 0;

  bool get discounted => listPrice != null && listPrice! > price;

  factory BookstoreProduct.fromJson(Map<String, dynamic> j) {
    final status = switch (j['stock_status']) {
      'last_one' => StockStatus.lastOne,
      'out_of_stock' => StockStatus.outOfStock,
      _ => StockStatus.inStock,
    };
    return BookstoreProduct(
      id: j['id'].toString(),
      name: j['name']?.toString() ?? '',
      author: _str(j['author']),
      publisher: _str(j['publisher']),
      isbn: _str(j['isbn']),
      imageUrl: _str(j['image_url']),
      description: _str(j['description']),
      categoryName: _str(j['category_name']),
      price: _int(j['price_cents']),
      listPrice: j['list_price_cents'] == null ? null : _int(j['list_price_cents']),
      stockStatus: status,
      maxQty: _int(j['max_qty']),
    );
  }
}

class BookstoreProductPage {
  final List<BookstoreProduct> items;
  final int total;
  final int page;
  final int pageSize;

  const BookstoreProductPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  factory BookstoreProductPage.fromJson(Map<String, dynamic> j) =>
      BookstoreProductPage(
        items: (j['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BookstoreProduct.fromJson)
            .toList(),
        total: _int(j['total']),
        page: _int(j['page']),
        pageSize: _int(j['page_size']),
      );
}

class PresenceSession {
  final BookstoreStore store;
  final String token;
  final DateTime expiresAt;

  const PresenceSession({
    required this.store,
    required this.token,
    required this.expiresAt,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);

  factory PresenceSession.fromJson(Map<String, dynamic> j) => PresenceSession(
        store: BookstoreStore.fromJson(j['store'] as Map<String, dynamic>),
        token: j['presence_token'].toString(),
        expiresAt: _date(j['presence_expires_at']) ?? DateTime.now(),
      );
}

class CheckoutLine {
  final String productId;
  final String productName;
  final String? isbn;
  final int qty;
  final int unitPrice;
  final int lineTotal;

  const CheckoutLine({
    required this.productId,
    required this.productName,
    this.isbn,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory CheckoutLine.fromJson(Map<String, dynamic> j) => CheckoutLine(
        productId: j['product_id'].toString(),
        productName: j['product_name']?.toString() ?? '',
        isbn: _str(j['isbn']),
        qty: _int(j['qty']),
        unitPrice: _int(j['unit_price_cents']),
        lineTotal: _int(j['line_total_cents']),
      );
}

class ExitPass {
  final String token;
  final String code;
  final DateTime expiresAt;

  const ExitPass({required this.token, required this.code, required this.expiresAt});

  factory ExitPass.fromJson(Map<String, dynamic> j) => ExitPass(
        token: j['token'].toString(),
        code: j['code'].toString(),
        expiresAt: _date(j['expires_at']) ?? DateTime.now(),
      );
}

/// 櫃台現金付款碼：店員掃 QR（token）或輸入 6 位數 code
class CashPayment {
  final String token;
  final String code;
  final DateTime expiresAt;

  const CashPayment({required this.token, required this.code, required this.expiresAt});

  factory CashPayment.fromJson(Map<String, dynamic> j) => CashPayment(
        token: j['token'].toString(),
        code: j['code'].toString(),
        expiresAt: _date(j['expires_at']) ?? DateTime.now(),
      );
}

class BookstoreCheckout {
  final String id;
  final String storeId;
  final String storeName;
  final String status;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final String? paymentMethod; // cash | online
  final CashPayment? cashPayment;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final String? invoiceStatus;
  final String? invoiceNumber;
  final String? orderNo;
  final DateTime? exitVerifiedAt;
  final ExitPass? exitPass;
  final List<CheckoutLine> lines;
  final DateTime? createdAt;

  const BookstoreCheckout({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.status,
    required this.subtotal,
    this.discount = 0,
    required this.tax,
    required this.total,
    this.paymentMethod,
    this.cashPayment,
    this.expiresAt,
    this.paidAt,
    this.invoiceStatus,
    this.invoiceNumber,
    this.orderNo,
    this.exitVerifiedAt,
    this.exitPass,
    required this.lines,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isRefunded => status == 'refunded';
  bool get isClosed => status == 'expired' || status == 'cancelled';
  bool get isCash => paymentMethod == 'cash';
  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);

  String get statusLabel => switch (status) {
        'pending' => '待付款',
        'paid' => exitVerifiedAt != null ? '已出門核銷' : '已付款',
        'refunded' => '已退貨',
        'expired' => '已逾時',
        'cancelled' => '已取消',
        _ => status,
      };

  factory BookstoreCheckout.fromJson(Map<String, dynamic> j) => BookstoreCheckout(
        id: j['id'].toString(),
        storeId: j['store_id']?.toString() ?? '',
        storeName: j['store_name']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        subtotal: _int(j['subtotal_cents']),
        discount: _int(j['discount_cents']),
        tax: _int(j['tax_cents']),
        total: _int(j['total_cents']),
        paymentMethod: _str(j['payment_method']),
        cashPayment: j['cash_payment'] is Map<String, dynamic>
            ? CashPayment.fromJson(j['cash_payment'] as Map<String, dynamic>)
            : null,
        expiresAt: _date(j['expires_at']),
        paidAt: _date(j['paid_at']),
        invoiceStatus: _str(j['invoice_status']),
        invoiceNumber: _str(j['invoice_number']),
        orderNo: _str(j['order_no']),
        exitVerifiedAt: _date(j['exit_verified_at']),
        exitPass: j['exit_pass'] is Map<String, dynamic>
            ? ExitPass.fromJson(j['exit_pass'] as Map<String, dynamic>)
            : null,
        lines: (j['lines'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CheckoutLine.fromJson)
            .toList(),
        createdAt: _date(j['created_at']),
      );
}

/// 發票選項；全部為空代表會員載具（由後端預設處理）
class InvoiceChoice {
  final String? carrierType; // mobile | citizenDigital
  final String? carrierCode;
  final String? taxId;
  final String? donationCode;

  const InvoiceChoice({this.carrierType, this.carrierCode, this.taxId, this.donationCode});

  bool get isEmpty =>
      carrierType == null && taxId == null && donationCode == null;

  Map<String, dynamic>? toJson() {
    if (isEmpty) return null;
    return {
      if (carrierType != null) 'carrier_type': carrierType,
      if (carrierCode != null) 'carrier_code': carrierCode,
      if (taxId != null) 'tax_id': taxId,
      if (donationCode != null) 'donation_code': donationCode,
    };
  }
}
