import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/bookstore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_exit_pass_screen.dart';
import 'bookstore_widgets.dart';

enum _PayMethod { cash, online }

/// 選付款方式 →
///   現金：出示櫃台付款碼，店員收款後自動切到出門憑證
///   線上：外部瀏覽器付款，回到 App 自動查詢結果（未開通時顯示「準備中」）
class BookstorePaymentScreen extends StatefulWidget {
  final BookstoreCheckout checkout;

  const BookstorePaymentScreen({super.key, required this.checkout});

  @override
  State<BookstorePaymentScreen> createState() => _BookstorePaymentScreenState();
}

class _BookstorePaymentScreenState extends State<BookstorePaymentScreen> with WidgetsBindingObserver {
  late BookstoreCheckout _checkout = widget.checkout;
  _PayMethod? _method;
  Timer? _ticker;
  Timer? _poller;
  bool _busy = false;
  bool _awaitingPayment = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (_checkout.isCash && _checkout.isPending) _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _poller?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingPayment) _refresh();
  }

  Duration get _remaining =>
      (_checkout.expiresAt ?? DateTime.now()).difference(DateTime.now());

  BookstoreStore? get _store {
    final s = context.read<BookstoreProvider>().store;
    return s?.id == _checkout.storeId ? s : null;
  }

  bool get _cashAvailable => _store?.cashEnabled ?? true;
  bool get _onlineAvailable => _store?.onlinePaymentEnabled ?? false;

  _PayMethod? get _selected {
    if (_method != null) return _method;
    if (_cashAvailable) return _PayMethod.cash;
    if (_onlineAvailable) return _PayMethod.online;
    return null;
  }

  Future<void> _refresh() async {
    final token = context.read<AuthProvider>().authToken;
    if (token == null) return;
    try {
      final fresh = await BookstoreService.getCheckout(token, _checkout.id);
      if (!mounted) return;
      setState(() => _checkout = fresh);
      if (fresh.isPaid) _onPaid(fresh);
      if (fresh.isClosed) _stopPolling();
    } on BookstoreException {
      // 輪詢失敗就等下一次
    }
  }

  void _onPaid(BookstoreCheckout paid) {
    if (_done) return;
    _done = true;
    _stopPolling();
    context.read<BookstoreProvider>().clearBag();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BookstoreExitPassScreen(checkout: paid, justPaid: true)),
    );
  }

  void _startPolling() {
    _awaitingPayment = true;
    _poller?.cancel();
    var ticks = 0;
    _poller = Timer.periodic(const Duration(seconds: 3), (_) {
      if (++ticks > 400) {
        _stopPolling();
        return;
      }
      _refresh();
    });
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _chooseCash() async {
    final token = await requireToken(context);
    if (!mounted || token == null) return;
    setState(() => _busy = true);
    try {
      final updated = await BookstoreService.chooseCash(token, _checkout.id);
      if (!mounted) return;
      setState(() => _checkout = updated);
      _startPolling();
    } on BookstoreException catch (e) {
      if (!mounted) return;
      showBookstoreError(context, e);
      if (e.code == 'expired' || e.code == 'not_pending') _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payOnline() async {
    final token = await requireToken(context);
    if (!mounted || token == null) return;
    setState(() => _busy = true);
    try {
      final url = await BookstoreService.startPayment(token, _checkout.id);
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) throw BookstoreException('無法開啟付款頁，請稍後再試');
      _startPolling();
    } on BookstoreException catch (e) {
      if (!mounted) return;
      showBookstoreError(context, e);
      if (e.code == 'expired' || e.code == 'not_pending') _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final token = await requireToken(context);
    if (!mounted || token == null) return;
    try {
      await BookstoreService.cancelCheckout(token, _checkout.id);
    } on BookstoreException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_pending') {
        await _refresh();
        return;
      }
      showBookstoreError(context, e);
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _confirmLeave() async {
    if (!_checkout.isPending || _remaining.isNegative) return true;
    final cash = _checkout.isCash;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('還沒付款喔'),
        content: Text(cash
            ? '書會繼續為你保留到倒數結束。之後回到購物籃再按一次結帳，就能找回這張付款碼。'
            : '離開後書會繼續為你保留到倒數結束。若已在付款頁完成付款，請按「我已付款」。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('先離開')),
          FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('留在這頁')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    final c = _checkout;
    final expired = c.isPending && _remaining.isNegative;
    final closed = c.isClosed || expired;
    final showCashCode = c.isCash && c.cashPayment != null && !closed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmLeave()) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(showCashCode ? '櫃台付款' : '確認付款')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _countdownCard(closed, cash: c.isCash),
            const SizedBox(height: 16),
            if (showCashCode) ...[
              _cashCodeCard(c),
              const SizedBox(height: 16),
            ],
            Text(c.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (final l in c.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(l.productName, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('x${l.qty}', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                    const SizedBox(width: 12),
                    SizedBox(width: 90, child: Text(ntd(l.lineTotal), textAlign: TextAlign.right)),
                  ],
                ),
              ),
            const Divider(height: 24),
            ..._summary(c),
            if (!c.isCash && !closed) ...[
              const SizedBox(height: 24),
              const Text('付款方式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _methodTile(
                method: _PayMethod.cash,
                icon: Icons.payments_outlined,
                title: '現金（到櫃台付款）',
                subtitle: _cashSubtitle(c),
                badge: (_store?.hasCashDiscount ?? false) ? _store!.cashDiscountLabel : null,
                enabled: _cashAvailable,
              ),
              _methodTile(
                method: _PayMethod.online,
                icon: Icons.credit_card,
                title: '信用卡／行動支付',
                subtitle: _onlineAvailable ? '在 App 內完成付款' : '即將開放，敬請期待',
                badge: _onlineAvailable ? null : '準備中',
                badgeMuted: true,
                enabled: _onlineAvailable,
              ),
            ],
            if (_awaitingPayment && !closed && !c.isCash) ...[
              const SizedBox(height: 24),
              const Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Expanded(child: Text('等待付款結果…完成付款後回到 App 會自動更新')),
                ],
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: closed
                ? FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: const Text('回購物籃重新結帳'),
                  )
                : showCashCode
                    ? Row(
                        children: [
                          TextButton(onPressed: _cancel, child: const Text('取消結帳')),
                          const Spacer(),
                          TextButton(onPressed: _refresh, child: const Text('店員已收款')),
                        ],
                      )
                    : _payButtons(c),
          ),
        ),
      ),
    );
  }

  String _cashSubtitle(BookstoreCheckout c) {
    final store = _store;
    if (!_cashAvailable) return '這家店目前不接受現金';
    if (store != null && store.hasCashDiscount) {
      return '現金價約 ${ntd(store.cashPriceOf(c.subtotal))}（零頭捨去）';
    }
    return '到櫃台出示付款碼，由店員收款';
  }

  List<Widget> _summary(BookstoreCheckout c) {
    const muted = TextStyle(color: AppTheme.textSecondaryColor);
    return [
      if (c.discount > 0) ...[
        Row(children: [const Expanded(child: Text('原價', style: muted)), Text(ntd(c.subtotal), style: muted)]),
        const SizedBox(height: 4),
        Row(children: [
          const Expanded(child: Text('現金折扣', style: TextStyle(color: AppTheme.successColor))),
          Text('-${ntd(c.discount)}', style: const TextStyle(color: AppTheme.successColor)),
        ]),
        const SizedBox(height: 8),
      ],
      Row(
        children: [
          Expanded(child: Text(c.isCash ? '應付現金' : '應付金額', style: const TextStyle(fontSize: 16))),
          Text(
            ntd(c.total),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ],
      ),
      const SizedBox(height: 4),
      const Text('含稅，金額由門市系統計算', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
    ];
  }

  Widget _payButtons(BookstoreCheckout c) {
    final method = _selected;
    final store = _store;
    final String label;
    final VoidCallback? action;
    switch (method) {
      case _PayMethod.cash:
        final preview = (store?.hasCashDiscount ?? false) ? ' ${ntd(store!.cashPriceOf(c.subtotal))}' : '';
        label = '到櫃台付現金$preview';
        action = _chooseCash;
      case _PayMethod.online:
        label = _awaitingPayment ? '重新開啟付款頁' : '前往付款 ${ntd(c.total)}';
        action = _payOnline;
      case null:
        label = '目前無可用的付款方式';
        action = null;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : action,
          icon: Icon(method == _PayMethod.online ? Icons.credit_card : Icons.payments_outlined),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppTheme.primaryColor,
          ),
        ),
        Row(
          children: [
            TextButton(onPressed: _cancel, child: const Text('取消結帳')),
            const Spacer(),
            if (_awaitingPayment) TextButton(onPressed: _refresh, child: const Text('我已付款')),
          ],
        ),
      ],
    );
  }

  Widget _methodTile({
    required _PayMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    bool badgeMuted = false,
    required bool enabled,
  }) {
    final selected = enabled && _selected == method;
    final fg = enabled ? AppTheme.textPrimaryColor : AppTheme.textHintColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? () => setState(() => _method = method) : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: enabled ? Colors.white : Colors.grey.shade100,
            border: Border.all(
              color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: enabled ? AppTheme.primaryColor : AppTheme.textHintColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: fg))),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeMuted ? Colors.grey.shade300 : AppTheme.successColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 12,
                                color: badgeMuted ? AppTheme.textSecondaryColor : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: enabled ? AppTheme.textSecondaryColor : AppTheme.textHintColor)),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppTheme.primaryColor : AppTheme.textHintColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cashCodeCard(BookstoreCheckout c) {
    final pay = c.cashPayment!;
    final code = pay.code.length == 6 ? '${pay.code.substring(0, 3)} ${pay.code.substring(3)}' : pay.code;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('請到櫃台出示此畫面', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          QrImageView(
            data: pay.token,
            size: 220,
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
          const Text('掃不到時請唸出這 6 碼付款碼', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 16),
          Text('應付現金 ${ntd(c.total)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('店員收款後，這裡會自動換成出門憑證'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownCard(bool closed, {required bool cash}) {
    final color = closed ? Colors.grey : (_remaining.inSeconds < 60 ? AppTheme.errorColor : AppTheme.infoColor);
    final text = closed
        ? '保留已結束，書已放回架上'
        : cash
            ? '已為你保留這些書，請在時間內到櫃台付款'
            : '已為你保留這些書，請在時間內完成付款';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(closed ? Icons.timer_off_outlined : Icons.timer_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color))),
          if (!closed)
            Text(
              formatCountdown(_remaining),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
        ],
      ),
    );
  }
}
