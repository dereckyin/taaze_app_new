import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bookstore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import '../../theme/app_theme.dart';
import 'bookstore_payment_screen.dart';
import 'bookstore_widgets.dart';
import 'door_qr_scanner_screen.dart';

enum _InvoiceKind { member, mobile, taxId, donation }

/// 購物車：調整數量、選發票、結帳（伺服器重新計價並鎖庫存）
class BookstoreBagScreen extends StatefulWidget {
  const BookstoreBagScreen({super.key});

  @override
  State<BookstoreBagScreen> createState() => _BookstoreBagScreenState();
}

class _BookstoreBagScreenState extends State<BookstoreBagScreen> {
  _InvoiceKind _invoiceKind = _InvoiceKind.member;
  final _invoiceInput = TextEditingController();
  bool _submitting = false;
  MemberWallet _wallet = const MemberWallet();
  int _redeemBonus = 0;
  int _redeemAcc = 0;

  static final _mobileCarrier = RegExp(r'^/[0-9A-Z.+\-]{7}$');
  static final _taxId = RegExp(r'^\d{8}$');
  static final _donation = RegExp(r'^\d{3,7}$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWallet());
  }

  bool get _memberSync =>
      context.read<BookstoreProvider>().store?.memberSyncEnabled == true;

  Future<void> _loadWallet() async {
    if (!mounted) return;
    if (!_memberSync) return;
    final token = context.read<AuthProvider>().authToken;
    if (token == null) return;
    try {
      final wallet = await BookstoreService.getWallet(token);
      if (!mounted) return;
      setState(() => _wallet = wallet);
    } on BookstoreException {
      // 折抵列隱藏即可，不擋結帳
    }
  }

  int get _maxRedeem {
    final bag = context.read<BookstoreProvider>();
    return bag.estimatedSubtotal;
  }

  int get _payablePreview {
    final raw = _maxRedeem - _redeemBonus - _redeemAcc;
    return raw < 0 ? 0 : raw;
  }

  @override
  void dispose() {
    _invoiceInput.dispose();
    super.dispose();
  }

  InvoiceChoice? _invoice() {
    final v = _invoiceInput.text.trim().toUpperCase();
    switch (_invoiceKind) {
      case _InvoiceKind.member:
        return const InvoiceChoice();
      case _InvoiceKind.mobile:
        return _mobileCarrier.hasMatch(v) ? InvoiceChoice(carrierType: 'mobile', carrierCode: v) : null;
      case _InvoiceKind.taxId:
        return _taxId.hasMatch(v) ? InvoiceChoice(taxId: v) : null;
      case _InvoiceKind.donation:
        return _donation.hasMatch(v) ? InvoiceChoice(donationCode: v) : null;
    }
  }

