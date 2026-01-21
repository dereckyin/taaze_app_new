import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/identified_book.dart';
import '../services/book_identification_service.dart';

class AiListingWizardProvider with ChangeNotifier {
  List<IdentifiedBook> _identifiedBooks = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;
  final List<IdentifiedBook> _localDrafts = [];

  List<IdentifiedBook> get identifiedBooks => _identifiedBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;
  List<IdentifiedBook> get localDrafts => List.unmodifiable(_localDrafts);

  // 獲取選中的書籍
  List<IdentifiedBook> get selectedBooks {
    return _identifiedBooks.where((book) => book.isSelected).toList();
  }

  // 檢查是否有選中的書籍
  bool get hasSelectedBooks => selectedBooks.isNotEmpty;

  // 設置選中的圖片
  void setSelectedImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

  // 識別書籍
  Future<void> identifyBooks(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await BookIdentificationService.identifyBooks(imageFile);
      _identifiedBooks = books;
      _selectedImage = imageFile;
    } catch (e) {
      _error = '書籍識別失敗: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 切換書籍選中狀態
  void toggleBookSelection(int index) {
    if (index >= 0 && index < _identifiedBooks.length) {
      _identifiedBooks[index] = _identifiedBooks[index].copyWith(
        isSelected: !_identifiedBooks[index].isSelected,
      );
      notifyListeners();
    }
  }

  // 更新書籍備註
  void updateBookNotes(int index, String notes) {
    if (index >= 0 && index < _identifiedBooks.length) {
      _identifiedBooks[index] = _identifiedBooks[index].copyWith(notes: notes);
      // 不在此呼叫 notifyListeners() 以避免輸入時列表頻繁重繪導致鍵盤卡頓
    }
  }

  // 更新書籍書況
  void updateBookCondition(int index, String condition) {
    if (index >= 0 && index < _identifiedBooks.length) {
      _identifiedBooks[index] = _identifiedBooks[index].copyWith(condition: condition);
      notifyListeners();
    }
  }

  // 更新書籍賣價
  void updateBookSellingPrice(int index, double? price) {
    if (index >= 0 && index < _identifiedBooks.length) {
      _identifiedBooks[index] = _identifiedBooks[index].copyWith(
        sellingPrice: price,
      );
      // 不在此呼叫 notifyListeners()
    }
  }

  // 匯入上架草稿
  Future<bool> importToDraft({String? authToken}) async {
    if (!hasSelectedBooks) {
      _error = '請至少選擇一本書籍';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await BookIdentificationService.importToDraft(
        selectedBooks,
        authToken: authToken,
      );
      if (success) {
        addToLocalDrafts(selectedBooks, append: true);
        // 清空選中的書籍
        for (int i = 0; i < _identifiedBooks.length; i++) {
          if (_identifiedBooks[i].isSelected) {
            _identifiedBooks[i] = _identifiedBooks[i].copyWith(
              isSelected: false,
            );
          }
        }
      }
      return success;
    } catch (e) {
      _error = '匯入失敗: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 提交二手書申請
  Future<bool> submitApplication({
    String? authToken,
  }) async {
    if (!hasSelectedBooks) {
      _error = '請至少選擇一本書籍';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await BookIdentificationService.submitSecondHandApplication(
        selectedBooks: selectedBooks,
        authToken: authToken,
      );

      if (success) {
        clearAll();
      }
      return success;
    } catch (e) {
      _error = '提交失敗: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 清空所有數據
  void clearAll() {
    _identifiedBooks.clear();
    _selectedImage = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // 將書籍加入本地草稿列表（僅前端顯示用）
  void addToLocalDrafts(List<IdentifiedBook> drafts, {bool append = true}) {
    if (!append) {
      _localDrafts
        ..clear()
        ..addAll(drafts);
    } else {
      for (final d in drafts) {
        final key = d.orgProdId ?? d.prodId ?? d.titleMain;
        final exists = _localDrafts.any((b) {
          final bKey = b.orgProdId ?? b.prodId ?? b.titleMain;
          return bKey == key;
        });
        if (!exists) {
          _localDrafts.add(d);
        }
      }
    }
    notifyListeners();
  }

  void clearLocalDrafts() {
    _localDrafts.clear();
    notifyListeners();
  }

  // 重新識別
  Future<void> reIdentify() async {
    if (_selectedImage != null) {
      await identifyBooks(_selectedImage!);
    }
  }
}
