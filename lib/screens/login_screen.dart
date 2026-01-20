import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/security_widgets.dart';
import '../widgets/api_captcha_widget.dart';
import '../widgets/oauth_buttons.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  /// 若從「結帳」等需要回到上一頁的情境進入，可用 [popOnSuccess] 讓登入成功後
  /// `Navigator.pop(context, true)` 回傳成功，交由上一頁接續流程。
  final bool popOnSuccess;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.popOnSuccess = false,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    // 不在 initState 中獲取驗證碼，而是在 Consumer 中處理
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {}); // 觸發密碼強度指示器更新
  }

  Future<void> _refreshCaptcha() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.refreshCaptcha();
    // 清除驗證碼輸入框
    _captchaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '登入', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Logo（簡化版）
              _buildHeader(),

              const SizedBox(height: 24),

              // 安全狀態顯示
              _buildSecurityStatus(),

              const SizedBox(height: 12),

              // 登入表單
              _buildLoginForm(),

              const SizedBox(height: 12),

              // 驗證碼（始終顯示）
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  // 如果沒有驗證碼且沒有在載入，自動獲取驗證碼
                  if (authProvider.currentCaptcha == null &&
                      !authProvider.isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      authProvider.fetchCaptcha();
                    });
                    // 顯示載入中的驗證碼區域
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '安全驗證',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '正在載入驗證碼...',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '安全驗證',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '為了保護您的帳戶安全，請輸入下方驗證碼完成登入',
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ApiCaptchaWidget(
                              captcha: authProvider.currentCaptcha,
                              onCaptchaChanged: (value) {
                                _captchaController.text = value;
                              },
                              onRefreshCaptcha: _refreshCaptcha,
                              isLoading: authProvider.isLoading,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              // 登入按鈕
              _buildLoginButton(),

              const SizedBox(height: 12),

              // OAuth 登入按鈕
              OAuthButtons(
                onSuccess: () async {
                  if (!context.mounted) return;
                  
                  // 同步本機暫存並獲取清單
                  final authProvider = context.read<AuthProvider>();
                  final watchlistProvider = context.read<WatchlistProvider>();
                  if (authProvider.authToken != null) {
                    await watchlistProvider.syncLocalToBackend(authProvider.authToken!);
                    await watchlistProvider.fetchRemoteWatchlist(authProvider.authToken!);
                  }

                  if (widget.popOnSuccess) {
                    widget.onLoginSuccess?.call();
                    Navigator.pop(context, true);
                    return;
                  }
                  // OAuth 登入成功，導航到主頁面
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
                onError: () {
                  // OAuth 登入失敗，顯示錯誤訊息
                  // 錯誤訊息已在 OAuthButtons 中處理
                },
              ),

              const SizedBox(height: 12),

              // 註冊連結
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.book, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // 電子郵件或用戶名輸入框
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'TAAZE帳號',
            prefixIcon: Icon(Icons.person_outlined),
            hintText: '請輸入您的TAAZE帳號',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '請輸入您的TAAZE帳號';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // 密碼輸入框
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: '密碼',
            prefixIcon: const Icon(Icons.lock_outlined),
            hintText: '請輸入您的密碼',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '請輸入密碼';
            }
            if (value.length < 6) {
              return '密碼至少需要6個字符';
            }
            return null;
          },
        ),

        // 密碼強度指示器
        const SizedBox(height: 6),
        PasswordStrengthIndicator(password: _passwordController.text),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ElevatedButton(
          onPressed: authProvider.isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: authProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  '登入',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        );
      },
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('還沒有帳戶？', style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text('立即註冊'),
        ),
      ],
    );
  }

  Widget _buildSecurityStatus() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 顯示帳戶鎖定狀態
        if (authProvider.isAccountLocked) {
          final remainingTime = authProvider.getLockoutRemainingTime();
          if (remainingTime != null) {
            return LockoutTimerWidget(
              remainingTime: remainingTime,
              onUnlock: () {
                setState(() {});
              },
            );
          }
        }

        // 顯示登入嘗試次數
        if (authProvider.remainingAttempts < AuthProvider.maxLoginAttempts) {
          return Column(
            children: [
              LoginAttemptsWidget(
                remainingAttempts: authProvider.remainingAttempts,
                maxAttempts: AuthProvider.maxLoginAttempts,
                nextResetTime: authProvider.getNextAttemptResetTime(),
              ),
              const SizedBox(height: 8),
              if (authProvider.remainingAttempts <= 2)
                const SecurityWarningWidget(
                  message: '剩餘嘗試次數較少，請確認帳號密碼正確',
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // 強制要求驗證碼
    if (_captchaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入驗證碼'), backgroundColor: Colors.red),
      );
      return;
    }

    // 確保有驗證碼ID
    if (authProvider.currentCaptcha?.captchaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('驗證碼已過期，請刷新後重試'),
          backgroundColor: Colors.red,
        ),
      );
      await _refreshCaptcha();
      return;
    }

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      captchaCode: _captchaController.text,
    );

    if (success && mounted) {
      // 登入成功，清除驗證碼輸入框
      _captchaController.clear();

      // 同步本機暫存並獲取清單
      final watchlistProvider = context.read<WatchlistProvider>();
      if (authProvider.authToken != null) {
        await watchlistProvider.syncLocalToBackend(authProvider.authToken!);
        await watchlistProvider.fetchRemoteWatchlist(authProvider.authToken!);
      }

      if (widget.popOnSuccess) {
        widget.onLoginSuccess?.call();
        Navigator.pop(context, true);
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } else if (mounted) {
      // 登入失敗，刷新驗證碼並顯示錯誤訊息
      await _refreshCaptcha();

      if (mounted) {
        final errorMessage = authProvider.error ?? '登入失敗';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
