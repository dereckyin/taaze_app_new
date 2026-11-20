import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/support_provider.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/ai_listing_wizard_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/bookstore/bookstore_entry_screen.dart';
import '../screens/category_browse_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/messages_hub_screen.dart';
import '../screens/register_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/podcast_hub_screen.dart';

/// 對齊官網 RWD 漢堡選單：站內頻道 + 「書籍」展開後顯示分類 + App 服務。
class SiteNavDrawer extends StatefulWidget {
  const SiteNavDrawer({super.key});

  @override
  State<SiteNavDrawer> createState() => _SiteNavDrawerState();
}

class _SiteNavDrawerState extends State<SiteNavDrawer> {
  bool _booksExpanded = false;
  bool _ebooksExpanded = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法開啟連結')),
      );
    }
  }

  void _closeAnd(VoidCallback action) {
    Navigator.of(context).pop(); // close drawer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  void _goHome() {
    _closeAnd(() {
      MainScreen.openTab(0);
    });
  }

  Future<bool> _ensureLogin(String message) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return false;
    return context.read<AuthProvider>().isAuthenticated;
  }

  Future<void> _openSupport() async {
    final nav = Navigator.of(context);
    final ok = await _ensureLogin('請先登入後再聯絡客服');
    if (!ok || !mounted) return;
    final support = context.read<SupportProvider>();
    final token = await context.read<AuthProvider>().tokenForApi();
    if (!mounted) return;
    if (token != null) {
      await support.refreshUnreadCount(token);
    }
    if (!mounted) return;
    if (MainScreen.navKey.currentState != null) {
      MainScreen.openMessages(tab: 0);
    } else {
      nav.push(
        MaterialPageRoute(
          builder: (_) => const MessagesHubScreen(initialTab: 0),
        ),
      );
    }
  }

  Future<void> _openBookstore() async {
    final nav = Navigator.of(context);
    final ok = await _ensureLogin('請先登入後再使用門市自助結帳');
    if (!ok || !mounted) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const BookstoreEntryScreen()),
    );
  }

  Future<void> _openBarcodeScanner() async {
    final nav = Navigator.of(context);
    final ok = await _ensureLogin('請先登入後再掃描條碼');
    if (!ok || !mounted) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final auth = context.watch<AuthProvider>();
    final bookProvider = context.watch<BookProvider>();
    final supportUnread = context.watch<SupportProvider>().unreadCount;
    final bookCats = bookProvider.levelOneCategories; // List<String>

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _link(
              label: '首頁',
              emphasize: true,
              onTap: _goHome,
            ),
            if (!auth.isAuthenticated) ...[
              _link(
                label: '登入',
                onTap: () => _closeAnd(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }),
              ),
              _outlineButton(
                label: '註冊',
                primary: primary,
                onTap: () => _closeAnd(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                }),
              ),
            ],
            _link(
              label: '暫存清單',
              onTap: () => _closeAnd(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WatchlistScreen()),
                );
              }),
            ),
            const Divider(height: 24),

            // 書籍：展開顯示分類（對應官網 hover）
            _expandableBooks(
              primary: primary,
              categories: bookCats,
              onCategoryTap: (name) {
                _closeAnd(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoryBrowseScreen(initialCategoryName: name),
                    ),
                  );
                });
              },
              onBrowseAll: () {
                _closeAnd(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryBrowseScreen(),
                    ),
                  );
                });
              },
            ),
            _link(
              label: '雜誌',
              onTap: () => _closeAnd(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookListScreen(
                      title: '雜誌',
                      category: '雜誌',
                    ),
                  ),
                );
              }),
            ),
            _expandableEbooks(
              primary: primary,
              onChineseEbook: () {
                _closeAnd(() {
                  context.read<BookProvider>().loadCategories(prodCatId: '14');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryBrowseScreen(
                        prodCatId: '14',
                        title: '中文電子書',
                      ),
                    ),
                  );
                });
              },
              onChineseEmag: () {
                _closeAnd(() {
                  context.read<BookProvider>().loadCategories(prodCatId: '25');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryBrowseScreen(
                        prodCatId: '25',
                        title: '中文電子雜誌',
                      ),
                    ),
                  );
                });
              },
              onNewArrivals: () {
                _closeAnd(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookListScreen(
                        title: '電子書注目新品',
                        endpoint: ApiConfig.ebookNewArrivalsEndpoint,
                        startNum: 0,
                        endNum: 19,
                      ),
                    ),
                  );
                });
              },
            ),
            _link(
              label: '二手書',
              onTap: () => _closeAnd(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookListScreen(
                      title: '最新上架二手書',
                      endpoint: ApiConfig.usedBooksLatestEndpoint,
                      startNum: 0,
                      endNum: 19,
                    ),
                  ),
                );
              }),
            ),
            _link(
              label: 'CD/DVD',
              onTap: () => _closeAnd(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookListScreen(
                      title: 'CD/DVD',
                      category: 'CD/DVD',
                    ),
                  ),
                );
              }),
            ),
            _link(
              label: '文具百貨',
              onTap: () => _closeAnd(() {
                _openUrl(
                  'https://www.taaze.tw/rwd_searchResult.html?keyWord=%E6%96%87%E5%85%B7',
                );
              }),
            ),
            _link(
              label: '我要賣二手書',
              subtitle: 'AI上架精靈',
              onTap: () => _closeAnd(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiListingWizardScreen(),
                  ),
                );
              }),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _promoChip(
                    label: '搶絕版書',
                    color: const Color(0xFF5C4033),
                    onTap: () => _closeAnd(() {
                      _openUrl('https://www.taaze.tw/usedBookRare.html');
                    }),
                  ),
                  _promoChip(
                    label: '49元!',
                    color: primary,
                    onTap: () => _closeAnd(() {
                      _openUrl('https://www.taaze.tw/');
                    }),
                  ),
                  _promoChip(
                    label: '最高6%紅利',
                    color: primary,
                    onTap: () => _closeAnd(() {
                      _openUrl(
                        'https://www.taaze.tw/static_act/about/index.htm',
                      );
                    }),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),
            _sectionLabel('服務'),
            _link(
              label: '聯絡客服',
              badgeCount: supportUnread,
              onTap: () => _closeAnd(() {
                _openSupport();
              }),
            ),
            _link(
              label: 'AI 智能助手',
              onTap: () => _closeAnd(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                );
              }),
            ),
            _link(
              label: '實體書店',
              showNew: true,
              onTap: () => _closeAnd(() {
                _openBookstore();
              }),
            ),
            _link(
              label: '掃描條碼',
              onTap: () => _closeAnd(() {
                _openBarcodeScanner();
              }),
            ),

            const Divider(height: 24),
            _link(
              label: '學堂',
              onTap: () => _closeAnd(() {
                _openUrl(
                  'https://www.taaze.tw/static_act/lecture/2015/index.htm',
                );
              }),
            ),
            _link(
              label: '冊格子',
              onTap: () => _closeAnd(() {
                _openUrl('https://wecollect.fun/');
              }),
            ),
            _link(
              label: 'Podcast',
              onTap: () => _closeAnd(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PodcastHubScreen()),
                );
              }),
            ),
            _link(
              label: '會員中心',
              onTap: () => _closeAnd(() {
                MainScreen.openTab(4);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _expandableBooks({
    required Color primary,
    required List<String> categories,
    required ValueChanged<String> onCategoryTap,
    required VoidCallback onBrowseAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _booksExpanded = !_booksExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '書籍',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                Icon(
                  _booksExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_booksExpanded) ...[
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 16, 12),
              child: TextButton(
                onPressed: onBrowseAll,
                child: const Text('瀏覽全部分類'),
              ),
            )
          else
            ...categories.map(
              (name) => _nestedLink(
                label: name,
                onTap: () => onCategoryTap(name),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onBrowseAll,
                child: const Text('查看全部分類 ›'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _expandableEbooks({
    required Color primary,
    required VoidCallback onChineseEbook,
    required VoidCallback onChineseEmag,
    required VoidCallback onNewArrivals,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() => _ebooksExpanded = !_ebooksExpanded);
            if (_ebooksExpanded) {
              final provider = context.read<BookProvider>();
              provider.loadCategories(prodCatId: '14');
              provider.loadCategories(prodCatId: '25');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '電子書',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                Icon(
                  _ebooksExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_ebooksExpanded) ...[
          _nestedLink(label: '中文電子書', onTap: onChineseEbook),
          _nestedLink(label: '中文電子雜誌', onTap: onChineseEmag),
          _nestedLink(label: '電子書注目新品', onTap: onNewArrivals),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _nestedLink({
    required String label,
    required VoidCallback onTap,
  }) {
    // 與父層 20 對齊再縮一階；左側多留並關閉裁切，避免 CJK 首字（尤其「中」）缺筆變淡
    return Material(
      type: MaterialType.transparency,
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 10, 20, 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
        ),
      ),
    );
  }

  Widget _link({
    required String label,
    required VoidCallback onTap,
    bool emphasize = false,
    String? subtitle,
    int badgeCount = 0,
    bool showNew = false,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: emphasize ? primary : Colors.black87,
                      fontWeight:
                          emphasize ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (showNew)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _promoChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
