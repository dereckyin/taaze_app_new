class Book {
  final String id;
  final String? orgProdId;
  final String title;
  final String author;
  final String description;
  final double price;
  /// 定價（原價）
  final double? listPrice;
  /// 優惠價（特價）
  final double? salePrice;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final DateTime publishDate;
  final String isbn;
  final int pages;
  final String publisher;

  Book({
    required this.id,
    this.orgProdId,
    required this.title,
    required this.author,
    required this.description,
    required this.price,
    this.listPrice,
    this.salePrice,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.publishDate,
    required this.isbn,
    required this.pages,
    required this.publisher,
  });

  /// 實際顯示用的優惠價：優先 `salePrice`，否則回退 `price`
  double get effectiveSalePrice => salePrice ?? price;

  /// 實際顯示用的定價：只有在有提供且 > 0 時才回傳
  double? get effectiveListPrice {
    final lp = listPrice;
    if (lp == null || lp <= 0) return null;
    return lp;
  }

  /// 折扣（幾折）label，例如：`7.9折`
  /// 僅在 `listPrice > salePrice` 時顯示，否則回傳 null。
  String? get discountOffLabel {
    final lp = effectiveListPrice;
    final sp = effectiveSalePrice;
    if (lp == null || lp <= 0) return null;
    if (sp <= 0) return null;
    if (sp >= lp) return null;

    final off = (sp / lp) * 10.0; // 幾折
    if (off.isNaN || off.isInfinite) return null;

    final clamped = off.clamp(0.0, 10.0);
    final rounded = (clamped * 10).round() / 10.0; // 取到 0.1 折
    final text = (rounded % 1 == 0)
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    return '${text}折';
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      orgProdId: json['orgProdId']?.toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      // 兼容不同來源欄位命名
      listPrice: _tryParseDouble(json['listPrice'] ?? json['list_price']),
      salePrice: _tryParseDouble(json['salePrice'] ?? json['sale_price']),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      publishDate: DateTime.parse(
        json['publishDate'] ?? DateTime.now().toIso8601String(),
      ),
      isbn: json['isbn'] ?? '',
      pages: json['pages'] ?? 0,
      publisher: json['publisher'] ?? '',
    );
  }

  static double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.tryParse(cleaned);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgProdId': orgProdId,
      'title': title,
      'author': author,
      'description': description,
      'price': price,
      'listPrice': listPrice,
      'salePrice': salePrice,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'publishDate': publishDate.toIso8601String(),
      'isbn': isbn,
      'pages': pages,
      'publisher': publisher,
    };
  }

  Book copyWith({
    String? id,
    String? orgProdId,
    String? title,
    String? author,
    String? description,
    double? price,
    double? listPrice,
    double? salePrice,
    String? imageUrl,
    String? category,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    DateTime? publishDate,
    String? isbn,
    int? pages,
    String? publisher,
  }) {
    return Book(
      id: id ?? this.id,
      orgProdId: orgProdId ?? this.orgProdId,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      price: price ?? this.price,
      listPrice: listPrice ?? this.listPrice,
      salePrice: salePrice ?? this.salePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      publishDate: publishDate ?? this.publishDate,
      isbn: isbn ?? this.isbn,
      pages: pages ?? this.pages,
      publisher: publisher ?? this.publisher,
    );
  }
}
