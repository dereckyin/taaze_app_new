class IdentifiedBook {
  final String? prodId;
  final String? eancode;
  final String titleMain;
  final String condition;
  final bool isSelected;
  final String? notes;
  final double? sellingPrice;

  IdentifiedBook({
    this.prodId,
    this.eancode,
    required this.titleMain,
    required this.condition,
    this.isSelected = false,
    this.notes,
    this.sellingPrice,
  });

  factory IdentifiedBook.fromJson(Map<String, dynamic> json) {
    return IdentifiedBook(
      prodId: json['prod_id'],
      eancode: json['eancode'],
      titleMain: json['title_main'] ?? '',
      condition: json['書況'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prod_id': prodId,
      'eancode': eancode,
      'title_main': titleMain,
      '書況': condition,
      'isSelected': isSelected,
      'notes': notes,
      'sellingPrice': sellingPrice,
    };
  }

  IdentifiedBook copyWith({
    String? prodId,
    String? eancode,
    String? titleMain,
    String? condition,
    bool? isSelected,
    String? notes,
    double? sellingPrice,
  }) {
    return IdentifiedBook(
      prodId: prodId ?? this.prodId,
      eancode: eancode ?? this.eancode,
      titleMain: titleMain ?? this.titleMain,
      condition: condition ?? this.condition,
      isSelected: isSelected ?? this.isSelected,
      notes: notes ?? this.notes,
      sellingPrice: sellingPrice ?? this.sellingPrice,
    );
  }

  // 獲取商品圖片URL
  String? get imageUrl {
    if (prodId == null) return null;
    return 'https://media.taaze.tw/showLargeImage.html?sc=$prodId&height=200&width=150';
  }

  // 獲取ISBN顯示文本
  String get isbnDisplay {
    return eancode ?? '無ISBN';
  }

  // 獲取商品ID顯示文本
  String get prodIdDisplay {
    return prodId ?? '未識別';
  }

  // 檢查是否為有效商品（有prodId）
  bool get isValidProduct {
    return prodId != null && prodId!.isNotEmpty;
  }
}
