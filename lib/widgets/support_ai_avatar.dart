import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SupportAiMood { idle, typing, happy, think, sorry }

SupportAiMood moodFromAiMessage({
  required String body,
  String? senderId,
}) {
  final sid = (senderId ?? '').toLowerCase();
  final text = body;
  if (sid == 'cs-ack' || sid == 'cs-handoff' || text.contains('已通知')) {
    return SupportAiMood.happy;
  }
  if (sid == 'cs-followup' ||
      text.contains('抱歉') ||
      text.contains('稍候') ||
      text.contains('較忙') ||
      text.contains('優先處理')) {
    return SupportAiMood.sorry;
  }
  if (text.contains('請提供') ||
      text.contains('確認') ||
      text.contains('訂單編號') ||
      text.contains('分類')) {
    return SupportAiMood.think;
  }
  if (text.contains('感謝') ||
      text.contains('歡迎') ||
      text.contains('已收到') ||
      text.contains('幫助')) {
    return SupportAiMood.happy;
  }
  return SupportAiMood.idle;
}

class SupportAiAvatar extends StatefulWidget {
  final SupportAiMood mood;
  final double size;

  const SupportAiAvatar({
    super.key,
    this.mood = SupportAiMood.idle,
    this.size = 40,
  });

  @override
  State<SupportAiAvatar> createState() => _SupportAiAvatarState();
}

class _SupportAiAvatarState extends State<SupportAiAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.mood == SupportAiMood.typing ? 700 : 2600,
      ),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SupportAiAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _controller.duration = Duration(
        milliseconds: widget.mood == SupportAiMood.typing ? 700 : 2600,
      );
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amp = widget.mood == SupportAiMood.typing ? 3.0 : 1.6;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = math.sin(_controller.value * math.pi);
        return Transform.translate(
          offset: Offset(0, -amp * t),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _AiFacePainter(mood: widget.mood),
      ),
    );
  }
}

class _AiFacePainter extends CustomPainter {
  final SupportAiMood mood;

  _AiFacePainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final face = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE8F0), Color(0xFFFFF6FB)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, face);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFF5A3C0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final eyePaint = Paint()..color = const Color(0xFF5B3A45);
    final eyeY = center.dy - size.height * 0.08;
    final eyeR = size.width * 0.07;
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.18, eyeY),
      eyeR,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.18, eyeY),
      eyeR,
      eyePaint,
    );

    final mouthPaint = Paint()
      ..color = mood == SupportAiMood.happy
          ? const Color(0xFFE91E63)
          : const Color(0xFF5B3A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final mouthY = center.dy + size.height * 0.18;
    switch (mood) {
      case SupportAiMood.think:
      case SupportAiMood.typing:
        canvas.drawLine(
          Offset(center.dx - size.width * 0.1, mouthY),
          Offset(center.dx + size.width * 0.1, mouthY),
          mouthPaint..style = PaintingStyle.stroke,
        );
        break;
      case SupportAiMood.sorry:
        final path = Path()
          ..moveTo(center.dx - size.width * 0.14, mouthY + 2)
          ..quadraticBezierTo(
            center.dx,
            mouthY - size.height * 0.08,
            center.dx + size.width * 0.14,
            mouthY + 2,
          );
        canvas.drawPath(path, mouthPaint);
        break;
      case SupportAiMood.happy:
        final path = Path()
          ..moveTo(center.dx - size.width * 0.16, mouthY - 2)
          ..quadraticBezierTo(
            center.dx,
            mouthY + size.height * 0.12,
            center.dx + size.width * 0.16,
            mouthY - 2,
          );
        canvas.drawPath(path, mouthPaint);
        break;
      case SupportAiMood.idle:
        final path = Path()
          ..moveTo(center.dx - size.width * 0.14, mouthY - 1)
          ..quadraticBezierTo(
            center.dx,
            mouthY + size.height * 0.08,
            center.dx + size.width * 0.14,
            mouthY - 1,
          );
        canvas.drawPath(path, mouthPaint);
        break;
    }

    if (mood == SupportAiMood.typing) {
      final dot = Paint()..color = const Color(0xFFE91E63);
      final baseY = center.dy + size.height * 0.42;
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(center.dx + (i - 1) * size.width * 0.12, baseY),
          1.8,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AiFacePainter oldDelegate) =>
      oldDelegate.mood != mood;
}
