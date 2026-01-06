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
    String rawCondition = json['書況'] ?? '';
    // 將後端代碼 (A, B, C...) 或舊版字串映射為 UI 用的純中文
    String mappedCondition;
    if (rawCondition == 'A' || rawCondition == '全新') mappedCondition = '全新';
    else if (rawCondition == 'B' || rawCondition == '近全新') mappedCondition = '近全新';
    else if (rawCondition == 'C' || rawCondition == '良好') mappedCondition = '良好';
    else if (rawCondition == 'D' || rawCondition == '普通') mappedCondition = '普通';
    else if (rawCondition == 'E' || rawCondition == '差' || rawCondition == '差強人意') mappedCondition = '差強人意';
    else mappedCondition = '良好'; // 預設值

    return IdentifiedBook(
      prodId: json['prod_id'],
      eancode: json['eancode'],
      titleMain: json['title_main'] ?? '',
      condition: mappedCondition,
    );
  }

  Map<String, dynamic> toJson() {
    // 將純中文映射回後端要求的代碼
    String conditionCode;
    switch (condition) {
      case '全新': conditionCode = 'A'; break;
      case '近全新': conditionCode = 'B'; break;
      case '良好': conditionCode = 'C'; break;
      case '普通': conditionCode = 'D'; break;
      case '差強人意': conditionCode = 'E'; break;
      default: conditionCode = 'C';
    }

    return {
      'prod_id': prodId,
      'eancode': eancode,
      'title_main': titleMain,
      '書況': conditionCode,
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
