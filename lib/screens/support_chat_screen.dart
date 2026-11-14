import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/support.dart';
import '../providers/auth_provider.dart';
import '../providers/support_provider.dart';
import '../services/support_api_service.dart';
import '../widgets/support_ai_avatar.dart';
import 'login_screen.dart';

class SupportChatScreen extends StatefulWidget {
  /// Null = draft mode; conversation is created on first send.
  final int? conversationId;
  final String? subject;

  const SupportChatScreen({
    super.key,
    required this.conversationId,
    this.subject,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const int _visibleTail = 24;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  String? _authToken;
  SupportProvider? _supportProvider;
  int? _convId;
  bool _showAllHistory = false;
  bool _bootstrapped = false;
  bool _closed = false;
  bool _awaitingAi = false;
  DateTime? _awaitingAiSince;

  @override
  void initState() {
    super.initState();
    _convId = widget.conversationId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supportProvider = context.read<SupportProvider>();
  }

  @override
  void dispose() {
    _supportProvider?.stopPolling();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<String?> _requireToken() async {
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

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final token = await _requireToken();
    if (token == null || !mounted) return;
    _authToken = token;
    final convId = _convId;
    if (convId == null) {
      setState(() {});
      return;
    }
    final provider = context.read<SupportProvider>();
    await provider.loadMessages(authToken: token, convId: convId);
    if (!mounted) return;
    _syncClosed(provider);
    provider.startPolling(authToken: token, convId: convId);
    _scrollToBottom();
  }

  void _syncClosed(SupportProvider provider) {
    final convId = _convId;
    if (convId == null) return;
    for (final c in provider.conversations) {
      if (c.convId == convId) {
        _closed = c.isClosed;
        break;
      }
    }
  }

  bool _expectsImmediateAi(List<SupportMessage> messages) {
    // Only show typing while waiting for the first auto reply.
    // After AI/agent has joined, backend sends a short「已通知」text instead —
    // fake "..." would look like a human typing when nobody is online.
    return !messages.any(
      (m) => m.senderType == 'ai' || m.senderType == 'agent',
    );
  }

  void _markAwaitingAi(List<SupportMessage> messages) {
    if (!_expectsImmediateAi(messages)) {
      _awaitingAi = false;
      _awaitingAiSince = null;
      return;
    }
    _awaitingAi = true;
    _awaitingAiSince = DateTime.now();
  }

  void _syncAwaitingAi(List<SupportMessage> messages) {
    if (!_awaitingAi) return;
    if (messages.isNotEmpty &&
        (messages.last.senderType == 'ai' ||
            messages.last.senderType == 'agent')) {
      _awaitingAi = false;
      _awaitingAiSince = null;
      return;
    }
    if (!_expectsImmediateAi(messages)) {
      _awaitingAi = false;
      _awaitingAiSince = null;
      return;
    }
    final since = _awaitingAiSince;
    if (since != null && DateTime.now().difference(since).inSeconds > 20) {
      _awaitingAi = false;
      _awaitingAiSince = null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<int?> _ensureConversation(String token, {String? seedBody}) async {
    if (_convId != null) return _convId;
    final provider = context.read<SupportProvider>();
    final conv = await provider.createConversation(
      authToken: token,
      body: seedBody?.trim().isNotEmpty == true ? seedBody!.trim() : '您好',
    );
    if (conv == null) return null;
    setState(() => _convId = conv.convId);
    await provider.loadMessages(authToken: token, convId: conv.convId);
    if (!mounted) return conv.convId;
    provider.startPolling(authToken: token, convId: conv.convId);
    return conv.convId;
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final token = _authToken ?? await _requireToken();
    if (token == null || !mounted) return;
    final provider = context.read<SupportProvider>();

    if (_convId == null) {
      _textController.clear();
      final convId = await _ensureConversation(token, seedBody: text);
      if (!mounted) return;
      if (convId == null) {
        _textController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? '建立對話失敗')),
        );
        return;
      }
      setState(() {
        _closed = false;
        _markAwaitingAi(provider.messagesFor(convId));
      });
      _scrollToBottom();
      return;
    }

    _textController.clear();
    final ok = await provider.sendMessage(
      authToken: token,
      convId: _convId!,
      body: text,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? '送出失敗')),
      );
      return;
    }
    setState(() {
      _closed = false;
      _markAwaitingAi(provider.messagesFor(_convId!));
    });
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final token = _authToken ?? await _requireToken();
    if (token == null || !mounted) return;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final provider = context.read<SupportProvider>();
    var convId = _convId;
    if (convId == null) {
      convId = await _ensureConversation(token, seedBody: '請查看附圖');
      if (convId == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? '建立對話失敗')),
        );
        return;
      }
      // Seed message already created; still upload image as next message.
    }

    final name = file.name.toLowerCase();
    var contentType = 'image/jpeg';
    if (name.endsWith('.png')) {
      contentType = 'image/png';
    } else if (name.endsWith('.webp')) {
      contentType = 'image/webp';
    }

    final ok = await provider.sendImage(
      authToken: token,
      convId: convId,
      filePath: file.path,
      filename: file.name,
      contentType: contentType,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? '圖片上傳失敗')),
      );
      return;
    }
    setState(() {
      _closed = false;
      _markAwaitingAi(provider.messagesFor(convId!));
    });
    _scrollToBottom();
  }

  Future<void> _closeConversation() async {
    final convId = _convId;
    if (convId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('結束對話'),
        content: const Text('確定要結束此客服對話嗎？之後仍可再開啟新對話。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('結束'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = _authToken ?? await _requireToken();
    if (token == null || !mounted) return;
    final provider = context.read<SupportProvider>();
    final ok = await provider.closeConversation(
      authToken: token,
      convId: convId,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? '無法結束對話')),
      );
      return;
    }
    setState(() => _closed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('對話已結束')),
    );
  }

  String _title(SupportProvider provider) {
    if (widget.subject != null && widget.subject!.isNotEmpty) {
      return widget.subject!;
    }
    final convId = _convId;
    if (convId == null) return '新對話';
    for (final c in provider.conversations) {
      if (c.convId == convId) {
        final preview = c.lastMessagePreview?.trim();
        if (preview != null && preview.isNotEmpty) {
          return preview.length > 18 ? '${preview.substring(0, 18)}…' : preview;
        }
        if (c.subject.isNotEmpty) return c.subject;
      }
    }
    return '客服對話';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Consumer<SupportProvider>(
          builder: (context, provider, _) => Text(_title(provider)),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_convId != null && !_closed)
            IconButton(
              tooltip: '結束對話',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _closeConversation,
            ),
        ],
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, _) {
          _syncClosed(provider);
          final convId = _convId;
          final allMessages = convId == null
              ? const <SupportMessage>[]
              : provider.messagesFor(convId);
          _syncAwaitingAi(allMessages);
          final showTyping = _awaitingAi &&
              (allMessages.isEmpty || allMessages.last.senderType != 'ai');
          final hiddenCount =
              (!_showAllHistory && allMessages.length > _visibleTail)
                  ? allMessages.length - _visibleTail
                  : 0;
          final visible = hiddenCount > 0
              ? allMessages.sublist(allMessages.length - _visibleTail)
              : allMessages;
          final extraTop = hiddenCount > 0 ? 1 : 0;
          final extraTyping = showTyping ? 1 : 0;

          return Column(
            children: [
              if (_closed)
                Material(
                  color: Colors.grey.shade200,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('此對話已結束，傳送訊息將重新開啟'),
                  ),
                ),
              Expanded(
                child: convId == null
                    ? const SizedBox.shrink()
                    : provider.loadingMessages && allMessages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : allMessages.isEmpty && !showTyping
                            ? const SizedBox.shrink()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: visible.length +
                                    extraTop +
                                    extraTyping,
                                itemBuilder: (context, index) {
                                  if (hiddenCount > 0 && index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Center(
                                        child: TextButton(
                                          onPressed: () => setState(
                                            () => _showAllHistory = true,
                                          ),
                                          child: Text('顯示更早的 $hiddenCount 則訊息'),
                                        ),
                                      ),
                                    );
                                  }
                                  final msgStart = extraTop;
                                  final typingIndex =
                                      msgStart + visible.length;
                                  if (showTyping && index == typingIndex) {
                                    return const _AiTypingRow();
                                  }
                                  final msgIndex = index - msgStart;
                                  return _MessageBubble(
                                    message: visible[msgIndex],
                                    authToken: _authToken,
                                  );
                                },
                              ),
              ),
              if (provider.sending)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '傳送中...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              _buildInput(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInput(SupportProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              tooltip: '上傳圖片',
              onPressed: provider.sending
                  ? null
                  : () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library_outlined),
                                title: const Text('相簿'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickAndSendImage(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_camera_outlined),
                                title: const Text('拍照'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pickAndSendImage(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
              icon: Icon(
                Icons.image_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: '輸入訊息...',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: provider.sending ? null : (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: provider.sending ? null : _send,
              icon: const Icon(Icons.send, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final SupportMessage message;
  final String? authToken;

  const _MessageBubble({required this.message, this.authToken});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  late Future<Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.attachmentUrl != widget.message.attachmentUrl ||
        oldWidget.authToken != widget.authToken) {
      _imageFuture = _loadImage();
    }
  }

  Future<Uint8List?> _loadImage() async {
    final url = widget.message.attachmentUrl;
    final token = widget.authToken;
    if (url == null || url.isEmpty || token == null || token.isEmpty) {
      return null;
    }
    return SupportApiService.fetchMediaBytes(
      authToken: token,
      attachmentUrl: url,
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMine = message.isMine;
    final isAi = message.senderType == 'ai';
    final align =
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = isMine
        ? Theme.of(context).colorScheme.primary
        : isAi
            ? const Color(0xFFFFF0F5)
            : Colors.grey[200];
    final fg = isMine ? Colors.white : Colors.black87;
    final label = switch (message.senderType) {
      'customer' => '我',
      'agent' => '客服',
      'ai' => 'AI 客服',
      _ => '系統',
    };
    final showText = message.body.trim().isNotEmpty &&
        !(message.hasImage && message.body.trim() == '[圖片]');
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * (isAi ? 0.68 : 0.78),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showText)
            Text(
              message.body,
              style: TextStyle(color: fg, height: 1.35),
            ),
          if (message.hasImage) ...[
            if (showText) const SizedBox(height: 8),
            FutureBuilder(
              future: _imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    width: 120,
                    height: 80,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final bytes = snapshot.data;
                if (bytes == null) {
                  return Text(
                    '（圖片）',
                    style: TextStyle(color: fg.withValues(alpha: 0.8)),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    bytes,
                    width: 220,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );

    if (isAi) {
      final mood = moodFromAiMessage(
        body: message.body,
        senderId: message.senderId,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SupportAiAvatar(mood: mood, size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  bubble,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          bubble,
        ],
      ),
    );
  }
}

class _AiTypingRow extends StatelessWidget {
  const _AiTypingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SupportAiAvatar(mood: SupportAiMood.typing, size: 40),
          SizedBox(width: 8),
          _TypingDots(),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_controller.value + i * 0.2) % 1.0;
              final t = (phase < 0.5 ? phase : 1 - phase) * 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.35 + 0.65 * t,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E63),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
