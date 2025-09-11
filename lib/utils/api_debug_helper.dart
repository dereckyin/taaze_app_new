import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/auth_api_service.dart';

/// API 調試助手
class ApiDebugHelper {
  /// 顯示 API 切換對話框
  static void showApiSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('API 端點切換'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '當前: ${ApiConfig.currentApiInfo}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('選擇要切換到的 API 端點:'),
              const SizedBox(height: 12),
              ...ApiConfig.availableEndpoints.map((endpoint) {
                final isCurrent = endpoint.url == ApiConfig.baseUrl;
                return ListTile(
                  title: Text(endpoint.name),
                  subtitle: Text(endpoint.url),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: isCurrent
                      ? null
                      : () {
                          ApiConfig.setBaseUrl(endpoint.url);
                          Navigator.of(context).pop();
                          _showApiChangedSnackBar(context);
                        },
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  /// 顯示 API 切換成功的提示
  static void _showApiChangedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切換到: ${ApiConfig.currentApiInfo}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 在控制台輸出當前 API 信息
  static void logCurrentApiInfo() {
    print('🔧 ${ApiConfig.currentApiInfo}');
    print('🔧 AuthApiService: ${AuthApiService.currentApiInfo}');
  }

  /// 快速切換到測試環境
  static void switchToTest() {
    ApiConfig.useTest();
    logCurrentApiInfo();
  }

  /// 快速切換到生產環境
  static void switchToProduction() {
    ApiConfig.useProduction();
    logCurrentApiInfo();
  }

  /// 獲取 API 狀態信息
  static Map<String, dynamic> getApiStatus() {
    return {
      'currentUrl': ApiConfig.baseUrl,
      'environment': ApiConfig.environmentName,
      'isTest': ApiConfig.isTestEnvironment,
      'isProduction': ApiConfig.isProductionEnvironment,
      'availableEndpoints': ApiConfig.availableEndpoints
          .map((e) => e.toString())
          .toList(),
    };
  }
}
