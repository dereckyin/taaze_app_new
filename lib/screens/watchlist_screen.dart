import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                  (item) => (item is Map && item['prod_id']?.toString() == id),
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
    String title = '書籍 ID: $id';
    String? imageUrl;
    String? author;
    double priceValue = 0;

    if (remoteItem is Map) {
      title = remoteItem['title_main'] ?? remoteItem['title'] ?? title;
      author = remoteItem['author'];
      priceValue = (remoteItem['sale_price'] ?? remoteItem['salePrice'] ?? remoteItem['price'] ?? 0).toDouble();
      final prodId = remoteItem['prod_id']?.toString();
      if (prodId != null) {
        imageUrl = 'https://media.taaze.tw/showThumbnail.html?sc=$prodId&height=200&width=150';
      }
    }

    // 建立一個骨架 Book 物件，點選時傳入詳情頁
    final book = Book(
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
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (author != null)
                      Text(
                        author,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NT\$ ${priceValue.toInt()}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
}
