class Banner {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final String? actionUrl;
  final String? actionText;
  final BannerType type;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    this.actionUrl,
    this.actionText,
    required this.type,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    this.expiresAt,
  });

  /// 首頁橫幅用較寬圖，避免 300px 圖在全幅區塊看起來被壓縮。
  static String displayImageUrl(String raw) {
    if (raw.isEmpty || !raw.contains('showBanaerImage')) return raw;
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'width': '800',
      'height': '400',
      'fill': 'f',
    }).toString();
  }

  factory Banner.fromJson(Map<String, dynamic> json) {
    final rawImage = json['imageUrl']?.toString() ?? '';
    return Banner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: displayImageUrl(rawImage),
      actionUrl: json['actionUrl']?.toString(),
      actionText: json['actionText']?.toString(),
      type: BannerType.fromString(json['type']?.toString() ?? 'promotion'),
      isActive: json['isActive'] ?? true,
      displayOrder: json['displayOrder'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionText': actionText,
      'type': type.value,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  Banner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? imageUrl,
    String? actionUrl,
    String? actionText,
    BannerType? type,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isValid {
    return isActive && !isExpired;
  }
}

enum BannerType {
  promotion('promotion', '促銷活動'),
  announcement('announcement', '公告'),
  featured('featured', '精選推薦'),
  newRelease('new_release', '新品上市'),
  event('event', '活動');

  const BannerType(this.value, this.displayName);

  final String value;
  final String displayName;

  static BannerType fromString(String value) {
    switch (value) {
      case 'promotion':
        return BannerType.promotion;
      case 'announcement':
        return BannerType.announcement;
      case 'featured':
        return BannerType.featured;
      case 'new_release':
        return BannerType.newRelease;
      case 'event':
        return BannerType.event;
      default:
        return BannerType.promotion;
    }
  }
}
