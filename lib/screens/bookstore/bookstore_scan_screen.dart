import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/bookstore.dart';
import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_bag_screen.dart';
import 'bookstore_widgets.dart';

/// 連續掃書：掃到就加入購物籃，不用每本確認
class BookstoreScanScreen extends StatefulWidget {
  const BookstoreScanScreen({super.key});

  @override
  State<BookstoreScanScreen> createState() => _BookstoreScanScreenState();
}

class _BookstoreScanScreenState extends State<BookstoreScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
    detectionSpeed: DetectionSpeed.normal,
  );
  final Map<String, DateTime> _recent = {};
  bool _busy = false;
  BookstoreProduct? _last;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    final seen = _recent[raw];
    if (seen != null && DateTime.now().difference(seen) < const Duration(milliseconds: 2500)) return;
    _recent[raw] = DateTime.now();
    await _lookup(raw);
  }

  Future<void> _lookup(String code) async {
    if (_busy) return;
    final storeId = context.read<BookstoreProvider>().store?.id;
    final token = await requireToken(context);
    if (!mounted || token == null || storeId == null) return;
    setState(() => _busy = true);
    try {
      final product = await BookstoreService.lookup(token, storeId, code);
      if (!mounted) return;
      final result = context.read<BookstoreProvider>().add(product);
      switch (result) {
        case BagAddResult.added:
          HapticFeedback.mediumImpact();
          SystemSound.play(SystemSoundType.click);
          _show(product, '已加入購物籃', false);
        case BagAddResult.maxReached:
          HapticFeedback.heavyImpact();
          _show(product, '已達可購買數量（${product.maxQty} 本）', true);
        case BagAddResult.unavailable:
          HapticFeedback.heavyImpact();
          _show(product, '系統顯示已售完，請洽店員', true);
      }
    } on BookstoreException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _show(null, e.message, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(BookstoreProduct? product, String message, bool isError) {
    setState(() {
      _last = product;
      _message = message;
      _messageIsError = isError;
    });
  }

  Future<void> _manualInput() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手動輸入條碼'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'ISBN 或書背條碼'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('查詢')),
        ],
      ),
    );
    controller.dispose();
    final trimmed = code?.trim() ?? '';
    if (trimmed.isNotEmpty) await _lookup(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final bag = context.watch<BookstoreProvider>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('掃書加入'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: '手電筒',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: '手動輸入',
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: _manualInput,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Container(
              width: 280,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: _busy ? AppTheme.warningColor : Colors.white, width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const Align(
            alignment: Alignment(0, 0.05),
            child: Text('對準書背或封底的條碼', style: TextStyle(color: Colors.white70)),
          ),
          Positioned(left: 12, right: 12, bottom: 12, child: _resultCard()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BookstoreBagScreen()),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(bag.isEmpty ? '查看購物籃' : '完成・購物籃 ${bag.itemCount} 本 ${ntd(bag.estimatedSubtotal)}'),
          ),
        ),
      ),
    );
  }

  Widget _resultCard() {
    if (_message == null) return const SizedBox.shrink();
    final color = _messageIsError ? AppTheme.errorColor : AppTheme.successColor;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_last != null) ...[
              BookstoreCover(url: _last!.imageUrl, width: 44, height: 60),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(_messageIsError ? Icons.error_outline : Icons.check_circle, color: color, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_message!, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (_last != null) ...[
                    const SizedBox(height: 4),
                    Text(_last!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(ntd(_last!.price), style: const TextStyle(color: AppTheme.primaryColor)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
