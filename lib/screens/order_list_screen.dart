import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/custom_app_bar.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _hasRequestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasRequestedInitialLoad) {
      _hasRequestedInitialLoad = true;
      _loadOrders();
    }
  }

  Future<void> _loadOrders({bool allowRetry = true}) async {
    final authProvider = context.read<AuthProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final token = authProvider.authToken;
    if (token == null) {
      if (!mounted) return;
      _showMessageSnackBar('尚未登入，請重新登入後再查看訂單');
      return;
    }

    final result = await ordersProvider.fetchOrders(token: token);

    if (!result.success) {
      if (result.statusCode == 401 && allowRetry) {
        final refreshed = await authProvider.refreshAuthToken();
        if (refreshed && authProvider.authToken != null) {
          if (!mounted) return;
          await _loadOrders(allowRetry: false);
        } else {
          if (!mounted) return;
          _showMessageSnackBar('登入已失效，請重新登入');
        }
      } else if (result.statusCode == 403) {
        if (!mounted) return;
        _showMessageSnackBar('帳號權限不足或會員不符，請重新登入');
      }
    }

  }

  Future<void> _refresh() async {
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '我的訂單',
        showBackButton: true,
      ),
      body: Consumer2<AuthProvider, OrdersProvider>(
        builder: (context, authProvider, ordersProvider, child) {
          if (!authProvider.isAuthenticated) {
            return _buildNotLoggedInState(context);
          }

          if (authProvider.authToken == null) {
            return _buildMessageState(
              context,
              icon: Icons.lock_outline,
              title: '找不到登入資訊',
              message: '請重新登入後再查看訂單',
              actionLabel: '返回',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          if (ordersProvider.isLoading && !ordersProvider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ordersProvider.error != null && !ordersProvider.hasData) {
            return _buildMessageState(
              context,
              icon: Icons.error_outline,
              title: '訂單載入失敗',
              message: ordersProvider.error!,
              actionLabel: '重新整理',
              onAction: _refresh,
            );
          }

          if (!ordersProvider.hasData) {
            return _buildMessageState(
              context,
              icon: Icons.receipt_long_outlined,
              title: '尚無訂單紀錄',
              message: '您的帳號目前沒有任何訂單，快去挑選喜愛的書籍吧！',
            );
          }

          final orders = ordersProvider.orders;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return _buildMessageState(
      context,
      icon: Icons.person_outline,
      title: '請先登入',
      message: '登入後即可查看您的訂單紀錄',
      actionLabel: '前往登入',
      onAction: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildMessageState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessageSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '訂單編號 ${order.orderId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: '下單日期',
              value: _formatDate(order.orderDate),
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: '金額',
              value: order.totalAmount != null
                  ? 'NT\$${order.totalAmount!.toStringAsFixed(0)}'
                  : '--',
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: '客戶編號',
              value: order.custId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = order.orderStatus.isEmpty ? '未知' : order.orderStatus;

    Color backgroundColor = colorScheme.surfaceContainerHighest;
    Color foregroundColor = colorScheme.onSurfaceVariant;

    final normalizedStatus = status.toUpperCase();
    if (normalizedStatus.contains('SHIP') ||
        normalizedStatus.contains('完成') ||
        normalizedStatus.contains('DELIVER')) {
      backgroundColor = Colors.green[50]!;
      foregroundColor = Colors.green[700]!;
    } else if (normalizedStatus.contains('CANCEL') ||
        normalizedStatus.contains('取消')) {
      backgroundColor = Colors.red[50]!;
      foregroundColor = Colors.red[700]!;
    } else if (normalizedStatus.contains('PENDING') ||
        normalizedStatus.contains('處理')) {
      backgroundColor = Colors.orange[50]!;
      foregroundColor = Colors.orange[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute';
  }

}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

