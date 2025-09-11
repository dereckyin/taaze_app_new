class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String? phone;
  final DateTime? birthDate;
  final String? address;
  final List<String> favoriteCategories;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.phone,
    this.birthDate,
    this.address,
    this.favoriteCategories = const [],
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      phone: json['phone'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      address: json['address'],
      favoriteCategories: List<String>.from(json['favoriteCategories'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'phone': phone,
      'birthDate': birthDate?.toIso8601String(),
      'address': address,
      'favoriteCategories': favoriteCategories,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    String? phone,
    DateTime? birthDate,
    String? address,
    List<String>? favoriteCategories,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
