class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? 'general').toString();
    NotificationType type = NotificationType.general;
    for (final t in NotificationType.values) {
      if (t.name == typeRaw) {
        type = t;
        break;
      }
    }

    final createdRaw = json['created_at'] ?? json['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdRaw is num) {
      createdAt = DateTime.fromMillisecondsSinceEpoch((createdRaw * 1000).toInt());
    } else if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      type: type,
      createdAt: createdAt,
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

enum NotificationType {
  general,
  promotion,
  order,
  bookRecommendation,
  system,
}
