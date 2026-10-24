import 'dart:convert';
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '驗證碼',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: '請輸入圖中文字',
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade500, letterSpacing: 0),
                  filled: true,
                  fillColor: Colors.white,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.security),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            const SizedBox(width: 10),
            // 驗證碼圖片顯示區域（放大以便辨識）
            Container(
              width: 148,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 1.2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _captchaImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.memory(
                        _captchaImageBytes!,
                        fit: BoxFit.contain,
                        width: 148,
                        height: 56,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackCaptcha();
                        },
                      ),
                    )
                  : _buildFallbackCaptcha(),
            ),
            IconButton(
              onPressed: widget.isLoading ? null : widget.onRefreshCaptcha,
              icon: const Icon(Icons.refresh, size: 26),
              tooltip: '刷新驗證碼',
              padding: const EdgeInsets.only(left: 4, top: 8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
            letterSpacing: 4,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: '請輸入圖中文字',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
                  ),
                  prefixIcon: const Icon(Icons.security),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            const SizedBox(width: 10),
            // 文字驗證碼顯示
            Container(
              width: 148,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 1.2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  widget.captchaText,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onRefreshCaptcha,
              icon: const Icon(Icons.refresh, size: 26),
              tooltip: '刷新驗證碼',
              padding: const EdgeInsets.only(left: 4, top: 8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ],
    );
  }
}
