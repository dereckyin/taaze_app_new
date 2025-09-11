import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/captcha_response.dart';

/// API驗證碼輸入組件
class ApiCaptchaWidget extends StatefulWidget {
  final CaptchaResponse? captcha;
  final Function(String) onCaptchaChanged;
  final Function() onRefreshCaptcha;
  final bool isLoading;

  const ApiCaptchaWidget({
    super.key,
    required this.captcha,
    required this.onCaptchaChanged,
    required this.onRefreshCaptcha,
    this.isLoading = false,
  });

  @override
  State<ApiCaptchaWidget> createState() => _ApiCaptchaWidgetState();
}

class _ApiCaptchaWidgetState extends State<ApiCaptchaWidget> {
  final TextEditingController _controller = TextEditingController();
  Uint8List? _captchaImageBytes;

  @override
  void initState() {
    super.initState();
    _updateCaptchaImage();
  }

  @override
  void didUpdateWidget(ApiCaptchaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.captcha != widget.captcha) {
      _updateCaptchaImage();
    }
  }

  void _updateCaptchaImage() {
    if (widget.captcha?.captchaImage != null) {
      try {
        // 如果是Base64編碼的圖片
        if (widget.captcha!.captchaImage.startsWith('data:image')) {
          final base64String = widget.captcha!.captchaImage.split(',')[1];
          _captchaImageBytes = base64Decode(base64String);
        } else {
          // 假設是純Base64字符串
          _captchaImageBytes = base64Decode(widget.captcha!.captchaImage);
        }
      } catch (e) {
        _captchaImageBytes = null;
      }
    } else {
      _captchaImageBytes = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '驗證碼',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '請輸入驗證碼',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(6)],
                onChanged: widget.onCaptchaChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入驗證碼';
                  }
                  if (value.length < 4) {
                    return '驗證碼長度不足';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            // 驗證碼圖片顯示區域
            Container(
              width: 120,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _captchaImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _captchaImageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackCaptcha();
                        },
                      ),
                    )
                  : _buildFallbackCaptcha(),
            ),
            const SizedBox(width: 8),
            // 刷新按鈕
            IconButton(
              onPressed: widget.isLoading ? null : widget.onRefreshCaptcha,
              icon: const Icon(Icons.refresh),
              tooltip: '刷新驗證碼',
            ),
          ],
        ),
        if (widget.captcha?.message != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.captcha!.message!,
            style: TextStyle(color: Colors.orange[700], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackCaptcha() {
    // 如果圖片加載失敗，顯示文字驗證碼或佔位符
    if (widget.captcha?.captchaText != null) {
      return Center(
        child: Text(
          widget.captcha!.captchaText!,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            letterSpacing: 2,
          ),
        ),
      );
    } else {
      return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
  }
}

/// 簡單的文字驗證碼組件（用於測試）
class SimpleTextCaptchaWidget extends StatefulWidget {
  final String captchaText;
  final Function(String) onCaptchaChanged;
  final Function() onRefreshCaptcha;

  const SimpleTextCaptchaWidget({
    super.key,
    required this.captchaText,
    required this.onCaptchaChanged,
    required this.onRefreshCaptcha,
  });

  @override
  State<SimpleTextCaptchaWidget> createState() =>
      _SimpleTextCaptchaWidgetState();
}

class _SimpleTextCaptchaWidgetState extends State<SimpleTextCaptchaWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '驗證碼',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '請輸入驗證碼',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(6)],
                onChanged: widget.onCaptchaChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入驗證碼';
                  }
                  if (value.length < 4) {
                    return '驗證碼長度不足';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            // 文字驗證碼顯示
            Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: Center(
                child: Text(
                  widget.captchaText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 刷新按鈕
            IconButton(
              onPressed: widget.onRefreshCaptcha,
              icon: const Icon(Icons.refresh),
              tooltip: '刷新驗證碼',
            ),
          ],
        ),
      ],
    );
  }
}
