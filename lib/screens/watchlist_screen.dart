import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/watchlist_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../models/book.dart';
import '../widgets/cached_image_widget.dart';
import 'book_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Map<String, Book> _detailCache = {};
  final Set<String> _loadingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.authToken != null) {
      context.read<WatchlistProvider>().fetchRemoteWatchlist(authProvider.authToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的暫存'),
      ),
      body: Consumer<WatchlistProvider>(
        builder: (context, watchlistProvider, child) {
          if (watchlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allIds = watchlistProvider.allIds;
          if (allIds.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _fetchData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allIds.length,
              itemBuilder: (context, index) {
                final id = allIds[index];
                final remoteItem = watchlistProvider.remoteItems.firstWhere(
                  (item) => item is Map && _matchesWatchlistId(item, id),
                  orElse: () => null,
                );
                return _buildWatchlistTile(id, remoteItem);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '目前沒有暫存書籍',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('您可以去逛逛書籍並將感興趣的加入暫存'),
        ],
      ),
    );
  }

  Widget _buildWatchlistTile(String id, dynamic remoteItem) {
    String title = '店內碼: $id';
    String? imageUrl;
    String? author;
    double priceValue = 0;
    Book? detailBook;

    // 1. 從 remoteItem 拿基礎資料
    if (remoteItem is Map) {
      final rTitle = (remoteItem['titleMain'] ??
              remoteItem['title_main'] ??
              remoteItem['title'])
          ?.toString();
      if (rTitle != null && rTitle.isNotEmpty) title = rTitle;
      author = remoteItem['author']?.toString();
      priceValue = (remoteItem['sale_price'] ??
              remoteItem['salePrice'] ??
              remoteItem['price'] ??
              0)
          .toDouble();
      final rProdId =
          (remoteItem['prod_id'] ?? remoteItem['prodId'])?.toString();
      if (rProdId != null) {
        imageUrl =
            'https://media.taaze.tw/showThumbnail.html?sc=$rProdId&height=200&width=150';
      }
    }

    // 2. 如果快取有資料（API 抓回來的），優先使用快取覆蓋
    if (_detailCache.containsKey(id)) {
      detailBook = _detailCache[id];
      if (detailBook != null) {
        if (detailBook.title.isNotEmpty) title = detailBook.title;
        if (detailBook.author.isNotEmpty) author = detailBook.author;
        if ((detailBook.salePrice ?? detailBook.price) > 0) {
          priceValue = detailBook.salePrice ?? detailBook.price;
        }
        if (detailBook.imageUrl.isNotEmpty) imageUrl = detailBook.imageUrl;
      }
    }

    // 3. 如果標題還是店內碼，觸發爬蟲
    if ((title == '店內碼: $id' || title.isEmpty) && !_loadingIds.contains(id)) {
      _loadingIds.add(id);
      String lookupId = id;
      if (remoteItem is Map) {
        final orgProdId =
            (remoteItem['org_prod_id'] ?? remoteItem['orgProdId'])?.toString();
        if (orgProdId != null && orgProdId.isNotEmpty) lookupId = orgProdId;
      }
      _fetchDetail(id, lookupId: lookupId);
    }

    // 建立一個骨架 Book 物件，點選時傳入詳情頁
    final book = detailBook ??
        Book(
          id: id,
          title: title,
          author: author ?? '',
          imageUrl: imageUrl ?? '',
          price: priceValue,
          salePrice: priceValue,
          description: '',
          category: '',
          rating: 0,
          reviewCount: 0,
          isAvailable: true,
          publishDate: DateTime.now(),
          isbn: '',
          pages: 0,
          publisher: '',
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 書籍圖片
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imageUrl != null
                    ? CachedImageWidget(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.book, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              // 書籍資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.startsWith('店內碼:') ? title : '書名: $title',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (author != null && author.isNotEmpty)
                      Text(
                        '作者: $author',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        priceValue > 0
                            ? Text(
                                '優惠價: NT\$ ${priceValue.toInt()}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : Text(
                                '價格未知',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<CartProvider>().addToCart(book);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已將《$title》加入購物車'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('加入購物車'),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchDetail(String id, {required String lookupId}) async {
    try {
      final uri = Uri.parse('https://service.taaze.tw/product/$lookupId');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return;
      }
      final decoded = json.decode(utf8.decode(response.bodyBytes));

      // 萃取 book_data，支援 Map 或 List 格式
      Map<String, dynamic>? bookData;
      if (decoded is Map<String, dynamic>) {
        bookData = decoded['book_data'] as Map<String, dynamic>? ?? decoded;
      } else if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) {
          bookData = first['book_data'] as Map<String, dynamic>? ?? first;
        }
      }

      final data = bookData;
      if (data == null || data.isEmpty) return;

      final title = (data['titleMain'] ?? data['title_main'] ?? data['title'])
          ?.toString() ??
          '';
      final salePrice =
          _tryParseOptionalDouble(data['salePrice'] ?? data['sale_price']);
      final author = data['author']?.toString() ?? '';

      if (title.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _detailCache[id] = Book(
          id: id,
          orgProdId: lookupId,
          title: title,
          author: author,
          description: '',
          price: salePrice ?? 0,
          listPrice: _tryParseOptionalDouble(data['listPrice'] ?? data['list_price']),
          salePrice: salePrice,
          imageUrl:
              'https://media.taaze.tw/showLargeImage.html?sc=$lookupId&height=200&width=150&fill=f',
          category: '',
          rating: 0,
          reviewCount: 0,
          isAvailable: true,
          publishDate: DateTime.now(),
          isbn: (data['eancode'] ?? data['isbn'])?.toString() ?? '',
          pages: 0,
          publisher: data['publisher']?.toString() ?? '',
        );
      });
    } catch (_) {
      // ignore
    } finally {
      _loadingIds.remove(id);
    }
  }

  double? _tryParseOptionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.tryParse(cleaned);
    }
    return null;
  }

  bool _matchesWatchlistId(Map item, String id) {
    final prodId = (item['prod_id'] ?? item['prodId'])?.toString();
    final orgProdId = (item['org_prod_id'] ?? item['orgProdId'])?.toString();
    return prodId == id || orgProdId == id;
  }
}
