class OrderItemSummary {
  final String? titleMain;
  final String? prodId;
  final String? orgProdId;
  final String? author;
  final String? coverImage;
  final double? unitPrice;
  final int? quantity;
  final Map<String, dynamic> raw;

  OrderItemSummary({
    required this.titleMain,
    required this.prodId,
    required this.orgProdId,
    required this.author,
    required this.coverImage,
    required this.unitPrice,
    required this.quantity,
    required this.raw,
  });

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      titleMain: json['title_main'] as String?,
      prodId: json['prod_id'] as String?,
      orgProdId: json['org_prod_id'] as String?,
      author: json['author'] as String?,
      coverImage: json['cover_image'] as String?,
      unitPrice: _tryParseDouble(json['unit_price']),
      quantity: _tryParseInt(json['qty'] ?? json['quantity']),
      raw: json,
    );
  }

  static double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

