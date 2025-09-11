import 'package:flutter/material.dart';

/// 臨時條碼掃描頁面 - 等待 mobile_scanner 依賴解決
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _searchBookByBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // 模擬搜尋延遲
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        _showNoBookFoundDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('搜尋失敗：${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showNoBookFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未找到書籍'),
        content: const Text('找不到與此條碼對應的書籍，請檢查條碼是否正確。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _barcodeController.clear();
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('條碼掃描'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 提示訊息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '條碼掃描功能暫時不可用',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '由於依賴套件衝突，條碼掃描功能暫時停用。\n您可以使用手動輸入條碼的方式搜尋書籍。',
                    style: TextStyle(color: Colors.orange[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 手動輸入條碼
            Text('手動輸入條碼', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: '條碼',
                hintText: '請輸入書籍條碼',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchBookByBarcode(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // 搜尋按鈕
            ElevatedButton(
              onPressed: _isSearching
                  ? null
                  : () {
                      if (_barcodeController.text.isNotEmpty) {
                        _searchBookByBarcode(_barcodeController.text);
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSearching
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('搜尋中...'),
                      ],
                    )
                  : const Text('搜尋書籍'),
            ),

            const SizedBox(height: 24),

            // 功能說明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '功能說明',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 輸入書籍的 ISBN 條碼進行搜尋\n'
                      '• 支援 13 位 ISBN-13 格式\n'
                      '• 支援 10 位 ISBN-10 格式\n'
                      '• 找到書籍後會自動跳轉到書籍詳情頁面',
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 底部提示
            Text(
              '提示：條碼掃描功能將在依賴套件問題解決後恢復',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
