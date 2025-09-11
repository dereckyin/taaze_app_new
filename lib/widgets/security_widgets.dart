import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// 簡單驗證碼輸入框
class CaptchaInputWidget extends StatefulWidget {
  final String captchaCode;
  final Function(String) onCaptchaChanged;
  final Function() onRefreshCaptcha;

  const CaptchaInputWidget({
    super.key,
    required this.captchaCode,
    required this.onCaptchaChanged,
    required this.onRefreshCaptcha,
  });

  @override
  State<CaptchaInputWidget> createState() => _CaptchaInputWidgetState();
}

class _CaptchaInputWidgetState extends State<CaptchaInputWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '驗證碼',
              hintText: '請輸入驗證碼',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: widget.onCaptchaChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入驗證碼';
              }
              if (value.length != 4) {
                return '驗證碼必須為4位數字';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // 驗證碼顯示區域
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
              widget.captchaCode,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
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
    );
  }
}

/// 安全警告提示框
class SecurityWarningWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const SecurityWarningWidget({
    super.key,
    required this.message,
    this.icon = Icons.warning,
    this.color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// 登入嘗試次數顯示
class LoginAttemptsWidget extends StatelessWidget {
  final int remainingAttempts;
  final int maxAttempts;
  final DateTime? nextResetTime;

  const LoginAttemptsWidget({
    super.key,
    required this.remainingAttempts,
    required this.maxAttempts,
    this.nextResetTime,
  });

  String _formatResetTime(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);

    if (difference.isNegative) {
      return '已可重置';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}小時${minutes}分鐘後重置';
    } else {
      return '${minutes}分鐘後重置';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (remainingAttempts >= maxAttempts) {
      return const SizedBox.shrink();
    }

    final usedAttempts = maxAttempts - remainingAttempts;
    final progress = usedAttempts / maxAttempts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '登入嘗試次數: $usedAttempts/$maxAttempts',
          style: TextStyle(
            color: progress > 0.6 ? Colors.red : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (nextResetTime != null) ...[
          const SizedBox(height: 2),
          Text(
            _formatResetTime(nextResetTime!),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 0.6 ? Colors.red : Colors.orange,
          ),
        ),
      ],
    );
  }
}

/// 帳戶鎖定倒數計時器
class LockoutTimerWidget extends StatefulWidget {
  final Duration remainingTime;
  final VoidCallback? onUnlock;

  const LockoutTimerWidget({
    super.key,
    required this.remainingTime,
    this.onUnlock,
  });

  @override
  State<LockoutTimerWidget> createState() => _LockoutTimerWidgetState();
}

class _LockoutTimerWidgetState extends State<LockoutTimerWidget> {
  late Duration _remainingTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.remainingTime;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
      } else {
        timer.cancel();
        widget.onUnlock?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SecurityWarningWidget(
      message: '帳戶已鎖定，剩餘時間: ${_formatDuration(_remainingTime)}',
      icon: Icons.lock,
      color: Colors.red,
    );
  }
}

/// 密碼強度指示器
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // 長度檢查
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // 包含小寫字母
    if (password.contains(RegExp(r'[a-z]'))) score++;

    // 包含大寫字母
    if (password.contains(RegExp(r'[A-Z]'))) score++;

    // 包含數字
    if (password.contains(RegExp(r'[0-9]'))) score++;

    // 包含特殊字符
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;
    double progress;

    switch (strength) {
      case PasswordStrength.weak:
        color = Colors.red;
        text = '密碼強度: 弱';
        progress = 0.33;
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        text = '密碼強度: 中等';
        progress = 0.66;
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        text = '密碼強度: 強';
        progress = 1.0;
        break;
      case PasswordStrength.none:
        return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

enum PasswordStrength { none, weak, medium, strong }
