import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/auth_api_service.dart';
import '../utils/api_debug_helper.dart';

/// API 調試頁面
class ApiDebugScreen extends StatelessWidget {
  const ApiDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 調試'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 當前 API 狀態
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '當前 API 狀態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('環境: ${ApiConfig.environmentName}'),
                    Text('URL: ${ApiConfig.baseUrl}'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ApiConfig.isTestEnvironment
                            ? Colors.orange[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ApiConfig.isTestEnvironment ? '測試環境' : '生產環境',
                        style: TextStyle(
                          color: ApiConfig.isTestEnvironment
                              ? Colors.orange[800]
                              : Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 快速切換按鈕
            const Text(
              '快速切換',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ApiConfig.useTest();
                      _showSnackBar(context, '已切換到測試環境');
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('測試環境'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ApiConfig.useProduction();
                      _showSnackBar(context, '已切換到生產環境');
                    },
                    icon: const Icon(Icons.cloud),
                    label: const Text('生產環境'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 詳細切換選項
            const Text(
              '詳細選項',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                ApiDebugHelper.showApiSwitchDialog(context);
              },
              icon: const Icon(Icons.settings),
              label: const Text('選擇 API 端點'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 16),

            // API 信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API 信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('AuthApiService: ${AuthApiService.currentApiInfo}'),
                    const SizedBox(height: 8),
                    const Text('可用端點:'),
                    ...ApiConfig.availableEndpoints.map((endpoint) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• ${endpoint.name}: ${endpoint.url}'),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 測試按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _testApiConnection(context);
                },
                icon: const Icon(Icons.network_check),
                label: const Text('測試 API 連接'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _testApiConnection(BuildContext context) {
    // 這裡可以添加實際的 API 連接測試
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('API 連接測試'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('正在測試連接: ${ApiConfig.baseUrl}'),
            ],
          ),
        );
      },
    );

    // 模擬測試延遲
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showSnackBar(context, 'API 連接測試完成');
      }
    });
  }
}
