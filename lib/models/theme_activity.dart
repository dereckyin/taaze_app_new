class ThemeActivity {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? actionUrl;
  final int displayOrder;

  ThemeActivity({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.actionUrl,
    this.displayOrder = 0,
  });

  factory ThemeActivity.fromJson(Map<String, dynamic> json) {
    return ThemeActivity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      actionUrl: json['actionUrl']?.toString(),
      displayOrder: json['displayOrder'] is int
          ? json['displayOrder'] as int
          : int.tryParse(json['displayOrder']?.toString() ?? '0') ?? 0,
    );
  }
}
