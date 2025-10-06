import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/today_deals_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/ai_listing_wizard_provider.dart';
import 'providers/coupon_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _initializeNotifications();
  }

  Future<void> _initializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initializeAuth();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    final notifProvider = context.read<NotificationProvider>();
    await NotificationService.instance.initialize(provider: notifProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // 顯示載入畫面
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 無論登入狀態如何，都直接進入主畫面
    return const MainScreen();
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
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
        ChangeNotifierProvider(create: (_) => AiListingWizardProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
      ],
      child: MaterialApp(
        title: '讀冊生活網路書店',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AppHome(),
      ),
    );
  }
}
