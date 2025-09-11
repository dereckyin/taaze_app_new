import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';  // 暫時註解
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import 'book_detail_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  String? _lastScannedCode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code != _lastScannedCode) {
        _lastScannedCode = code;
        _isScanning = false;

        // 顯示掃描結果
        _showScanResult(code);
      }
    }
  }

  void _showScanResult(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('掃描成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text('條碼: $code'),
            const SizedBox(height: 16),
            const Text('正在搜尋相關書籍...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchBookByBarcode(code);
            },
            child: const Text('搜尋書籍'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('繼續掃描'),
          ),
        ],
      ),
    );
  }

  void _searchBookByBarcode(String barcode) async {
    try {
      // 顯示載入指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('搜尋中...'),
            ],
          ),
        ),
      );

      // 模擬搜尋書籍（實際應用中應該調用API）
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop(); // 關閉載入對話框

      // 檢查是否有匹配的書籍
      final bookProvider = context.read<BookProvider>();
      final books = bookProvider.books;

      // 模擬根據條碼找到書籍（實際應用中應該根據條碼查詢）
      if (books.isNotEmpty) {
        final foundBook = books.first; // 這裡應該根據條碼查詢

        // 顯示找到的書籍
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('找到書籍'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('書名: ${foundBook.title}'),
                const SizedBox(height: 8),
                Text('作者: ${foundBook.author}'),
                const SizedBox(height: 8),
                Text('價格: \$${foundBook.price}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // 返回掃描頁面
                  _resetScanner();
                },
                child: const Text('繼續掃描'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // 返回掃描頁面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(book: foundBook),
                    ),
                  );
                },
                child: const Text('查看詳情'),
              ),
            ],
          ),
        );
      } else {
        // 沒有找到書籍
        _showNoBookFound();
      }
    } catch (e) {
      Navigator.of(context).pop(); // 關閉載入對話框
      _showError('搜尋失敗: $e');
    }
  }

  void _showNoBookFound() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未找到書籍'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text('抱歉，我們沒有找到與此條碼相關的書籍。'),
            SizedBox(height: 8),
            Text('請確認條碼是否正確，或嘗試手動搜尋。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('繼續掃描'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 返回上一頁
            },
            child: const Text('手動搜尋'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('條碼掃描'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off, color: Colors.grey),
            onPressed: () {
              // TODO: 實現手電筒切換功能
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('手電筒功能開發中')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_rear),
            onPressed: () {
              // TODO: 實現前後鏡頭切換功能
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('鏡頭切換功能開發中')));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 相機預覽
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // 掃描框
          _buildScannerOverlay(),

          // 底部提示
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '將條碼對準掃描框',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: '相簿',
                        onTap: () {
                          // TODO: 實現從相簿選擇圖片掃描
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('相簿掃描功能開發中')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.keyboard,
                        label: '手動輸入',
                        onTap: () {
                          _showManualInputDialog();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5)),
      child: Stack(
        children: [
          // 半透明遮罩
          Positioned.fill(child: CustomPaint(painter: ScannerOverlayPainter())),

          // 掃描框
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // 四個角落的指示器
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手動輸入條碼'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '請輸入條碼',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop();
                _searchBookByBarcode(code);
              }
            },
            child: const Text('搜尋'),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanAreaSize = 250.0;

    // 計算掃描區域
    final scanArea = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // 創建整個屏幕的矩形
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 創建掃描區域的圓角矩形
    final scanAreaRounded = RRect.fromRectAndRadius(
      scanArea,
      const Radius.circular(12),
    );

    // 創建路徑：整個屏幕減去掃描區域
    final path = Path()
      ..addRect(screenRect)
      ..addRRect(scanAreaRounded)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
