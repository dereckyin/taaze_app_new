import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/local_notification_service.dart';
import 'services/navigation_service.dart';
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
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 重新啟用 Firebase 初始化
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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
    // 通知服務已在 main() 中初始化，這裡只需要設定 provider
    // 暫時不初始化 Firebase 推播通知，專注於本地通知
    // await NotificationService.instance.initialize(
    //   provider: notifProvider,
    //   authProvider: authProvider,
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // 顯示載入畫面
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 根據登入狀態決定顯示哪個畫面
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 如果已登入（有token和用戶資料），直接進入主畫面
        if (authProvider.isAuthenticated && authProvider.authToken != null) {
          return const MainScreen();
        }
        // 否則顯示登入畫面
        return const LoginScreen();
      },
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
