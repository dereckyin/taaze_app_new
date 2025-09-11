import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/book.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addToCart(Book book, {int quantity = 1}) {
    final existingItemIndex = _items.indexWhere((item) => item.book.id == book.id);
    
    if (existingItemIndex >= 0) {
      // 如果商品已存在，增加數量
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + quantity,
      );
    } else {
      // 如果商品不存在，添加新項目
      _items.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        book: book,
        quantity: quantity,
        addedAt: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String bookId) {
    _items.removeWhere((item) => item.book.id == bookId);
    notifyListeners();
  }

  void updateQuantity(String bookId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(bookId);
      return;
    }

    final itemIndex = _items.indexWhere((item) => item.book.id == bookId);
    if (itemIndex >= 0) {
      _items[itemIndex] = _items[itemIndex].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String bookId) {
    return _items.any((item) => item.book.id == bookId);
  }

  int getQuantity(String bookId) {
    final item = _items.firstWhere(
      (item) => item.book.id == bookId,
      orElse: () => CartItem(
        id: '',
        book: Book(
          id: '',
          title: '',
          author: '',
          description: '',
          price: 0,
          imageUrl: '',
          category: '',
          rating: 0,
          reviewCount: 0,
          isAvailable: false,
          publishDate: DateTime.now(),
          isbn: '',
          pages: 0,
          publisher: '',
        ),
        quantity: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }
}