  Future<void> _checkout() async {
    final bag = context.read<BookstoreProvider>();
    final store = bag.store;
    if (store == null || bag.isEmpty) return;
    if (!store.isOpen) {
      showBookstoreError(context, BookstoreException('這家店目前暫停營業'));
      return;
    }
    InvoiceChoice? invoice;
    if (_memberSync) {
      invoice = _invoice();
      if (invoice == null) {
        showBookstoreError(context, BookstoreException('發票資料格式不正確，請再確認'));
        return;
      }
    }
    var presence = bag.presence;
    if (presence == null) {
      final scanned = await _askForDoorScan();
      if (!mounted || scanned == null) return;
      presence = scanned;
    }
    final token = await requireToken(context);
    if (!mounted || token == null) return;

    setState(() => _submitting = true);
    try {
      final checkout = await BookstoreService.createCheckout(
        token,
        storeId: store.id,
        presenceToken: presence.token,
        clientRequestId: bag.clientRequestId,
        lines: bag.lines,
        invoice: invoice,
        redeemBonus: _memberSync ? _redeemBonus : 0,
        redeemAcc: _memberSync ? _redeemAcc : 0,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookstorePaymentScreen(checkout: checkout)),
      );
    } on BookstoreException catch (e) {
      if (!mounted) return;
      if (e.needsPresence) {
        await _askForDoorScan();
      } else {
        showBookstoreError(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<PresenceSession?> _askForDoorScan() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('請先掃門口 QR Code'),
        content: const Text('為了確認你在店內，結帳前需要掃描店門口或櫃檯的 QR Code。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('稍後')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('去掃描')),
        ],
      ),
    );
    if (go != true || !mounted) return null;
    return Navigator.push<PresenceSession>(
      context,
      MaterialPageRoute(builder: (_) => const DoorQrScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bag = context.watch<BookstoreProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('購物車${bag.isEmpty ? '' : '（${bag.itemCount}）'}'),
        actions: [
          if (!bag.isEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清空購物車？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
                    ],
                  ),
                );
                if (ok == true) bag.clearBag();
              },
              child: const Text('清空'),
            ),
        ],
      ),
      body: bag.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('購物車是空的，掃書或逛書架加入吧'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (!bag.isInStore) _presenceBanner(),
                for (final item in bag.items) _BagRow(item: item),
                const SizedBox(height: 16),
                if (_memberSync) ...[
                  _invoiceSection(),
                  const SizedBox(height: 12),
                  _redeemSection(),
                  const SizedBox(height: 12),
                ],
                const Text(
                  '・金額與庫存以結帳當下為準，結帳後會為你保留 5 分鐘\n'
                  '・付款完成請出示「出門憑證」給店員核對\n'
                  '・退換貨請至店內櫃檯辦理',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12, height: 1.6),
                ),
              ],
            ),
      bottomNavigationBar: bag.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('預估金額', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          Text(
                            ntd(_payablePreview),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (bag.store?.hasCashDiscount ?? false)
                            Text(
                              '現金結帳 ${bag.store!.cashDiscountLabel}・約 ${ntd(bag.store!.cashPriceOf(bag.estimatedSubtotal))}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.successColor),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _submitting ? null : _checkout,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 50),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('結帳'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _presenceBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2, color: AppTheme.warningColor),
          const SizedBox(width: 8),
          const Expanded(child: Text('結帳前需要掃門口 QR Code', style: TextStyle(fontSize: 13))),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoorQrScannerScreen()),
            ),
            child: const Text('掃描'),
          ),
        ],
      ),
    );
  }

  Widget _invoiceSection() {
    final (hint, keyboard) = switch (_invoiceKind) {
      _InvoiceKind.mobile => ('手機條碼，例如 /ABC1234', TextInputType.text),
      _InvoiceKind.taxId => ('8 碼統一編號', TextInputType.number),
      _InvoiceKind.donation => ('捐贈碼（3～7 碼）', TextInputType.number),
      _InvoiceKind.member => ('', TextInputType.text),
    };
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('電子發票', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (kind, label) in const [
                  (_InvoiceKind.member, '會員載具'),
                  (_InvoiceKind.mobile, '手機條碼'),
                  (_InvoiceKind.taxId, '公司統編'),
                  (_InvoiceKind.donation, '捐贈'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _invoiceKind == kind,
                    onSelected: (_) => setState(() {
                      _invoiceKind = kind;
                      _invoiceInput.clear();
                    }),
                  ),
              ],
            ),
            if (_invoiceKind != _InvoiceKind.member) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _invoiceInput,
                keyboardType: keyboard,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: hint, isDense: true),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _redeemSection() {
    if (!_wallet.enabled || (_wallet.bonus <= 0 && _wallet.acc <= 0)) {
      return const SizedBox.shrink();
    }
    final maxBonus = (_maxRedeem - _redeemAcc).clamp(0, _wallet.bonus).toInt();
    final maxAcc = (_maxRedeem - _redeemBonus).clamp(0, _wallet.acc).toInt();
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('會員折抵', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_wallet.bonus > 0)
              _redeemRow('紅利', _wallet.bonus, _redeemBonus, maxBonus, (v) => setState(() => _redeemBonus = v)),
            if (_wallet.acc > 0)
              _redeemRow('回饋金', _wallet.acc, _redeemAcc, maxAcc, (v) => setState(() => _redeemAcc = v)),
          ],
        ),
      ),
    );
  }

  Widget _redeemRow(String label, int available, int value, int maxUse, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text('$label（可用 $available）', style: const TextStyle(fontSize: 13))),
        TextButton(onPressed: value == 0 ? null : () => onChanged(0), child: const Text('不用')),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: maxUse == 0 || value == maxUse ? null : () => onChanged(maxUse),
          child: const Text('全折'),
        ),
      ],
    );
  }
}

class _BagRow extends StatelessWidget {
  final BagItem item;

  const _BagRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final bag = context.read<BookstoreProvider>();
    final p = item.product;
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => bag.remove(p.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            BookstoreCover(url: p.imageUrl, width: 56, height: 78),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(ntd(p.price), style: const TextStyle(color: AppTheme.primaryColor)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(item.qty <= 1 ? Icons.delete_outline : Icons.remove_circle_outline),
              onPressed: () => bag.setQty(p.id, item.qty - 1),
            ),
            Text('${item.qty}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: item.qty >= p.maxQty ? null : () => bag.setQty(p.id, item.qty + 1),
            ),
          ],
        ),
      ),
    );
  }
}
