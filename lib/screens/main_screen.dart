import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/notification_provider.dart';
import '../providers/support_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'messages_hub_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';
import '../providers/ai_chat_provider.dart';

class MainScreen extends StatefulWidget {
  static final GlobalKey<MainScreenState> navKey = GlobalKey<MainScreenState>();

  /// Bottom-nav index of the messages hub.
  static const int messagesTabIndex = 3;

  const MainScreen({super.key});

  /// Switch to bottom「訊息」and select hub tab (0=客服, 1=通知).
  static void openMessages({int tab = 0}) {
    navKey.currentState?.openMessages(tab: tab);
  }

  /// Switch bottom navigation tab (0 home … 4 profile).
  static void openTab(int index) {
    navKey.currentState?.openTab(index);
  }

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<MessagesHubScreenState> _messagesHubKey =
      GlobalKey<MessagesHubScreenState>();

  late final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(query: ''),
    const CartScreen(),
    MessagesHubScreen(key: _messagesHubKey),
    const ProfileScreen(),
  ];

  void openMessages({int tab = 0}) {
    setState(() => _currentIndex = MainScreen.messagesTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagesHubKey.currentState?.selectTab(tab);
    });
  }

  void openTab(int index) {
    final i = index.clamp(0, _screens.length - 1);
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      // Hide AI FAB on 訊息 tab so it does not cover 開始對話.
      floatingActionButton: _currentIndex == MainScreen.messagesTabIndex
          ? null
          : FloatingActionButton(
              onPressed: () {
                context.read<AiChatProvider>().setProductContext(null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiChatScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              tooltip: '與書對話',
              heroTag: 'ai_chat',
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
      bottomNavigationBar: Consumer2<NotificationProvider, SupportProvider>(
        builder: (context, notificationProvider, supportProvider, child) {
          final unread =
              notificationProvider.unreadCount + supportProvider.unreadCount;
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey[600],
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '首頁',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: '搜尋',
              ),
              const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.cartShopping),
                activeIcon: Icon(FontAwesomeIcons.cartShopping),
                label: '購物車',
              ),
              BottomNavigationBarItem(
                icon: _MessagesNavIcon(
                  outlined: true,
                  unread: unread,
                ),
                activeIcon: _MessagesNavIcon(
                  outlined: false,
                  unread: unread,
                ),
                label: '訊息',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessagesNavIcon extends StatelessWidget {
  final bool outlined;
  final int unread;

  const _MessagesNavIcon({
    required this.outlined,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          outlined ? Icons.chat_bubble_outline : Icons.chat_bubble,
        ),
        if (unread > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
