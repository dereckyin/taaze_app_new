import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/book.dart';
import '../models/theme_activity.dart';
import '../providers/theme_content_provider.dart';
import '../screens/book_detail_screen.dart';
import '../widgets/cached_image_widget.dart';

class ThemeActivitySection extends StatelessWidget {
  const ThemeActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeContentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading &&
            provider.themeActivities.isEmpty &&
            provider.hotProducts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.themeActivities.isEmpty && provider.hotProducts.isEmpty) {
          if (provider.error != null) {
            return _RetryBanner(
              message: provider.error!,
              onRetry: provider.load,
            );
          }
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.hotProducts.isNotEmpty) ...[
              _sectionTitle(context, '百貨熱門'),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.hotProducts.length,
                  itemBuilder: (context, i) {
                    final book = provider.hotProducts[i];
                    return _HotProductCard(book: book);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (provider.themeActivities.isNotEmpty) ...[
              _sectionTitle(context, '主題活動'),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.themeActivities.length,
                  itemBuilder: (context, i) {
                    final item = provider.themeActivities[i];
                    return _ThemeCard(activity: item);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ThemeActivity activity;

  const _ThemeCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (activity.imageUrl.isNotEmpty)
              CachedImageWidget(imageUrl: activity.imageUrl, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  activity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final url = activity.actionUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }
}

class _HotProductCard extends StatelessWidget {
  final Book book;

  const _HotProductCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: book),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.imageUrl.isNotEmpty
                    ? CachedImageWidget(imageUrl: book.imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[200]),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RetryBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Text(message, style: TextStyle(color: Colors.grey[600]))),
          TextButton(onPressed: onRetry, child: const Text('重試')),
        ],
      ),
    );
  }
}
