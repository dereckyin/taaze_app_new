import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/identified_book.dart';
import '../providers/auth_provider.dart';
import '../providers/ai_listing_wizard_provider.dart';
import '../services/search_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    autoStart: true,
  );

  IdentifiedBook? _scannedBook;
  String? _scannedCode;
  String? _error;
  bool _isSubmitting = false;
  bool _isSearching = false;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _condition = '良好';
  String? _infoMessage;

  @override
  void dispose() {
    _cameraController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isSearching || _isSubmitting) return;
    final first = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final code = first?.rawValue?.trim();
    if (code == null || code.isEmpty) return;
    final sanitized = _sanitizeIsbn(code);
    if (sanitized == null) return; // 非 ISBN 直接忽略
    if (_scannedCode == code && _scannedBook != null) return;

    setState(() {
      _scannedCode = code;
      _error = null;
      _infoMessage = null;
      _isSearching = true;
    });

    try {
      final book = await _fetchBookByIsbn(sanitized);
      if (!mounted) return;
      setState(() {
        _scannedBook = book;
        _condition = book.condition;
        _priceController.text =
            book.sellingPrice?.toStringAsFixed(0) ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      // 搜尋失敗時不顯示錯誤，只是保留掃描狀態，讓使用者繼續掃描
      setState(() {
        _scannedBook = null;
        _infoMessage = '未找到對應書籍，請再試一次或換本書。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<IdentifiedBook> _fetchBookByIsbn(String isbn) async {
    final results =
        await SearchService.searchBooks(keyword: isbn, page: 1, pageSize: 10);
    if (results.books.isEmpty) {
      throw Exception('未找到符合的書籍');
    }

    // 先嘗試 ISBN 完全符合的
    final matched = results.books
        .where((b) => b.isbn == isbn || b.id == isbn || b.orgProdId == isbn)
        .toList();
    final book = matched.isNotEmpty ? matched.first : results.books.first;

    return IdentifiedBook(
      prodId: book.id,
      orgProdId: book.orgProdId ?? book.id,
      eancode: book.isbn.isNotEmpty ? book.isbn : isbn,
      titleMain: book.title,
      condition: '良好',
      isSelected: true,
      sellingPrice: book.salePrice,
    );
  }

  Future<void> _submitDraft() async {
    final book = _scannedBook;
    if (book == null) return;

    final confirmed = await _confirmSubmit();
    if (!confirmed) return;

    final parsedPrice = double.tryParse(_priceController.text.trim());
    final updated = book.copyWith(
      condition: _condition,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      sellingPrice: parsedPrice,
      isSelected: true,
    );

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入後再匯入草稿')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final wizardProvider = context.read<AiListingWizardProvider>();
    wizardProvider.addToLocalDrafts([updated], append: true);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _infoMessage = '已加入本機草稿列表，可於「查看上架草稿」確認後再送出。';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入本機草稿列表')),
      );
      Navigator.pop(context);
    }
  }

  void _resetScan() {
    setState(() {
      _scannedBook = null;
      _scannedCode = null;
      _error = null;
      _infoMessage = null;
      _priceController.clear();
      _notesController.clear();
      _condition = '良好';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _scannedBook != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描條碼'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraController,
                  fit: BoxFit.contain,
                  onDetect: _onDetect,
                ),
                if (_isSearching)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: hasResult ? _buildResultCard() : _buildHint(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: hasResult
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _resetScan,
                      child: const Text('重新掃描'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDraft,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('匯入上架草稿'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHint() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '對準書籍背面的 ISBN 條碼進行掃描。',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '• 直向橫向皆可，避免手指遮擋\n'
          '• 光線不足時可開啟手電筒\n'
          '• 讀取到條碼後會自動帶入單本上架資料',
          style: TextStyle(color: Colors.grey[700]),
        ),
        if (_infoMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _infoMessage!,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard() {
    final book = _scannedBook!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (book.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book.imageUrl!,
                    width: 64,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 90,
                      color: Colors.grey[200],
                      child: const Icon(Icons.book),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.titleMain,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ISBN：${book.isbnDisplay}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ProdId：${book.prodIdDisplay}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _condition,
            decoration: const InputDecoration(
              labelText: '書況',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '全新', child: Text('全新')),
              DropdownMenuItem(value: '近全新', child: Text('近全新')),
              DropdownMenuItem(value: '良好', child: Text('良好')),
              DropdownMenuItem(value: '普通', child: Text('普通')),
              DropdownMenuItem(value: '差強人意', child: Text('差強人意')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _condition = v;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '預設賣價（可留空）',
              prefixText: 'NT\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '備註（可留空）',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ],
        ],
      ),
    );
  }

  /// 僅接受 10 或 13 碼數字（允許含連字號、空白）
  String? _sanitizeIsbn(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10 || digits.length == 13) {
      return digits;
    }
    return null;
  }

  Future<bool> _confirmSubmit() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('確認匯入上架草稿'),
            content: const Text('確認將此書匯入上架草稿嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('確認'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
