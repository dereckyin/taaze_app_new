import 'package:flutter/foundation.dart';
import '../models/coupon.dart';

class CouponProvider with ChangeNotifier {
  final List<Coupon> _coupons = [];
  bool _isLoading = false;
  String? _error;

  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 獲取可用的折價券
  List<Coupon> get availableCoupons {
    return _coupons.where((coupon) => coupon.isAvailable).toList();
  }

  // 獲取即將過期的折價券（7天內）
  List<Coupon> get expiringSoonCoupons {
    return _coupons.where((coupon) {
      return coupon.isAvailable && coupon.remainingDays <= 7;
    }).toList();
  }

  // 載入折價券數據
  Future<void> loadCoupons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 模擬API調用延遲
      await Future.delayed(const Duration(milliseconds: 500));

      // 使用模擬數據
      _coupons.clear();
      _coupons.addAll(getMockCoupons());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '載入折價券失敗: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // 領取折價券
  Future<bool> claimCoupon(String couponId) async {
    try {
      // 模擬API調用
      await Future.delayed(const Duration(milliseconds: 300));

      // 在實際應用中，這裡會調用API來領取折價券
      // 現在只是模擬成功
      return true;
    } catch (e) {
      _error = '領取折價券失敗: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // 獲取模擬折價券數據
  List<Coupon> getMockCoupons() {
    final now = DateTime.now();

    return [
      Coupon(
        id: 'coupon_50_1',
        title: '新用戶專享',
        description: '首次購書優惠',
        discountAmount: 50.0,
        discountType: 'fixed',
        minOrderAmount: 200.0,
        expiryDate: now.add(const Duration(days: 30)),
        status: 'active',
        backgroundColor: '#E91E63', // 主題桃紅色
        textColor: '#FFFFFF',
      ),
      Coupon(
        id: 'coupon_100_1',
        title: '滿額優惠',
        description: '購物滿額立減',
        discountAmount: 100.0,
        discountType: 'fixed',
        minOrderAmount: 500.0,
        expiryDate: now.add(const Duration(days: 15)),
        status: 'active',
        backgroundColor: '#E91E63', // 主題桃紅色
        textColor: '#FFFFFF',
      ),
      Coupon(
        id: 'coupon_20_percent',
        title: '限時優惠',
        description: '全館8折優惠',
        discountAmount: 20.0,
        discountType: 'percentage',
        minOrderAmount: 300.0,
        expiryDate: now.add(const Duration(days: 7)),
        status: 'active',
        backgroundColor: '#E91E63', // 主題桃紅色
        textColor: '#FFFFFF',
      ),
      Coupon(
        id: 'coupon_80_1',
        title: '週末特惠',
        description: '週末購書優惠',
        discountAmount: 80.0,
        discountType: 'fixed',
        minOrderAmount: 400.0,
        expiryDate: now.add(const Duration(days: 3)),
        status: 'active',
        backgroundColor: '#E91E63', // 主題桃紅色
        textColor: '#FFFFFF',
      ),
      Coupon(
        id: 'coupon_150_1',
        title: 'VIP專享',
        description: '會員專屬優惠',
        discountAmount: 150.0,
        discountType: 'fixed',
        minOrderAmount: 800.0,
        expiryDate: now.add(const Duration(days: 45)),
        status: 'active',
        backgroundColor: '#E91E63', // 主題桃紅色
        textColor: '#FFFFFF',
      ),
      Coupon(
        id: 'coupon_30_percent',
        title: '清倉特價',
        description: '清倉商品7折',
        discountAmount: 30.0,
        discountType: 'percentage',
        minOrderAmount: 200.0,
        expiryDate: now.add(const Duration(days: 5)),
        status: 'active',
        backgroundColor: '#E91E63', // 主題桃紅色
        textColor: '#FFFFFF',
      ),
    ];
  }

  // 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 刷新數據
  Future<void> refresh() async {
    await loadCoupons();
  }
}
