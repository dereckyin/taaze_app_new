import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/book_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/banner_provider.dart';
import '../models/banner.dart' as banner_model;
import '../widgets/book_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_app_bar.dart';
import 'book_detail_screen.dart';
import 'search_screen.dart';
import 'category_screen.dart';
import 'book_list_screen.dart';
import 'barcode_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().clearError();
      context.read<BannerProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        controller: _searchController,
        onSearchPressed: () {
          if (_searchController.text.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SearchScreen(query: _searchController.text),
              ),
            );
          }
        },
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          if (bookProvider.isLoading) {
            return const Center(child: LoadingWidget());
          }

          if (bookProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    bookProvider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      bookProvider.clearError();
                      bookProvider.refreshBooks();
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                bookProvider.refreshBooks(),
                context.read<BannerProvider>().refreshBanners(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 橫幅廣告區域
                  _buildBannerSection(),

                  // 快速功能區域
                  _buildQuickActionsSection(),

                  // 分類導航
                  _buildCategorySection(bookProvider.categories),

                  // 今日特惠
                  _buildTodayDealsSection(bookProvider.todayDeals),

                  // 暢銷排行榜
                  _buildBestsellersSection(bookProvider.bestsellers),

                  // 注目新品
                  _buildNewReleasesSection(bookProvider.newReleases),

                  // 最新上架二手書
                  _buildUsedBooksSection(bookProvider.usedBooks),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerSection() {
    return Consumer<BannerProvider>(
      builder: (context, bannerProvider, child) {
        if (bannerProvider.isLoading) {
          return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (bannerProvider.error != null) {
          return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('橫幅載入失敗', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        final banners = bannerProvider.activeBanners;
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // 輪播頁面
              PageView.builder(
                controller: _bannerPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return _buildBannerCard(banner);
                },
              ),

              // 指示器
              if (banners.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      banners.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentBannerIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerCard(banner_model.Banner banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: _getBannerGradientColors(banner.type),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景圖片
          if (banner.imageUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    );
                  },
                ),
              ),
            ),

          // 遮罩層
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 內容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 類型標籤
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    banner.type.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 標題
                Text(
                  banner.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // 副標題
                Text(
                  banner.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // 行動按鈕
                if (banner.actionText != null && banner.actionUrl != null)
                  ElevatedButton(
                    onPressed: () => _handleBannerAction(banner),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      banner.actionText!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getBannerGradientColors(banner_model.BannerType type) {
    switch (type) {
      case banner_model.BannerType.promotion:
        return [Colors.red, Colors.orange];
      case banner_model.BannerType.announcement:
        return [Colors.blue, Colors.indigo];
      case banner_model.BannerType.featured:
        return [Colors.purple, Colors.deepPurple];
      case banner_model.BannerType.newRelease:
        return [Colors.green, Colors.teal];
      case banner_model.BannerType.event:
        return [Colors.amber, Colors.orange];
    }
  }

  void _handleBannerAction(banner_model.Banner banner) {
    if (banner.actionUrl == null) return;

    switch (banner.actionUrl) {
      case '/search':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchScreen(query: ''),
          ),
        );
        break;
      case '/register':
        // 跳轉到註冊頁面
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('跳轉到註冊頁面')));
        break;
      case '/cart':
        // 跳轉到購物車
        Navigator.pushNamed(context, '/cart');
        break;
      case '/books/sale':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookListScreen(
              title: '特價書籍',
              endpoint: '/api/books/today-deals',
            ),
          ),
        );
        break;
      case '/books/new':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookListScreen(
              title: '新書上架',
              endpoint: '/api/books/new-releases',
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('跳轉到: ${banner.actionUrl}')));
    }
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionButton(
            icon: FontAwesomeIcons.fire,
            label: '今日特惠',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookListScreen(
                    title: '今日特惠',
                    endpoint: '/api/books/today-deals',
                  ),
                ),
              );
            },
          ),
          _buildQuickActionButton(
            icon: FontAwesomeIcons.trophy,
            label: '暢銷榜',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookListScreen(
                    title: '暢銷排行榜',
                    endpoint: '/api/books/bestsellers',
                  ),
                ),
              );
            },
          ),
          _buildQuickActionButton(
            icon: FontAwesomeIcons.star,
            label: '注目新品',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookListScreen(
                    title: '注目新品',
                    endpoint: '/api/books/new-releases',
                  ),
                ),
              );
            },
          ),
          _buildQuickActionButton(
            icon: FontAwesomeIcons.bookOpen,
            label: '二手書',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookListScreen(
                    title: '最新上架二手書',
                    endpoint: '/api/books/used-books',
                  ),
                ),
              );
            },
          ),
          _buildQuickActionButton(
            icon: FontAwesomeIcons.qrcode,
            label: '掃描條碼',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('分類', style: Theme.of(context).textTheme.headlineSmall),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(),
                    ),
                  );
                },
                child: const Text('查看全部'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 今日特惠板塊
  Widget _buildTodayDealsSection(List<dynamic> todayDeals) {
    return _buildBookSection(
      title: '今日特惠',
      books: todayDeals,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookListScreen(
              title: '今日特惠',
              endpoint: '/api/books/today-deals',
            ),
          ),
        );
      },
    );
  }

  // 暢銷排行榜板塊
  Widget _buildBestsellersSection(List<dynamic> bestsellers) {
    return _buildBookSection(
      title: '暢銷排行榜',
      books: bestsellers,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookListScreen(
              title: '暢銷排行榜',
              endpoint: '/api/books/bestsellers',
            ),
          ),
        );
      },
    );
  }

  // 注目新品板塊
  Widget _buildNewReleasesSection(List<dynamic> newReleases) {
    return _buildBookSection(
      title: '注目新品',
      books: newReleases,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookListScreen(
              title: '注目新品',
              endpoint: '/api/books/new-releases',
            ),
          ),
        );
      },
    );
  }

  // 最新上架二手書板塊
  Widget _buildUsedBooksSection(List<dynamic> usedBooks) {
    return _buildBookSection(
      title: '最新上架二手書',
      books: usedBooks,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BookListScreen(
              title: '最新上架二手書',
              endpoint: '/api/books/used-books',
            ),
          ),
        );
      },
    );
  }

  // 通用的書籍板塊構建方法
  Widget _buildBookSection({
    required String title,
    required List<dynamic> books,
    required VoidCallback onViewAll,
  }) {
    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              TextButton(onPressed: onViewAll, child: const Text('查看更多')),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: BookCard(
                  book: book,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  onAddToCart: () {
                    context.read<CartProvider>().addToCart(book);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已將《${book.title}》加入購物車'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '程式設計':
        return FontAwesomeIcons.code;
      case '設計':
        return FontAwesomeIcons.palette;
      case '人工智慧':
        return FontAwesomeIcons.robot;
      case '資料庫':
        return FontAwesomeIcons.database;
      case '網路安全':
        return FontAwesomeIcons.shield;
      case '雲端運算':
        return FontAwesomeIcons.cloud;
      case '區塊鏈':
        return FontAwesomeIcons.link;
      default:
        return FontAwesomeIcons.book;
    }
  }
}
