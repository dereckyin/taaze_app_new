import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/ai_listing_wizard_provider.dart';
import '../models/identified_book.dart';

class IdentifiedBooksListScreen extends StatelessWidget {
  const IdentifiedBooksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 關鍵優化：僅監聽清單長度變化，確保打字更新資料時，ListView 不會整張重構
    final bookCount = context.select<AiListingWizardProvider, int>(
      (p) => p.identifiedBooks.length,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookCount,
      itemBuilder: (context, index) {
        // 使用 ValueKey 保持狀態，但 index 是唯一的
        return _BookCard(
          key: ValueKey('book_card_$index'),
          index: index,
        );
      },
    );
  }
}

class _BookCard extends StatefulWidget {
  final int index;

  const _BookCard({super.key, required this.index});

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> {
  late TextEditingController _notesController;
  late TextEditingController _priceController;
  late FocusNode _notesFocusNode;
  late FocusNode _priceFocusNode;
  late AiListingWizardProvider _provider; // 快取 Provider 實例
  Timer? _notesDebounce;
  Timer? _priceDebounce;

  @override
  void initState() {
    super.initState();
    // 取得並快取實例
    _provider = context.read<AiListingWizardProvider>();
    
    if (widget.index < _provider.identifiedBooks.length) {
      final book = _provider.identifiedBooks[widget.index];
      _notesController = TextEditingController(text: book.notes);
      _priceController = TextEditingController(
        text: book.sellingPrice?.toString() ?? '',
      );
    } else {
      _notesController = TextEditingController();
      _priceController = TextEditingController();
    }

    _notesFocusNode = FocusNode();
    _priceFocusNode = FocusNode();

    // 監聽焦點變化，失去焦點時立即同步
    _notesFocusNode.addListener(() {
      if (!_notesFocusNode.hasFocus) {
        _syncNotesToProvider();
      }
    });
    _priceFocusNode.addListener(() {
      if (!_priceFocusNode.hasFocus) {
        _syncPriceToProvider();
      }
    });
  }

  void _syncNotesToProvider() {
    if (_notesDebounce?.isActive ?? false) _notesDebounce!.cancel();
    // 使用快取的 _provider 而非 context.read
    _provider.updateBookNotes(
      widget.index,
      _notesController.text,
    );
  }

  void _syncPriceToProvider() {
    if (_priceDebounce?.isActive ?? false) _priceDebounce!.cancel();
    final price = double.tryParse(_priceController.text);
    _provider.updateBookSellingPrice(
      widget.index,
      price,
    );
  }

  @override
  void dispose() {
    // 銷毀前強制同步最後一次，此時使用快取的 _provider 是安全的
    _syncNotesToProvider();
    _syncPriceToProvider();

    _notesController.dispose();
    _priceController.dispose();
    _notesFocusNode.dispose();
    _priceFocusNode.dispose();
    _notesDebounce?.cancel();
    _priceDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Selector 僅監聽該 index 的書籍物件變化
    // 這樣打字時如果沒有呼叫 notifyListeners，這裡完全不會 rebuild
    return Selector<AiListingWizardProvider, IdentifiedBook>(
      selector: (context, provider) => provider.identifiedBooks[widget.index],
      builder: (context, book, child) {
        return RepaintBoundary( // 效能優化：隔離繪圖區域，避免鍵盤動畫導致不必要的重繪
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(book),
                  // 目前匯入草稿只需提供 org_prod_id，暫時隱藏編輯欄位
                  /*
                  if (book.isSelected) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildConditionDropdown(book),
                    const SizedBox(height: 12),
                    _buildNotesField(),
                    const SizedBox(height: 12),
                    _buildPriceField(),
                  ],
                  */
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(IdentifiedBook book) {
    return Row(
      children: [
        Checkbox(
          value: book.isSelected,
          onChanged: (value) {
            context.read<AiListingWizardProvider>().toggleBookSelection(
              widget.index,
            );
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        _buildBookImage(book),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.titleMain,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.qr_code, 'ISBN', book.isbnDisplay),
              // _buildInfoRow(Icons.star, '書況', book.condition),
            ],
          ),
        ),
      ],
    );
  }

  /*
  Widget _buildConditionDropdown(IdentifiedBook book) {
    return DropdownButtonFormField<String>(
      value: ['全新', '近全新', '良好', '普通', '差強人意'].contains(book.condition)
          ? book.condition
          : '良好',
      decoration: const InputDecoration(
        labelText: '書況',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['全新', '近全新', '良好', '普通', '差強人意']
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          context.read<AiListingWizardProvider>().updateBookCondition(
                widget.index,
                value,
              );
        }
      },
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      focusNode: _notesFocusNode,
      autocorrect: false, // 效能優化：關閉自動修正
      decoration: const InputDecoration(
        labelText: '備註',
        hintText: '請輸入備註（選填）',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      maxLines: 2,
      onChanged: (value) {
        // 使用 Debounce 延遲同步
        if (_notesDebounce?.isActive ?? false) _notesDebounce!.cancel();
        _notesDebounce = Timer(const Duration(milliseconds: 500), () {
          _syncNotesToProvider();
        });
      },
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: _priceController,
      focusNode: _priceFocusNode,
      autocorrect: false, // 效能優化
      enableSuggestions: false, // 效能優化
      decoration: const InputDecoration(
        labelText: '賣價',
        hintText: '請輸入賣價',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixText: 'NT\$ ',
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        // 使用 Debounce 延遲同步
        if (_priceDebounce?.isActive ?? false) _priceDebounce!.cancel();
        _priceDebounce = Timer(const Duration(milliseconds: 500), () {
          _syncPriceToProvider();
        });
      },
    );
  }
  */

  Widget _buildBookImage(IdentifiedBook book) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: book.imageUrl != null
            ? Image.network(
                book.imageUrl!,
                fit: BoxFit.cover,
                cacheWidth: 180, // 關鍵優化：限制圖片解碼大小，大幅降低主執行緒負擔
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage();
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.book, color: Colors.grey, size: 30),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
