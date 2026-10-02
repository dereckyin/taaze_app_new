import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/bookstore_provider.dart';
import '../../services/bookstore_service.dart';
import 'bookstore_widgets.dart';

const _doorQrPrefix = 'TAAZEBK1:';

/// 掃門口 QR Code 取得「在店內」憑證，成功後 pop 回傳 PresenceSession
class DoorQrScannerScreen extends StatefulWidget {
  const DoorQrScannerScreen({super.key});

  @override
  State<DoorQrScannerScreen> createState() => _DoorQrScannerScreenState();
}

class _DoorQrScannerScreenState extends State<DoorQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _busy = false;
  String? _hint;
  String? _lastRaw;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    final now = DateTime.now();
    if (raw == _lastRaw && now.difference(_lastAt) < const Duration(seconds: 3)) return;
    _lastRaw = raw;
    _lastAt = now;
    if (!raw.startsWith(_doorQrPrefix)) {
      setState(() => _hint = '這不是書店門口的 QR Code');
      return;
    }
    setState(() {
      _busy = true;
      _hint = null;
    });
    final token = await requireToken(context);
    if (!mounted || token == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      final session = await BookstoreService.resolveDoorQr(token, raw);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.read<BookstoreProvider>().setPresence(session);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('歡迎光臨 ${session.store.name}')),
      );
      Navigator.pop(context, session);
    } on BookstoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _hint = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('掃描門口 QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Column(
              children: [
                if (_busy) const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  _hint ?? '對準店門口或櫃檯的「讀冊 App 自助結帳」QR Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _hint != null ? Colors.amberAccent : Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
