import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/bookstore.dart';
import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_bag_screen.dart';
import 'bookstore_product_screen.dart';
import 'bookstore_scan_screen.dart';
import 'bookstore_widgets.dart';
import 'door_qr_scanner_screen.dart';

/// 店內商品展示：搜尋、分類、書牆，底部固定「掃書／店內袋」
class BookstoreHomeScreen extends StatefulWidget {
  const BookstoreHomeScreen({super.key});

  @override
  State<BookstoreHomeScreen> createState() => _BookstoreHomeScreenState();
}

class _BookstoreHomeScreenState extends State<BookstoreHomeScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  List<BookstoreCategory> _categories = const [];
  String? _categoryId;
  String _sort = 'new';
  final List<BookstoreProduct> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? get _storeId => context.read<BookstoreProvider>().store?.id;

  Future<void> _loadCategories() async {
    final token = await requireToken(context);
    final storeId = _storeId;
    if (token == null || storeId == null) return;
    try {
      final cats = await BookstoreService.listCategories(token, storeId);
      if (mounted) setState(() => _categories = cats);
    } on BookstoreException {
      // 分類載入失敗不影響逛書
    }
  }

  Future<void> _reload() async {
    _generation++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    final token = await requireToken(context);
    final storeId = _storeId;
    if (!mounted || token == null || storeId == null) return;
    setState(() => _loading = true);
    try {
      final page = await BookstoreService.listProducts(
        token,
        storeId,
        query: _search.text.trim(),
        categoryId: _categoryId,
        sort: _sort,
        page: _page + 1,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } on BookstoreException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  void _add(BookstoreProduct p) {
    final result = context.read<BookstoreProvider>().add(p);
    final msg = switch (result) {
      BagAddResult.added => '已加入店內袋：${p.name}',
      BagAddResult.maxReached => '這本書已達可購買數量',
      BagAddResult.unavailable => '這本書目前已售完',
    };
    if (result == BagAddResult.added) HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  Future<void> _scanDoor() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const DoorQrScannerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bag = context.watch<BookstoreProvider>();
    final store = bag.store;
    if (store == null) {
      return const Scaffold(body: Center(child: Text('請先選擇門市')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.name, style: const TextStyle(fontSize: 17)),
            Text(
              bag.isInStore ? '已在店內，可自助結帳' : '瀏覽中・到店掃門口 QR 才能結帳',
              style: TextStyle(
                fontSize: 11,
                color: bag.isInStore ? AppTheme.successColor : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          if (!bag.isInStore)
            IconButton(
              tooltip: '掃門口 QR Code',
              icon: const Icon(Icons.qr_code_2),
              onPressed: _scanDoor,
            ),
          PopupMenuButton<String>(
            tooltip: '排序',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (v) {
              _sort = v;
              _reload();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('最新上架')),
              PopupMenuItem(value: 'title', child: Text('依書名')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!store.isOpen)
            MaterialBanner(
              content: const Text('這家店目前暫停營業，仍可瀏覽但無法結帳'),
              leading: const Icon(Icons.info_outline),
              actions: [const SizedBox.shrink()],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜尋店內書名、作者、ISBN',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _reload();
                        },
                      ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('全部', null),
                  for (final c in _categories) _chip(c.name, c.id),
                ],
              ),
            ),
          Expanded(child: _buildGrid()),
        ],
      ),
      bottomNavigationBar: BagBottomBar(
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookstoreScanScreen()),
        ),
        onOpenBag: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookstoreBagScreen()),
        ),
      ),
    );
  }

  Widget _chip(String label, String? id) {
    final selected = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        onSelected: (_) {
          if (selected) return;
          setState(() => _categoryId = id);
          _reload();
        },
      ),
    );
  }

  Widget _buildGrid() {
    if (_items.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_error != null) return ErrorRetry(message: _error!, onRetry: _reload);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_search.text.isEmpty ? '店內暫時沒有上架的書' : '店內找不到符合的書'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.52,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final p = _items[i];
          return _ProductCard(
            product: p,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookstoreProductScreen(product: p)),
            ),
            onAdd: () => _add(p),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final BookstoreProduct product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _ProductCard({required this.product, required this.onTap, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final inBag = context.select<BookstoreProvider, int>((b) => b.qtyOf(product.id));
    final soldOut = !product.available;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: soldOut ? 0.45 : 1,
                        child: BookstoreCover(url: product.imageUrl),
                      ),
                    ),
                    Positioned(left: 6, top: 6, child: StockChip(status: product.stockStatus, dense: true)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 2),
              Text(
                product.author ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: PriceText(price: product.price, listPrice: product.listPrice, fontSize: 14)),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton.filled(
                      padding: EdgeInsets.zero,
                      onPressed: soldOut ? null : onAdd,
                      style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      icon: inBag > 0
                          ? Text('$inBag', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          : const Icon(Icons.add, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
