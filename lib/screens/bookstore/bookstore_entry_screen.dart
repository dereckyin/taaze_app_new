import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bookstore.dart';
import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_home_screen.dart';
import 'bookstore_orders_screen.dart';
import 'bookstore_widgets.dart';
import 'door_qr_scanner_screen.dart';

/// 實體書店專區入口：選店／掃門口 QR
class BookstoreEntryScreen extends StatefulWidget {
  const BookstoreEntryScreen({super.key});

  @override
  State<BookstoreEntryScreen> createState() => _BookstoreEntryScreenState();
}

class _BookstoreEntryScreenState extends State<BookstoreEntryScreen> {
  List<BookstoreStore>? _stores;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = await requireToken(context);
    if (!mounted) return;
    if (token == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stores = await BookstoreService.listStores(token);
      if (!mounted) return;
      setState(() => _stores = stores);
    } on BookstoreException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanDoor() async {
    final session = await Navigator.push<PresenceSession>(
      context,
      MaterialPageRoute(builder: (_) => const DoorQrScannerScreen()),
    );
    if (session == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BookstoreHomeScreen()));
  }

  void _browse(BookstoreStore store) {
    context.read<BookstoreProvider>().enterStore(store);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BookstoreHomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('實體書店'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookstoreOrdersScreen()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('購買紀錄'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HowItWorks(onScan: _scanDoor),
            const SizedBox(height: 24),
            Text('門市', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '不在店裡也可以先逛逛店內有哪些書',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_loading && _stores == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ErrorRetry(message: _error!, onRetry: _load)
            else if ((_stores ?? []).isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('目前沒有開放的門市')),
              )
            else
              for (final store in _stores!) _StoreCard(store: store, onTap: () => _browse(store)),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  final VoidCallback onScan;

  const _HowItWorks({required this.onScan});

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(body, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '店內自助結帳，不用排隊',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          step(Icons.qr_code_2, '1. 掃門口 QR Code', '確認你在店裡，才能結帳'),
          step(Icons.qr_code_scanner, '2. 掃書背條碼', '或在 App 裡逛書架，加入店內袋'),
          step(Icons.verified_outlined, '3. App 付款，出示出門憑證', '店員核對後就能帶書回家'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('我在店裡，掃門口 QR Code'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final BookstoreStore store;
  final VoidCallback onTap;

  const _StoreCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0x1AE91E63),
          child: Icon(Icons.storefront, color: AppTheme.primaryColor),
        ),
        title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(store.address ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              store.isOpen ? '營業中' : '暫停營業',
              style: TextStyle(
                color: store.isOpen ? AppTheme.successColor : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
