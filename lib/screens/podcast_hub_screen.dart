import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/book_provider.dart';
import '../services/podcast_progress_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_widget.dart';
import '../widgets/podcast_hub_book_tile.dart';
import 'book_detail_screen.dart';

class PodcastHubScreen extends StatefulWidget {
  const PodcastHubScreen({super.key});

  @override
  State<PodcastHubScreen> createState() => _PodcastHubScreenState();
}

class _PodcastHubScreenState extends State<PodcastHubScreen> {
  final ScrollController _scrollController = ScrollController();
  Map<String, int> _progressMs = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().loadPodcastBooks();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 320) {
      context.read<BookProvider>().loadMorePodcastBooks();
    }
  }

  Future<void> _loadProgress() async {
    final map = await PodcastProgressService.loadAllPositions();
    if (mounted) setState(() => _progressMs = map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '聽書專區', showBackButton: true),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          if (bookProvider.isLoadingPodcast &&
              bookProvider.podcastBooks.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          final books = bookProvider.podcastBooks;
          if (books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.podcasts, size: 72, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('目前沒有可試聽的 Podcast 書籍'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => bookProvider.loadPodcastBooks(),
                      child: const Text('重新載入'),
                    ),
                  ],
                ),
              ),
            );
          }

          final showFooter = bookProvider.isLoadingPodcast ||
              !bookProvider.podcastHasMore;
          final itemCount = books.length + (showFooter ? 1 : 0);

          return RefreshIndicator(
            onRefresh: () async {
              await bookProvider.loadPodcastBooks();
              await _loadProgress();
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index >= books.length) {
                  if (bookProvider.isLoadingPodcast) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        bookProvider.podcastTotal > 0
                            ? '已載入全部 ${bookProvider.podcastTotal} 本'
                            : '沒有更多了',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  );
                }
                final book = books[index];
                final progressMs =
                    _progressMs[book.id] ?? _progressMs[book.orgProdId];
                return PodcastHubBookTile(
                  book: book,
                  savedProgressMs: progressMs,
                  onProgressUpdated: _loadProgress,
                  onOpenDetail: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: book),
                      ),
                    );
                    await _loadProgress();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
