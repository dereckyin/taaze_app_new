class Book {
  final String id;
  final String? orgProdId;
  final String title;
  final String author;
  final String description;
  final double price;
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

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      orgProdId: json['orgProdId']?.toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgProdId': orgProdId,
      'title': title,
      'author': author,
      'description': description,
      'price': price,
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
