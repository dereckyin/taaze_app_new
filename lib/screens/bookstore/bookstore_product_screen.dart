import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/bookstore.dart';
import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_bag_screen.dart';
import 'bookstore_widgets.dart';

/// 店內商品詳情：顯示店內即時庫存，可直接加入購物車
class BookstoreProductScreen extends StatefulWidget {
  final BookstoreProduct product;

  const BookstoreProductScreen({super.key, required this.product});

  @override
  State<BookstoreProductScreen> createState() => _BookstoreProductScreenState();
}

class _BookstoreProductScreenState extends State<BookstoreProductScreen> {
  late BookstoreProduct _product = widget.product;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final token = await requireToken(context);
    if (!mounted) return;
    final storeId = context.read<BookstoreProvider>().store?.id;
    if (token == null || storeId == null) return;
    try {
      final fresh = await BookstoreService.getProduct(token, storeId, _product.id);
      if (mounted) setState(() => _product = fresh);
    } on BookstoreException catch (e) {
      if (mounted) showBookstoreError(context, e);
    }
  }

  void _add() {
    final result = context.read<BookstoreProvider>().add(_product);
    final msg = switch (result) {
      BagAddResult.added => '已加入購物車',
      BagAddResult.maxReached => '已達可購買數量（${_product.maxQty} 本）',
      BagAddResult.unavailable => '這本書目前已售完',
    };
    if (result == BagAddResult.added) HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        action: result == BagAddResult.added
            ? SnackBarAction(
                label: '看購物車',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookstoreBagScreen()),
                ),
              )
            : null,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final inBag = context.select<BookstoreProvider, int>((b) => b.qtyOf(p.id));
    final meta = <(String, String?)>[
      ('作者', p.author),
      ('出版社', p.publisher),
      ('ISBN', p.isbn),
      ('分類', p.categoryName),
    ].where((e) => e.$2 != null && e.$2!.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('店內商品')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: BookstoreCover(url: p.imageUrl, width: 180, height: 250)),
            const SizedBox(height: 20),
            Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.35)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: PriceText(price: p.price, listPrice: p.listPrice, fontSize: 22)),
                StockChip(status: p.stockStatus),
              ],
            ),
            if (p.available)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '這家店可購買 ${p.maxQty} 本',
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                ),
              ),
            const Divider(height: 32),
            for (final (label, value) in meta)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
                    ),
                    Expanded(child: Text(value!)),
                  ],
                ),
              ),
            if (p.description != null) ...[
              const Divider(height: 32),
              const Text('內容簡介', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(p.description!, style: const TextStyle(height: 1.6)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.infoColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '書在店內架上。拿到實體書後直接「掃書加入」最準確。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: p.available ? _add : null,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(!p.available ? '已售完' : inBag > 0 ? '再加一本（袋內 $inBag 本）' : '加入購物車'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
