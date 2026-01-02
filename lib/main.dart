import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/today_deals_provider.dart';
import 'providers/bestsellers_provider.dart';
import 'providers/new_arrivals_provider.dart';
import 'providers/ebook_new_arrivals_provider.dart';
import 'providers/used_books_latest_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/ai_listing_wizard_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/orders_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Avoid duplicate initialization if some plugin auto-started Firebase.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  // 在 runApp() 之前初始化通知服務
  await LocalNotificationService.instance.initialize();
  
  runApp(const BookStoreApp());
}

/// 應用主頁面，根據登入狀態決定顯示哪個畫面
class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  bool _isInitialized = false;
  late final DateTime _splashStartAt;
  static const Duration _minSplash = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _splashStartAt = DateTime.now();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    final notifProvider = context.read<NotificationProvider>();
    await authProvider.initializeAuth();
    await NotificationService.instance.initialize(
      provider: notifProvider,
      authToken: authProvider.authToken,
    );

    // 確保啟動畫面至少顯示一小段時間，避免瞬間跳轉
    final elapsed = DateTime.now().difference(_splashStartAt);
    if (elapsed < _minSplash) {
      await Future.delayed(_minSplash - elapsed);
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // 顯示載入畫面
      return const SplashScreen();
    }

    // 不論是否登入，皆可先進入主畫面（受限功能再另行要求登入）
    return const MainScreen();
  }
}

/// 啟動載入畫面（置中顯示 Logo）
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 將專案圖示置中作為啟動畫面 Logo
            Image.asset(
              'temp_icons/taaze_icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class BookStoreApp extends StatelessWidget {
  const BookStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => TodayDealsProvider()),
        ChangeNotifierProvider(create: (_) => BestsellersProvider()),
        ChangeNotifierProvider(create: (_) => NewArrivalsProvider()),
        ChangeNotifierProvider(create: (_) => EbookNewArrivalsProvider()),
        ChangeNotifierProvider(create: (_) => UsedBooksLatestProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
        ChangeNotifierProvider(create: (_) => AiListingWizardProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
      ],
      child: MaterialApp(
        title: '讀冊生活網路書店',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        home: const AppHome(),
      ),
    );
  }
}
