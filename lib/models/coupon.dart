class Coupon {
  final String id;
  final String title;
  final String description;
  final double discountAmount;
  final String discountType; // 'fixed' 固定金額, 'percentage' 百分比
  final double? minOrderAmount; // 最低消費金額
  final DateTime expiryDate;
  final String status; // 'active', 'expired', 'used'
  final String? imageUrl;
  final String? backgroundColor;
  final String? textColor;

  Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    this.minOrderAmount,
    required this.expiryDate,
    required this.status,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      discountType: json['discountType'] ?? 'fixed',
      minOrderAmount: json['minOrderAmount'] != null
          ? (json['minOrderAmount'] as num).toDouble()
          : null,
      expiryDate: DateTime.parse(
        json['expiryDate'] ??
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      ),
      status: json['status'] ?? 'active',
      imageUrl: json['imageUrl'],
      backgroundColor: json['backgroundColor'],
      textColor: json['textColor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discountAmount': discountAmount,
      'discountType': discountType,
      'minOrderAmount': minOrderAmount,
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
      'imageUrl': imageUrl,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
    };
  }

  Coupon copyWith({
    String? id,
    String? title,
    String? description,
    double? discountAmount,
    String? discountType,
    double? minOrderAmount,
    DateTime? expiryDate,
    String? status,
    String? imageUrl,
    String? backgroundColor,
    String? textColor,
  }) {
    return Coupon(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  // 獲取折扣顯示文本
  String get discountDisplayText {
    if (discountType == 'percentage') {
      return '${discountAmount.toInt()}%';
    } else {
      return 'NT\$ ${discountAmount.toInt()}';
    }
  }

  // 獲取最低消費顯示文本
  String? get minOrderDisplayText {
    if (minOrderAmount != null && minOrderAmount! > 0) {
      return '滿 NT\$ ${minOrderAmount!.toInt()} 可用';
    }
    return null;
  }

  // 檢查是否可用
  bool get isAvailable {
    return status == 'active' && expiryDate.isAfter(DateTime.now());
  }

  // 獲取剩餘天數
  int get remainingDays {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inDays;
  }
}
