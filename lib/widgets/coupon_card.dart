import 'package:flutter/material.dart';
import '../models/coupon.dart';

class CouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback? onClaim;
  final bool isClaiming;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onClaim,
    this.isClaiming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          // 主要卡片
          _buildMainCard(),
          // 左側圓形切口
          _buildLeftCutout(),
          // 右側圓形切口
          _buildRightCutout(),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseColor(coupon.backgroundColor ?? '#E91E63'),
            _parseColor(coupon.backgroundColor ?? '#E91E63').withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 背景圖案
            _buildBackgroundPattern(),
            // 中國風邊框裝飾
            _buildChineseStyleBorder(),
            // 內容
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CouponPatternPainter(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildChineseStyleBorder() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ChineseStyleBorderPainter(
          coupon: coupon,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 左側折扣信息
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 折扣金額
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    coupon.discountDisplayText,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _parseColor(coupon.textColor ?? '#FFFFFF'),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 標題
                Text(
                  coupon.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _parseColor(coupon.textColor ?? '#FFFFFF'),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // 描述
                Text(
                  coupon.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: _parseColor(
                      coupon.textColor ?? '#FFFFFF',
                    ).withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 右側按鈕和到期信息
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 到期信息
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${coupon.remainingDays}天',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _parseColor(coupon.textColor ?? '#FFFFFF'),
                    ),
                  ),
                ),
                // 領取按鈕
                _buildClaimButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton() {
    return GestureDetector(
      onTap: isClaiming ? null : onClaim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isClaiming
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            : Text(
                '領取',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _parseColor(coupon.backgroundColor ?? '#FF6B6B'),
                ),
              ),
      ),
    );
  }

  Widget _buildLeftCutout() {
    return Positioned(
      left: -8,
      top: 0,
      bottom: 0,
      child: Container(
        width: 16,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildRightCutout() {
    return Positioned(
      right: -8,
      top: 0,
      bottom: 0,
      child: Container(
        width: 16,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

// 背景圖案繪製器
class CouponPatternPainter extends CustomPainter {
  final Color color;

  CouponPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 繪製圓點圖案
    const double spacing = 20.0;
    const double radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 中國風邊框繪製器
class ChineseStyleBorderPainter extends CustomPainter {
  final Coupon coupon;
  final Color color;

  ChineseStyleBorderPainter({required this.coupon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 繪製單一層邊框
    _drawChineseBorder(canvas, size, paint, 8.0);

    // 如果是VIP或高額折價券，添加特殊裝飾
    if (_isHighValueCoupon()) {
      _drawSpecialDecorations(canvas, size, paint);
    }
  }

  bool _isHighValueCoupon() {
    if (coupon.discountType == 'percentage') {
      return coupon.discountAmount >= 20; // 8折以上
    } else {
      return coupon.discountAmount >= 100; // 100元以上
    }
  }

  void _drawChineseBorder(
    Canvas canvas,
    Size size,
    Paint paint,
    double padding,
  ) {
    // 繪製中國風邊框 - 類似印章的設計
    final borderPath = Path();

    // 外邊框
    borderPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          padding,
          padding,
          size.width - 2 * padding,
          size.height - 2 * padding,
        ),
        const Radius.circular(8),
      ),
    );

    canvas.drawPath(borderPath, paint);

    // 內邊框裝飾 - 四個角的裝飾
    _drawCornerDecorations(canvas, size, paint, padding);
  }

  void _drawCornerDecorations(
    Canvas canvas,
    Size size,
    Paint paint,
    double padding,
  ) {
    // 四個角的裝飾線條
    double cornerSize = 12.0;

    // 左上角
    canvas.drawLine(
      Offset(padding, padding + cornerSize),
      Offset(padding + cornerSize, padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding + cornerSize, padding + cornerSize),
      paint,
    );

    // 右上角
    canvas.drawLine(
      Offset(size.width - padding - cornerSize, padding),
      Offset(size.width - padding, padding + cornerSize),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding - cornerSize, padding + cornerSize),
      paint,
    );

    // 左下角
    canvas.drawLine(
      Offset(padding, size.height - padding - cornerSize),
      Offset(padding + cornerSize, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding + cornerSize, size.height - padding - cornerSize),
      paint,
    );

    // 右下角
    canvas.drawLine(
      Offset(size.width - padding - cornerSize, size.height - padding),
      Offset(size.width - padding, size.height - padding - cornerSize),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding),
      Offset(
        size.width - padding - cornerSize,
        size.height - padding - cornerSize,
      ),
      paint,
    );
  }

  void _drawSpecialDecorations(Canvas canvas, Size size, Paint paint) {
    // 在右上角繪製中國風的雲紋裝飾
    _drawCloudPattern(canvas, size, paint);

    // 在左下角繪製如意紋裝飾
    _drawRuyiPattern(canvas, size, paint);
  }

  void _drawCloudPattern(Canvas canvas, Size size, Paint paint) {
    // 繪製簡化的雲紋
    double centerX = size.width - 25;
    double centerY = 25;

    // 雲紋的基本形狀
    final cloudPath = Path();
    cloudPath.moveTo(centerX - 8, centerY);
    cloudPath.quadraticBezierTo(
      centerX - 12,
      centerY - 4,
      centerX - 8,
      centerY - 8,
    );
    cloudPath.quadraticBezierTo(
      centerX - 4,
      centerY - 12,
      centerX,
      centerY - 8,
    );
    cloudPath.quadraticBezierTo(
      centerX + 4,
      centerY - 12,
      centerX + 8,
      centerY - 8,
    );
    cloudPath.quadraticBezierTo(
      centerX + 12,
      centerY - 4,
      centerX + 8,
      centerY,
    );
    cloudPath.quadraticBezierTo(centerX + 4, centerY + 4, centerX, centerY);
    cloudPath.quadraticBezierTo(centerX - 4, centerY + 4, centerX - 8, centerY);
    cloudPath.close();

    canvas.drawPath(cloudPath, paint);
  }

  void _drawRuyiPattern(Canvas canvas, Size size, Paint paint) {
    // 繪製簡化的如意紋
    double centerX = 25;
    double centerY = size.height - 25;

    // 如意紋的基本形狀
    final ruyiPath = Path();
    ruyiPath.moveTo(centerX - 6, centerY);
    ruyiPath.quadraticBezierTo(
      centerX - 10,
      centerY - 6,
      centerX - 6,
      centerY - 10,
    );
    ruyiPath.quadraticBezierTo(
      centerX - 2,
      centerY - 14,
      centerX + 2,
      centerY - 10,
    );
    ruyiPath.quadraticBezierTo(
      centerX + 6,
      centerY - 6,
      centerX + 10,
      centerY - 2,
    );
    ruyiPath.quadraticBezierTo(
      centerX + 14,
      centerY + 2,
      centerX + 10,
      centerY + 6,
    );
    ruyiPath.quadraticBezierTo(
      centerX + 6,
      centerY + 10,
      centerX + 2,
      centerY + 6,
    );
    ruyiPath.quadraticBezierTo(centerX - 2, centerY + 2, centerX - 6, centerY);
    ruyiPath.close();

    canvas.drawPath(ruyiPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
