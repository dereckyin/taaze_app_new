import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/social_feed_provider.dart';
import '../screens/book_detail_screen.dart';
import '../screens/login_screen.dart';

class SocialFeedSection extends StatefulWidget {
  const SocialFeedSection({super.key});

  @override
  State<SocialFeedSection> createState() => _SocialFeedSectionState();
}

class _SocialFeedSectionState extends State<SocialFeedSection> {
  String? _loadedForCustId;

  void _scheduleLoadIfNeeded() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.user == null) return;
    final custId = auth.user!.id;
    if (_loadedForCustId == custId) return;
    _loadedForCustId = custId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialFeedProvider>().loadForUser(custId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleLoadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SocialFeedProvider, AuthProvider>(
      builder: (context, feedProvider, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return _guestPrompt(context);
        }

        if (feedProvider.isLoading && feedProvider.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (feedProvider.items.isEmpty) {
          if (feedProvider.error != null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text(feedProvider.error!)),
                  TextButton(
                    onPressed: () => feedProvider.loadForUser(
                      authProvider.user!.id,
                    ),
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '書友動態',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...feedProvider.items.take(5).map((item) {
              final label = item.isReading ? '正在閱讀' : '收藏了';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (item.nickName?.isNotEmpty == true)
                        ? item.nickName![0]
                        : '?',
                  ),
                ),
                title: Text(
                  '${item.nickName ?? '書友'} $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.prodName ?? item.prodId} · ${item.crtTime}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  if (item.prodId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailScreen(
                        book: Book.minimal(
                          id: item.prodId,
                          title: item.prodName ?? '書籍詳情',
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _guestPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('書友動態'),
          subtitle: const Text('登入後查看閱讀與收藏動態'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ),
    );
  }
}
