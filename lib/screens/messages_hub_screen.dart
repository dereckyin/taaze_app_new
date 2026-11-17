import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/support_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'notifications_screen.dart';
import 'support_conversations_screen.dart';

/// Bottom-nav hub: 客服 + 通知 under one「訊息」entry.
class MessagesHubScreen extends StatefulWidget {
  /// 0 = 客服, 1 = 通知
  final int initialTab;

  const MessagesHubScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<MessagesHubScreen> createState() => MessagesHubScreenState();
}

class MessagesHubScreenState extends State<MessagesHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTab.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initial,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshForTab());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void selectTab(int index) {
    final i = index.clamp(0, 1);
    if (_tabController.index != i) {
      _tabController.animateTo(i);
    } else {
      _refreshForTab();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    _refreshForTab();
  }

  Future<void> _refreshForTab() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final token = auth.authToken;
    if (_tabController.index == 0) {
      if (token != null && token.isNotEmpty) {
        await context.read<SupportProvider>().refreshConversations(token);
      }
    } else {
      await context.read<NotificationProvider>().refresh(authToken: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: CustomAppBar(
        title: '訊息',
        showBackButton: false,
        actions: [
          if (_tabController.index == 1)
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                if (notificationProvider.unreadCount <= 0) {
                  return const SizedBox.shrink();
                }
                return TextButton(
                  onPressed: () {
                    notificationProvider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已標記所有通知為已讀')),
                    );
                  },
                  child: const Text(
                    '全部已讀',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: primary,
              tabs: [
                Consumer<SupportProvider>(
                  builder: (context, support, _) {
                    return Tab(
                      child: _TabLabel(
                        text: '客服',
                        badge: support.unreadCount,
                      ),
                    );
                  },
                ),
                Consumer<NotificationProvider>(
                  builder: (context, notif, _) {
                    return Tab(
                      child: _TabLabel(
                        text: '通知',
                        badge: notif.unreadCount,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SupportConversationsScreen(embedded: true),
                NotificationsScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  final int badge;

  const _TabLabel({required this.text, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (badge > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge > 99 ? '99+' : '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
