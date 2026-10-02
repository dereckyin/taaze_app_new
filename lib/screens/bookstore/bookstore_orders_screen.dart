import 'package:flutter/material.dart';

import '../../models/bookstore.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_exit_pass_screen.dart';
import 'bookstore_widgets.dart';

/// 門市購買紀錄（已付款／已退貨）
class BookstoreOrdersScreen extends StatefulWidget {
  const BookstoreOrdersScreen({super.key});

  @override
  State<BookstoreOrdersScreen> createState() => _BookstoreOrdersScreenState();
}

class _BookstoreOrdersScreenState extends State<BookstoreOrdersScreen> {
  List<BookstoreCheckout>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = await requireToken(context);
    if (!mounted || token == null) return;
    setState(() => _error = null);
    try {
      final items = await BookstoreService.listCheckouts(token);
      if (mounted) setState(() => _items = items);
    } on BookstoreException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = ErrorRetry(message: _error!, onRetry: _load);
    } else if (_items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_items!.isEmpty) {
      body = const Center(child: Text('還沒有門市購買紀錄'));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final c = _items![i];
            final date = c.paidAt ?? c.createdAt;
            final color = c.isRefunded
                ? Colors.grey
                : c.exitVerifiedAt != null
                    ? AppTheme.successColor
                    : AppTheme.primaryColor;
            return Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookstoreExitPassScreen(checkout: c)),
                  );
                  _load();
                },
                title: Text(c.storeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${date == null ? '' : '${date.year}/${twoDigits(date.month)}/${twoDigits(date.day)}  '}'
                  '${c.itemCount} 本',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(ntd(c.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(c.statusLabel, style: TextStyle(color: color, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('門市購買紀錄')), body: body);
  }
}
