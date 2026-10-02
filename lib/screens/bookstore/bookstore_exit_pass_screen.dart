import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/bookstore.dart';
import '../../providers/auth_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_widgets.dart';

/// 付款完成與出門憑證：大 QR + 6 碼，店員核銷後自動變成「已核銷」
class BookstoreExitPassScreen extends StatefulWidget {
  final BookstoreCheckout checkout;
  final bool justPaid;

  const BookstoreExitPassScreen({super.key, required this.checkout, this.justPaid = false});

  @override
  State<BookstoreExitPassScreen> createState() => _BookstoreExitPassScreenState();
}

class _BookstoreExitPassScreenState extends State<BookstoreExitPassScreen>
    with SingleTickerProviderStateMixin {
  late BookstoreCheckout _checkout = widget.checkout;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  Timer? _ticker;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ticker?.cancel();
    _poller?.cancel();
    super.dispose();
  }

  bool get _settled => _checkout.exitVerifiedAt != null || _checkout.isRefunded;

  Future<void> _refresh() async {
    if (_settled) {
      _poller?.cancel();
      return;
    }
    final token = context.read<AuthProvider>().authToken;
    if (token == null) return;
    try {
      final fresh = await BookstoreService.getCheckout(token, _checkout.id);
      if (mounted) setState(() => _checkout = fresh);
    } on BookstoreException {
      // 下次再試
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _checkout;
    return Scaffold(
      appBar: AppBar(title: const Text('出門憑證')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.justPaid && c.exitVerifiedAt == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successColor, size: 56),
                    SizedBox(height: 8),
                    Text('付款完成', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            _passCard(c),
            const SizedBox(height: 20),
            _summary(c),
          ],
        ),
      ),
    );
  }

  Widget _passCard(BookstoreCheckout c) {
    if (c.isRefunded) {
      return _statusBox(Icons.undo, Colors.grey, '這筆已退貨', '退款依原付款方式辦理');
    }
    if (c.exitVerifiedAt != null) {
      return _statusBox(Icons.verified, AppTheme.successColor, '已核銷，謝謝光臨',
          '核銷時間 ${_hm(c.exitVerifiedAt!)}');
    }
    final pass = c.exitPass;
    if (pass == null || DateTime.now().isAfter(pass.expiresAt)) {
      return _statusBox(Icons.timer_off_outlined, AppTheme.warningColor, '出門憑證已過期',
          '請至櫃檯出示訂單編號 ${c.orderNo ?? c.id.substring(0, 8)}，由店員協助核對');
    }
    final remaining = pass.expiresAt.difference(DateTime.now());
    final code = pass.code.length == 6 ? '${pass.code.substring(0, 3)} ${pass.code.substring(3)}' : pass.code;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          const Text('請出示給店員掃描', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          QrImageView(
            data: pass.token,
            size: 240,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text('掃不到時請唸出這 6 碼', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _pulse,
                child: const Icon(Icons.circle, size: 10, color: AppTheme.successColor),
              ),
              const SizedBox(width: 6),
              Text(
                '即時畫面 ${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}',
                style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
              ),
              const SizedBox(width: 12),
              Text(
                '剩 ${formatCountdown(remaining)}',
                style: TextStyle(
                  color: remaining.inMinutes < 5 ? AppTheme.errorColor : AppTheme.textSecondaryColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBox(IconData icon, Color color, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 56),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _summary(BookstoreCheckout c) {
    final invoice = switch (c.invoiceStatus) {
      'issued' => c.invoiceNumber ?? '已開立',
      'failed' => '開立中，稍後可於載具查詢',
      _ => '—',
    };
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final l in c.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(l.productName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(' x${l.qty}  ${ntd(l.lineTotal)}'),
                  ],
                ),
              ),
            const Divider(height: 20),
            if (c.discount > 0) _kv('現金折扣', '-${ntd(c.discount)}'),
            _kv('合計', ntd(c.total)),
            if (c.isCash) _kv('付款方式', '現金（櫃台）'),
            if (c.orderNo != null) _kv('訂單編號', c.orderNo!),
            if (c.paidAt != null) _kv('付款時間', _hm(c.paidAt!, withDate: true)),
            _kv('電子發票', invoice),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(k, style: const TextStyle(color: AppTheme.textSecondaryColor))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  String _hm(DateTime t, {bool withDate = false}) {
    final hm = '${twoDigits(t.hour)}:${twoDigits(t.minute)}';
    return withDate ? '${t.year}/${twoDigits(t.month)}/${twoDigits(t.day)} $hm' : hm;
  }
}
