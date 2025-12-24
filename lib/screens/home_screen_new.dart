import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/book_provider.dart';
import '../providers/bestsellers_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_app_bar.dart';
import 'book_detail_screen.dart';
import 'search_screen.dart';
import 'category_screen.dart';
import 'book_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              await bookProvider.refreshBooks();
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
                  _buildBestsellersSection(),

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
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Icon(
              FontAwesomeIcons.book,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '讀冊生活網路書店',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '探索數千本精彩書籍，享受閱讀的美好時光',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(query: ''),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('開始探索'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    startNum: 0,
                    endNum: 19,
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
                    endpoint: '/content/bestsellers',
                    startNum: 0,
                    endNum: 9,
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
                    startNum: 0,
                    endNum: 19,
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
                    startNum: 0,
                    endNum: 19,
                  ),
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

  Future<void> _openTodayDealsPage() async {
    const url = 'https://www.taaze.tw/act66.html';
    final uri = Uri.parse(url);
    try {
      final openedExternally =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!openedExternally) {
        final openedInApp = await launchUrl(uri);
        if (!openedInApp) {
          throw Exception('unable to open');
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法開啟今日特惠頁面，請稍後再試')),
      );
    }
  }

  // 今日特惠板塊
  Widget _buildTodayDealsSection(List<dynamic> todayDeals) {
    return _buildBookSection(
      title: '今日特惠',
      books: todayDeals,
      onViewAll: _openTodayDealsPage,
    );
  }

  // 暢銷排行榜板塊
  // 暢銷排行榜板塊（使用 BestsellersProvider）
  Widget _buildBestsellersSection() {
    return Consumer<BestsellersProvider>(
      builder: (context, bestsellersProvider, child) {
        if (bestsellersProvider.isLoading) {
          return _buildBookSection(
            title: '暢銷排行榜',
            books: const [],
            onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookListScreen(
                    title: '暢銷排行榜',
                    endpoint: '/content/bestsellers',
                    startNum: 0,
                    endNum: 9,
                  ),
                ),
              );
            },
          );
        }

        final bestsellers = bestsellersProvider.bestsellers;
        if (bestsellers.isEmpty) return const SizedBox.shrink();

        return _buildBookSection(
          title: '暢銷排行榜',
          books: bestsellers,
          onViewAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookListScreen(
                  title: '暢銷排行榜',
                  endpoint: '/content/bestsellers',
                  startNum: 0,
                  endNum: 9,
                ),
              ),
            );
          },
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
              startNum: 0,
              endNum: 19,
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
              startNum: 0,
              endNum: 19,
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
