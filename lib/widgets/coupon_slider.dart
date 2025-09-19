import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coupon_provider.dart';
import '../models/coupon.dart';
import 'coupon_card.dart';

class CouponSlider extends StatefulWidget {
  const CouponSlider({super.key});

  @override
  State<CouponSlider> createState() => _CouponSliderState();
}

class _CouponSliderState extends State<CouponSlider> {
  final PageController _pageController = PageController();
  final Map<String, bool> _claimingStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CouponProvider>().loadCoupons();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CouponProvider>(
      builder: (context, couponProvider, child) {
        if (couponProvider.isLoading) {
          return _buildLoadingState();
        }

        if (couponProvider.error != null) {
          return _buildErrorState(couponProvider.error!);
        }

        if (couponProvider.availableCoupons.isEmpty) {
          return _buildEmptyState();
        }

        return _buildCouponSlider(couponProvider.availableCoupons);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              '載入折價券失敗',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                context.read<CouponProvider>().loadCoupons();
              },
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              '暫無可用折價券',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSlider(List<Coupon> coupons) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CouponCard(
              coupon: coupon,
              isClaiming: _claimingStates[coupon.id] ?? false,
              onClaim: () => _claimCoupon(coupon),
            ),
          );
        },
      ),
    );
  }

  Future<void> _claimCoupon(Coupon coupon) async {
    setState(() {
      _claimingStates[coupon.id] = true;
    });

    try {
      final success = await context.read<CouponProvider>().claimCoupon(
        coupon.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功領取 ${coupon.title} 折價券！'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () {
                // TODO: 導航到我的折價券頁面
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('領取失敗，請稍後再試'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _claimingStates[coupon.id] = false;
        });
      }
    }
  }
}
