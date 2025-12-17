import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_widget.dart';
import 'book_detail_screen.dart';

class BookListScreen extends StatefulWidget {
  final String title;
  final String? category;
  final String? searchQuery;
  final String? endpoint;
  final int startNum;
  final int endNum;

  const BookListScreen({
    super.key,
    required this.title,
    this.category,
    this.searchQuery,
    this.endpoint,
    this.startNum = 0,
    this.endNum = 19,
  });

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  late int _nextStart;
  late int _pageSize;
  String? _resolvedEndpoint;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _resolvedEndpoint = widget.endpoint ?? _inferEndpointFromTitle(widget.title);

    // 依據傳入的 start/end 計算分頁範圍
    final computedSize = widget.endNum - widget.startNum + 1;
    _pageSize = computedSize > 0 ? computedSize : 20;
    _nextStart = widget.startNum;

    // 載入第一頁資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFirstPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadFirstPage() async {
    final bookProvider = context.read<BookProvider>();
    bookProvider.resetPagination();
    _nextStart = widget.startNum;

    // 根據endpoint決定載入策略
    if (_resolvedEndpoint != null) {
      await _loadBooksByEndpoint();
    } else {
      await bookProvider.loadBooksWithPagination(
        category: widget.category,
        searchQuery: widget.searchQuery,
        page: 1,
        pageSize: 20,
      );
    }
  }

  Future<void> _loadBooksByEndpoint() async {
    if (_resolvedEndpoint == null) return;
    final bookProvider = context.read<BookProvider>();

    // 使用BookProvider的公共方法載入對應的資料
    await bookProvider.loadBooksByEndpoint(
      _resolvedEndpoint!,
      startNum: _nextStart,
      endNum: _nextStart + _pageSize - 1,
      append: _nextStart != widget.startNum,
    );

    // 更新下一次的起迄
    _nextStart += _pageSize;
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore) return;
    final bookProvider = context.read<BookProvider>();
    if (!bookProvider.hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    if (_resolvedEndpoint != null) {
      // endpoint 模式，根據 start/end 取下一頁
      await _loadBooksByEndpoint();
    } else {
      await context.read<BookProvider>().loadMoreBooks(
        category: widget.category,
        searchQuery: widget.searchQuery,
      );
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    await _loadFirstPage();
  }

  String? _inferEndpointFromTitle(String title) {
    if (title.contains('注目新品')) {
      return BookProvider.taazeNewArrivalsEndpoint;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          if (bookProvider.isLoading && bookProvider.books.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          if (bookProvider.error != null && bookProvider.books.isEmpty) {
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
                    onPressed: _onRefresh,
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                // 結果統計
                if (bookProvider.totalCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Text(
                      '共找到 ${bookProvider.totalCount} 本書籍',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                // 書籍列表
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        bookProvider.books.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= bookProvider.books.length) {
                        return _buildLoadingMoreIndicator();
                      }

                      final book = bookProvider.books[index];
                      return BookListTile(
                        book: book,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookDetailScreen(book: book),
                            ),
                          );
                        },
                        onAddToCart: () {
                          context.read<CartProvider>().addToCart(book);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已將《${book.title}》加入購物車'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('載入更多...'),
                ],
              )
            : const Text('沒有更多資料了', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
