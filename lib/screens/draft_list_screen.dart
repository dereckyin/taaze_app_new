import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ai_listing_wizard_provider.dart';
import '../providers/auth_provider.dart';
import '../services/book_identification_service.dart';

class DraftListScreen extends StatefulWidget {
  const DraftListScreen({super.key});

  @override
  State<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends State<DraftListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上架草稿'),
      ),
      body: Consumer<AiListingWizardProvider>(
        builder: (context, provider, _) {
          final items = provider.localDrafts;
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('目前沒有上架草稿')),
              ],
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final book = items[index];
                    return ListTile(
                      leading: const Icon(Icons.book_outlined),
                      title: Text(
                        book.titleMain.isEmpty ? '未命名書籍' : book.titleMain,
                      ),
                      subtitle: Text(
                        [
                          if (book.prodIdDisplay.isNotEmpty) 'ProdId: ${book.prodIdDisplay}',
                          if (book.isbnDisplay.isNotEmpty) 'ISBN: ${book.isbnDisplay}',
                          if (book.condition.isNotEmpty) '書況: ${book.condition}',
                        ].join(' ｜ '),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _confirmClear(provider),
                        child: const Text('清空本機草稿'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _submitDrafts(provider),
                        child: const Text('送出上架草稿'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(AiListingWizardProvider provider) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('清空本機草稿'),
            content: const Text('確定要清空本機暫存的上架草稿嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('清空'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      provider.clearLocalDrafts();
    }
  }

  Future<void> _submitDrafts(AiListingWizardProvider provider) async {
    if (provider.localDrafts.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入再送出草稿')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('送出上架草稿'),
            content: Text('即將送出 ${provider.localDrafts.length} 筆草稿到後端，確認送出嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('確認送出'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    try {
      final ok = await BookIdentificationService.importToDraft(
        provider.localDrafts,
        authToken: auth.authToken,
      );
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已送出上架草稿')),
        );
        provider.clearLocalDrafts();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('送出失敗，請稍後再試')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送出失敗：$e')),
      );
    }
  }
}
