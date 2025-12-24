import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_widget.dart';
import '../services/search_service.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<Book> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  String _currentQuery = '';
  String? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    if (widget.query.isNotEmpty) {
      _performSearch(widget.query);
    }

    // 設置滾動監聽器以實現無限滾動
    _scrollController.addListener(_onScroll);

    // 延遲聚焦，確保TextField完全建立後再聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreResults();
    }
  }

  void _loadMoreResults() async {
    if (_isLoadingMore || !_hasMoreData || _currentQuery.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreResults = await SearchService.searchBooks(
        keyword: _currentQuery,
        page: _currentPage + 1,
      );

      if (mounted) {
        setState(() {
          if (moreResults.books.isEmpty) {
            _hasMoreData = false;
          } else {
            _searchResults.addAll(moreResults.books);
            _currentPage++;
            _hasMoreData = moreResults.hasMore;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          // 載入更多失敗時不顯示錯誤，只是停止載入
        });
      }
    }
  }

  void _performSearch(String query) {
    // 取消之前的延遲搜尋
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
        _isSearching = false;
        _error = null;
        _currentPage = 1;
        _hasMoreData = true;
      });
      return;
    }

    // 設置延遲搜尋，避免頻繁API調用
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        setState(() {
          _isSearching = true;
          _currentQuery = query;
          _error = null;
          _currentPage = 1;
          _hasMoreData = true;
        });

        try {
          final results = await SearchService.searchBooks(
            keyword: query,
            page: 1,
          );
          if (mounted) {
            setState(() {
              _searchResults = results.books;
              _isSearching = false;
              _currentPage = 1;
              _hasMoreData = results.hasMore;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = '搜尋失敗：${e.toString()}';
              _isSearching = false;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true, // 自動聚焦，讓鍵盤自動顯示
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '搜尋書籍...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {}); // 重新構建以顯示/隱藏清除按鈕
              _performSearch(value);
            },
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: LoadingWidget());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_currentQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildSearchResults();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            '搜尋出錯',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.red[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '未知錯誤',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
              _performSearch(_currentQuery);
            },
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '搜尋書籍',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '輸入書名、作者或關鍵字來搜尋',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '找不到相關書籍',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '請嘗試其他關鍵字',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // 搜尋結果標題
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('搜尋結果', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 8),
              Text(
                '(${_searchResults.length} 本書)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // 搜尋結果列表
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length + (_hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              // 如果是最後一個項目且還有更多資料，顯示載入指示器
              if (index == _searchResults.length) {
                return _buildLoadingMoreIndicator();
              }

              final book = _searchResults[index];
              return BookListTile(
                book: book,
                showAddToCartButton: false, // 移除購物車按鈕
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(book: book),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
            : _hasMoreData
            ? const Text('滑動到底部載入更多', style: TextStyle(color: Colors.grey))
            : const Text('沒有更多資料了', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
