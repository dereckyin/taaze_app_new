import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugHelper {
  static bool get isDebugMode => kDebugMode;
  
  // 打印debug信息
  static void log(String message, {String? tag}) {
    if (isDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final prefix = tag != null ? '[$tag]' : '[DEBUG]';
      print('$prefix $timestamp: $message');
    }
  }
  
  // 打印Provider狀態
  static void logProviderState(String providerName, dynamic state) {
    if (isDebugMode) {
      log('$providerName State: $state', tag: 'PROVIDER');
    }
  }
  
  // 打印API請求
  static void logApiRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (isDebugMode) {
      log('API Request: $method $url', tag: 'API');
      if (body != null) {
        log('Request Body: $body', tag: 'API');
      }
    }
  }
  
  // 打印API響應
  static void logApiResponse(int statusCode, String response) {
    if (isDebugMode) {
      log('API Response: $statusCode', tag: 'API');
      log('Response Body: $response', tag: 'API');
    }
  }
  
  // 顯示debug信息覆蓋層
  static Widget debugOverlay(Widget child, {Map<String, dynamic>? debugInfo}) {
    if (!isDebugMode) return child;
    
    return Stack(
      children: [
        child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DEBUG INFO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (debugInfo != null)
                  ...debugInfo.entries.map((entry) => Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // 測量widget渲染時間
  static void measureRenderTime(String widgetName, VoidCallback buildFunction) {
    if (!isDebugMode) {
      buildFunction();
      return;
    }
    
    final stopwatch = Stopwatch()..start();
    buildFunction();
    stopwatch.stop();
    
    log('$widgetName render time: ${stopwatch.elapsedMicroseconds}μs', tag: 'PERFORMANCE');
  }
  
  // 檢查內存使用
  static void logMemoryUsage() {
    if (isDebugMode) {
      // 注意：這需要額外的package來獲取實際內存使用
      log('Memory usage check - 需要添加memory_info package', tag: 'MEMORY');
    }
  }
}
