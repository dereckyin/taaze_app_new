import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;
import '../providers/ai_chat_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'ai_listing_wizard_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _suggestionsCollapsed = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt(String prompt) async {
    final aiProvider = context.read<AiChatProvider>();
    final authToken = await _requireAuthToken();
    if (authToken == null) return;

    await aiProvider.sendMessage(
      prompt,
      token: authToken,
    );
    _scrollToBottom();
  }

  Future<String?> _requireAuthToken() async {
    final authProvider = context.read<AuthProvider>();
    final existingToken = authProvider.authToken;
    if (existingToken != null && existingToken.isNotEmpty) {
      return existingToken;
    }

    if (!mounted) return null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('請先登入會員才能使用 AI 對話功能。')),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    final refreshedToken = context.read<AuthProvider>().authToken;
    if (refreshedToken != null && refreshedToken.isNotEmpty) {
      return refreshedToken;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI 智能助手'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiListingWizardScreen(),
                ),
              );
            },
            tooltip: 'AI上架精靈',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              context.read<AiChatProvider>().clearChat();
            },
            tooltip: '清空對話',
          ),
        ],
      ),
      body: Consumer<AiChatProvider>(
        builder: (context, aiProvider, child) {
          return Column(
            children: [
              // 對話列表
              Expanded(
                child: aiProvider.messages.isEmpty
                    ? _buildWelcomeMessage()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: aiProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = aiProvider.messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),

              // 載入指示器
              if (aiProvider.isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI 正在思考中...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),

              // 建議提示區域
              _buildSuggestionPanel(aiProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI 智能助手',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '我可以幫你解答關於書籍的問題\n推薦適合的書籍\n或者回答其他問題\n\n提問後會自動提供下一步建議按鈕，只要點選即可接續對話。',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // AI上架精靈快速入口
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AiListingWizardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('AI上架精靈'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '試試問我：「推薦一些程式設計的書籍」',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null) ...[
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 200,
                        maxHeight: 200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(message.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.error,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (message.content.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.grey[600], size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionPanel(AiChatProvider aiProvider) {
    final prompts = aiProvider.suggestedPrompts;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxPanelHeight = math.min(220.0, constraints.maxHeight * 0.32);

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: prompts.isEmpty
                ? Text(
                    aiProvider.isLoading
                        ? 'AI 正在準備下一步建議，請稍候…'
                        : '尚未收到 AI 建議，請稍候或從書籍詳情發起問題。',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '下一步建議',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: _suggestionsCollapsed ? '展開' : '收合',
                            onPressed: () {
                              setState(() {
                                _suggestionsCollapsed = !_suggestionsCollapsed;
                              });
                            },
                            icon: Icon(
                              _suggestionsCollapsed
                                  ? Icons.expand_more
                                  : Icons.expand_less,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: _suggestionsCollapsed
                            // 收合狀態：一行高度，水平滑動，避免佔用太多畫面
                            ? SizedBox(
                                height: 44,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: prompts
                                        .take(6)
                                        .map(
                                          (prompt) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: FilledButton.tonal(
                                              onPressed: aiProvider.isLoading
                                                  ? null
                                                  : () => _sendPrompt(prompt),
                                              style: FilledButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              child: Text(
                                                prompt,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                ),
                              )
                            // 展開狀態：有最大高度、可垂直捲動
                            : ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: maxPanelHeight,
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: prompts
                                        .map(
                                          (prompt) => FilledButton.tonal(
                                            onPressed: aiProvider.isLoading
                                                ? null
                                                : () => _sendPrompt(prompt),
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              alignment: Alignment.centerLeft,
                                            ),
                                            child: Text(
                                              prompt,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });

  ChatMessage copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? imagePath,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
