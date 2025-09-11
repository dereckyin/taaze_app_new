import 'book.dart';

class CartItem {
  final String id;
  final Book book;
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.book,
    required this.quantity,
    required this.addedAt,
  });

  double get totalPrice => book.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      book: Book.fromJson(json['book'] ?? {}),
      quantity: json['quantity'] ?? 1,
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? id,
    Book? book,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      book: book ?? this.book,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
