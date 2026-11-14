import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/support.dart';
import '../providers/auth_provider.dart';
import '../providers/support_provider.dart';
import 'login_screen.dart';
import 'support_chat_screen.dart';

class SupportConversationsScreen extends StatefulWidget {
  const SupportConversationsScreen({super.key});

  @override
  State<SupportConversationsScreen> createState() =>
      _SupportConversationsScreenState();
}

class _SupportConversationsScreenState
    extends State<SupportConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<String?> _token() async {
    final auth = context.read<AuthProvider>();
    var token = await auth.tokenForApi();
    if (token != null && token.isNotEmpty) return token;
    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('請先登入會員才能使用客服功能。')),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return null;
    return context.read<AuthProvider>().authToken;
  }

  Future<void> _load() async {
    final token = await _token();
    if (token == null || !mounted) return;
    await context.read<SupportProvider>().refreshConversations(token);
  }

  Future<void> _startChat() async {
    final token = await _token();
    if (token == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupportChatScreen(conversationId: null),
      ),
    );
    await _load();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return '待回覆';
      case 'closed':
        return '已關閉';
      default:
        return '處理中';
    }
  }

  String _titleFor(SupportConversation conversation) {
    final preview = conversation.lastMessagePreview?.trim();
    if (preview != null && preview.isNotEmpty) {
      return preview.length > 28 ? '${preview.substring(0, 28)}…' : preview;
    }
    final subject = conversation.subject.trim();
    if (subject.isNotEmpty) return subject;
    return '客服對話 #${conversation.convId}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聯絡客服'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startChat,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('開始對話'),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, _) {
          if (provider.loadingList && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('重試')),
                  ],
                ),
              ),
            );
          }
          if (provider.conversations.isEmpty) {
            return Center(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.grey[350],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final conv = provider.conversations[index];
                return _ConversationTile(
                  title: _titleFor(conv),
                  conversation: conv,
                  statusLabel: _statusLabel(conv.status),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SupportChatScreen(conversationId: conv.convId),
                      ),
                    );
                    await _load();
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

class _ConversationTile extends StatelessWidget {
  final String title;
  final SupportConversation conversation;
  final String statusLabel;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.title,
    required this.conversation,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(
            Icons.chat_bubble_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight:
                      conversation.hasUnread ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (conversation.hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCustomer}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (conversation.category == 'human')
              Text(
                '人工優先',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (conversation.category != null &&
                conversation.category!.isNotEmpty)
              Text(
                '分類：${conversation.category}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            Text(
              statusLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
