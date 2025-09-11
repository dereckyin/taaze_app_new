import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/banner_provider.dart';
import '../utils/debug_helper.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _addLog('Debug Screen 已啟動');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 50) {
        _logs.removeAt(0); // 保持最多50條日誌
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug 控制台'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 狀態信息卡片
          Expanded(flex: 2, child: _buildStatusCards()),
          // 操作按鈕
          Expanded(flex: 1, child: _buildActionButtons()),
          // 日誌顯示
          Expanded(flex: 3, child: _buildLogsView()),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        children: [
          _buildStatusCard(
            '書籍狀態',
            Consumer<BookProvider>(
              builder: (context, bookProvider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('書籍數量: ${bookProvider.books.length}'),
                    Text('載入中: ${bookProvider.isLoading ? "是" : "否"}'),
                    if (bookProvider.error != null)
                      Text(
                        '錯誤: ${bookProvider.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 10),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildStatusCard(
            '橫幅狀態',
            Consumer<BannerProvider>(
              builder: (context, bannerProvider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('橫幅數量: ${bannerProvider.banners.length}'),
                    Text('載入中: ${bannerProvider.isLoading ? "是" : "否"}'),
                    if (bannerProvider.error != null)
                      Text(
                        '錯誤: ${bannerProvider.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 10),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildStatusCard(
            '用戶狀態',
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('已登入: ${authProvider.isAuthenticated ? "是" : "否"}'),
                    if (authProvider.user != null)
                      Text(
                        '用戶: ${authProvider.user!.name}',
                        style: const TextStyle(fontSize: 10),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildStatusCard(
            '購物車',
            Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('商品數量: ${cartProvider.items.length}'),
                    Text(
                      '總金額: \$${cartProvider.totalPrice.toStringAsFixed(2)}',
                    ),
                  ],
                );
              },
            ),
          ),
          _buildStatusCard(
            '通知',
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('通知數量: ${notificationProvider.notifications.length}'),
                    Text('未讀: ${notificationProvider.unreadCount}'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Debug 操作', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 2,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<BookProvider>().refreshBooks();
                    _addLog('重新載入書籍資料');
                  },
                  child: const Text(
                    '重新載入\n書籍',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<BannerProvider>().refreshBanners();
                    _addLog('重新載入橫幅資料');
                  },
                  child: const Text(
                    '重新載入\n橫幅',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<BookProvider>().switchToOfflineMode();
                    _addLog('切換到離線模式');
                  },
                  child: const Text(
                    '離線模式',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<BookProvider>().clearError();
                    _addLog('清除錯誤狀態');
                  },
                  child: const Text(
                    '清除錯誤',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<CartProvider>().clearCart();
                    _addLog('清空購物車');
                  },
                  child: const Text(
                    '清空購物車',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    DebugHelper.logMemoryUsage();
                    _addLog('檢查內存使用');
                  },
                  child: const Text(
                    '內存檢查',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addLog('測試日誌輸出');
                    DebugHelper.log('這是一條測試日誌', tag: 'TEST');
                  },
                  child: const Text(
                    '測試日誌',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsView() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Debug 日誌',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  child: Text(
                    _logs[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
