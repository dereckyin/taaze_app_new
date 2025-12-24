import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/order.dart';
import '../models/order_item_summary.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'book_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _hasRequestedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasRequestedInitialLoad) return;
      _hasRequestedInitialLoad = true;
      _loadOrders();
    });
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

  Future<void> _openOrderItems(Order order) async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.authToken;
    if (token == null || token.isEmpty) {
      _showMessageSnackBar('登入已失效，請重新登入後再查看訂單明細');
      return;
    }

    final selectedItem = await showModalBottomSheet<OrderItemSummary>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrderItemsBottomSheet(order: order, token: token),
    );

    if (selectedItem != null && mounted) {
      _openBookDetail(selectedItem);
    }
  }

  void _openBookDetail(OrderItemSummary item) {
    final book = _bookFromOrderItem(item);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );
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
                return _OrderCard(
                  order: order,
                  onTap: () => _openOrderItems(order),
                );
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
  const _OrderCard({required this.order, this.onTap});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                value: _formatOrderDate(order.orderDate),
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: '金額',
                value: order.totalAmount != null
                    ? 'NT\$${order.totalAmount!.toStringAsFixed(0)}'
                    : '--',
              ),
              // const SizedBox(height: 4),
              // _InfoRow(
              //   label: '客戶編號',
              //   value: order.custId,
              // ),
            ],
          ),
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

class _OrderItemsBottomSheet extends StatefulWidget {
  const _OrderItemsBottomSheet({
    required this.order,
    required this.token,
  });

  final Order order;
  final String token;

  @override
  State<_OrderItemsBottomSheet> createState() => _OrderItemsBottomSheetState();
}

class _OrderItemsBottomSheetState extends State<_OrderItemsBottomSheet> {
  bool _hasRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasRequested) return;
      _hasRequested = true;
      _fetchItems();
    });
  }

  Future<void> _fetchItems({bool forceRefresh = false}) async {
    final provider = context.read<OrdersProvider>();
    await provider.fetchOrderItems(
      orderId: widget.order.orderId,
      token: widget.token,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '訂單編號 ${widget.order.orderId}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '下單日期 ${_formatOrderDate(widget.order.orderDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (widget.order.totalAmount != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '總金額 NT\$${widget.order.totalAmount!.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Consumer<OrdersProvider>(
                    builder: (context, provider, _) {
                      final isLoading =
                          provider.isOrderItemsLoading(widget.order.orderId);
                      final error =
                          provider.orderItemsError(widget.order.orderId);
                      final items =
                          provider.itemsForOrder(widget.order.orderId) ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '訂單明細',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              if (items.isNotEmpty)
                                Text(
                                  '${items.length} 件商品',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => _fetchItems(forceRefresh: true),
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                label: const Text('重新整理'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                if (isLoading && items.isEmpty) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (error != null && items.isEmpty) {
                                  return _OrderItemsMessage(
                                    icon: Icons.error_outline,
                                    message: error,
                                    actionLabel: '再次嘗試',
                                    onAction: () =>
                                        _fetchItems(forceRefresh: true),
                                  );
                                }

                                if (items.isEmpty) {
                                  return const _OrderItemsMessage(
                                    icon: Icons.inbox_outlined,
                                    message: '查無訂單明細，請稍後再試。',
                                  );
                                }

                                return ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return _OrderItemTile(
                                      item: item,
                                      onTap: () =>
                                          Navigator.of(context).pop(item),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderItemsMessage extends StatelessWidget {
  const _OrderItemsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[500]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item, this.onTap});

  final OrderItemSummary item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[];
    if (item.prodId != null && item.prodId!.isNotEmpty) {
      subtitle.add('商品編號 ${item.prodId}');
    }
    if (item.author != null && item.author!.isNotEmpty) {
      subtitle.add(item.author!);
    }

    final quantity = item.quantity ?? 1;
    final unitPrice = item.unitPrice;
    final total = unitPrice != null ? unitPrice * quantity : null;
    final imageUrl = _resolveOrderItemImageUrl(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderItemThumbnail(
                imageUrl: imageUrl,
                quantity: quantity,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titleMain ?? '未命名商品',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle.join(' · '),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (unitPrice != null)
                    Text(
                      'NT\$${unitPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  if (total != null && quantity > 1)
                    Text(
                      '小計 NT\$${total.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItemThumbnail extends StatelessWidget {
  const _OrderItemThumbnail({
    required this.imageUrl,
    required this.quantity,
  });

  final String? imageUrl;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    final boxColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 70,
          height: 95,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: boxColor,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _ThumbnailFallback(icon: Icons.broken_image),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : const _ThumbnailFallback(icon: Icons.menu_book_outlined),
          ),
        ),
        Positioned(
          top: -6,
          left: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'x$quantity',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        icon,
        color: Colors.grey[400],
        size: 28,
      ),
    );
  }
}

String _formatOrderDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year/$month/$day $hour:$minute';
}

String? _resolveOrderItemImageUrl(OrderItemSummary item) {
  if (item.coverImage != null && item.coverImage!.isNotEmpty) {
    return item.coverImage;
  }
  final sourceId = item.orgProdId?.isNotEmpty == true
      ? item.orgProdId
      : item.prodId;
  if (sourceId == null || sourceId.isEmpty) {
    return null;
  }
  return 'https://media.taaze.tw/showThumbnail.html?sc=$sourceId&height=400&width=310';
}

Book _bookFromOrderItem(OrderItemSummary item) {
  final id = _firstNonEmptyValue(
    [item.prodId, item.orgProdId],
    'order-item-${item.hashCode}',
  );
  final imageUrl = _resolveOrderItemImageUrl(item) ?? '';
  final publishDate =
      _parseDate(item.raw['publish_date'] ?? item.raw['publishDate']);

  return Book(
    id: id,
    orgProdId: item.orgProdId ?? id,
    title: item.titleMain ?? '訂單商品',
    author: _firstNonEmptyValue(
      [item.author, item.raw['author_name'], item.raw['author']],
      '未知作者',
    ),
    description: _firstNonEmptyValue(
      [
        item.raw['description'],
        item.raw['prod_desc'],
        item.raw['prod_pf'],
      ],
      '此商品來自您的訂單，目前尚未提供詳細介紹。',
    ),
    price: item.unitPrice ?? _parseDouble(item.raw['price']) ?? 0,
    imageUrl: imageUrl,
    category: _firstNonEmptyValue(
      [item.raw['category'], item.raw['prod_cat_nm']],
      '訂單商品',
    ),
    rating: _parseDouble(item.raw['rating']) ?? 0,
    reviewCount: _parseInt(item.raw['review_count']),
    isAvailable: _parseBool(item.raw['is_available']),
    publishDate: publishDate,
    isbn: _firstNonEmptyValue(
      [item.raw['isbn'], item.raw['isbn13']],
      '',
    ),
    pages: _parseInt(item.raw['pages']),
    publisher: _firstNonEmptyValue(
      [item.raw['publisher'], item.raw['pub_nm_main']],
      '未知出版社',
    ),
  );
}

String _firstNonEmptyValue(List<dynamic> values, String fallback) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return fallback;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _parseBool(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  final normalized = value.toString().toLowerCase();
  return !(normalized == 'false' ||
      normalized == '0' ||
      normalized == 'n' ||
      normalized == 'no');
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  final parsed = DateTime.tryParse(value.toString());
  return parsed ?? DateTime.now();
}

