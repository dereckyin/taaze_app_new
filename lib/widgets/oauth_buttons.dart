import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/oauth_config.dart';

/// OAuth 登入按鈕組件
class OAuthButtons extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const OAuthButtons({super.key, this.onSuccess, this.onError});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 分隔線
        _buildDivider(context),

        const SizedBox(height: 16),

        // OAuth 按鈕
        _buildOAuthButtons(context),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '或使用以下方式登入',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }

  Widget _buildOAuthButtons(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final configuredProviders = OAuthConfig.getConfiguredProviders();

        if (configuredProviders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: _buildAvailableOAuthButtons(
            context,
            authProvider,
            configuredProviders,
          ),
        );
      },
    );
  }

  List<Widget> _buildAvailableOAuthButtons(
    BuildContext context,
    AuthProvider authProvider,
    List<String> configuredProviders,
  ) {
    final buttons = <Widget>[];

    // Google 登入按鈕
    if (configuredProviders.contains('google')) {
      buttons.add(
        _buildOAuthButton(
          context: context,
          label: '使用 Google 登入',
          icon: FontAwesomeIcons.google,
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey[300]!,
          onPressed: authProvider.isLoading
              ? null
              : () => _handleGoogleSignIn(context),
        ),
      );
    }

    // Facebook 登入按鈕
    if (configuredProviders.contains('facebook')) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 8));
      buttons.add(
        _buildOAuthButton(
          context: context,
          label: '使用 Facebook 登入',
          icon: FontAwesomeIcons.facebook,
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
          borderColor: const Color(0xFF1877F2),
          onPressed: authProvider.isLoading
              ? null
              : () => _handleFacebookSignIn(context),
        ),
      );
    }

    // LINE 登入按鈕
    if (configuredProviders.contains('line')) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 8));
      buttons.add(
        _buildOAuthButton(
          context: context,
          label: '使用 LINE 登入',
          icon: FontAwesomeIcons.line,
          backgroundColor: const Color(0xFF00C300),
          textColor: Colors.white,
          borderColor: const Color(0xFF00C300),
          onPressed: authProvider.isLoading
              ? null
              : () => _handleLineSignIn(context),
        ),
      );
    }

    return buttons;
  }

  Widget _buildOAuthButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 20, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 處理 Google 登入
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.signInWithGoogle();

      if (success && context.mounted) {
        onSuccess?.call();
        _showSuccessMessage(context, 'Google 登入成功');
      } else if (context.mounted) {
        onError?.call();
        _showErrorMessage(context, authProvider.error ?? 'Google 登入失敗');
      }
    } catch (e) {
      if (context.mounted) {
        onError?.call();
        _showErrorMessage(context, 'Google 登入發生錯誤：${e.toString()}');
      }
    }
  }

  /// 處理 Facebook 登入
  Future<void> _handleFacebookSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.signInWithFacebook();

      if (success && context.mounted) {
        onSuccess?.call();
        _showSuccessMessage(context, 'Facebook 登入成功');
      } else if (context.mounted) {
        onError?.call();
        _showErrorMessage(context, authProvider.error ?? 'Facebook 登入失敗');
      }
    } catch (e) {
      if (context.mounted) {
        onError?.call();
        _showErrorMessage(context, 'Facebook 登入發生錯誤：${e.toString()}');
      }
    }
  }

  /// 處理 LINE 登入
  Future<void> _handleLineSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.signInWithLine();

      if (success && context.mounted) {
        onSuccess?.call();
        _showSuccessMessage(context, 'LINE 登入成功');
      } else if (context.mounted) {
        onError?.call();
        _showErrorMessage(context, authProvider.error ?? 'LINE 登入失敗');
      }
    } catch (e) {
      if (context.mounted) {
        onError?.call();
        _showErrorMessage(context, 'LINE 登入發生錯誤：${e.toString()}');
      }
    }
  }

  /// 顯示成功訊息
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 顯示錯誤訊息
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// 單個 OAuth 按鈕組件（可重複使用）
class OAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  const OAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(icon, size: 20, color: textColor),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// OAuth 提供商資訊
class OAuthProviderInfo {
  final String name;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;

  const OAuthProviderInfo({
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
  });

  static const OAuthProviderInfo google = OAuthProviderInfo(
    name: 'Google',
    icon: FontAwesomeIcons.google,
    primaryColor: Color(0xFF4285F4),
    backgroundColor: Colors.white,
    textColor: Colors.black87,
  );

  static const OAuthProviderInfo facebook = OAuthProviderInfo(
    name: 'Facebook',
    icon: FontAwesomeIcons.facebook,
    primaryColor: Color(0xFF1877F2),
    backgroundColor: Color(0xFF1877F2),
    textColor: Colors.white,
  );

  static const OAuthProviderInfo line = OAuthProviderInfo(
    name: 'LINE',
    icon: FontAwesomeIcons.line,
    primaryColor: Color(0xFF00C300),
    backgroundColor: Color(0xFF00C300),
    textColor: Colors.white,
  );
}
