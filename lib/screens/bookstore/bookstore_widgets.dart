import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bookstore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image_widget.dart';
import '../login_screen.dart';

String ntd(int amount) {
  final s = amount.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${amount < 0 ? '-' : ''}NT\$ $s';
}

String twoDigits(int n) => n.toString().padLeft(2, '0');

String formatCountdown(Duration d) {
  if (d.isNegative) return '00:00';
  final m = d.inMinutes;
  return '${twoDigits(m)}:${twoDigits(d.inSeconds % 60)}';
}

/// 取得 token；未登入就導去登入頁並回傳 null
Future<String?> requireToken(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final token = auth.authToken;
  if (auth.isAuthenticated && token != null) return token;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('請先登入讀冊會員')),
  );
  await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  if (!context.mounted) return null;
  return context.read<AuthProvider>().authToken;
}

void showBookstoreError(BuildContext context, Object error) {
  final message = error is BookstoreException ? error.message : '發生錯誤，請稍後再試';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class StockChip extends StatelessWidget {
  final StockStatus status;
  final bool dense;

  const StockChip({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StockStatus.inStock => ('店內有書', AppTheme.successColor),
      StockStatus.lastOne => ('最後一本', AppTheme.warningColor),
      StockStatus.outOfStock => ('已售完', Colors.grey),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: dense ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class BookstoreCover extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;

  const BookstoreCover({super.key, this.url, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    if (url == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: radius),
        child: const Center(child: Icon(Icons.menu_book, color: Colors.grey)),
      );
    }
    return BookCoverImage(imageUrl: url!, width: width, height: height, borderRadius: radius);
  }
}

class PriceText extends StatelessWidget {
  final int price;
  final int? listPrice;
  final double fontSize;

  const PriceText({super.key, required this.price, this.listPrice, this.fontSize = 15});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: [
        Text(
          ntd(price),
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        if (listPrice != null && listPrice! > price)
          Text(
            ntd(listPrice!),
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: fontSize - 3,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

/// 店內頁共用的底部列：掃書 + 店內袋
class BagBottomBar extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onOpenBag;

  const BagBottomBar({super.key, required this.onScan, required this.onOpenBag});

  @override
  Widget build(BuildContext context) {
    final bag = context.watch<BookstoreProvider>();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('掃書加入'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onOpenBag,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Badge(
                      isLabelVisible: bag.itemCount > 0,
                      label: Text('${bag.itemCount}'),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        bag.isEmpty ? '店內袋' : ntd(bag.estimatedSubtotal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重試')),
          ],
        ),
      ),
    );
  }
}
