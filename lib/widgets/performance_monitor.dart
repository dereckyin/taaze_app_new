import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../utils/debug_helper.dart';

class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? name;
  final bool showOverlay;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.name,
    this.showOverlay = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  int _frameCount = 0;
  int _lastFrameCount = 0;
  DateTime _lastTime = DateTime.now();
  double _fps = 0.0;
  final List<double> _fpsHistory = [];
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    if (DebugHelper.isDebugMode) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    if (_isMonitoring) {
      _stopMonitoring();
    }
    super.dispose();
  }

  void _startMonitoring() {
    _isMonitoring = true;
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  void _stopMonitoring() {
    _isMonitoring = false;
    WidgetsBinding.instance.removeObserver(this);
    // 注意：removePersistentFrameCallback 在某些Flutter版本中可能不可用
    // SchedulerBinding.instance.removePersistentFrameCallback(_onFrame);
  }

  void _onFrame(Duration timeStamp) {
    if (!mounted) return;

    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTime).inMilliseconds;

    if (elapsed >= 1000) {
      final fps = (_frameCount - _lastFrameCount) * 1000 / elapsed;
      setState(() {
        _fps = fps;
        _fpsHistory.add(fps);
        if (_fpsHistory.length > 60) {
          _fpsHistory.removeAt(0);
        }
      });

      _lastFrameCount = _frameCount;
      _lastTime = now;

      // 記錄低FPS警告
      if (fps < 30) {
        DebugHelper.log(
          'Low FPS detected: ${fps.toStringAsFixed(1)} in ${widget.name ?? 'Unknown Widget'}',
          tag: 'PERFORMANCE',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DebugHelper.isDebugMode || !widget.showOverlay) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Performance Monitor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'FPS: ${_fps.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: _fps >= 55 ? Colors.green : 
                           _fps >= 30 ? Colors.yellow : Colors.red,
                    fontSize: 11,
                  ),
                ),
                if (widget.name != null)
                  Text(
                    'Widget: ${widget.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                Text(
                  'Frames: $_frameCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 性能測量裝飾器
class PerformanceMeasurer extends StatelessWidget {
  final Widget child;
  final String name;
  final VoidCallback? onSlowRender;

  const PerformanceMeasurer({
    super.key,
    required this.child,
    required this.name,
    this.onSlowRender,
  });

  @override
  Widget build(BuildContext context) {
    if (!DebugHelper.isDebugMode) {
      return child;
    }

    return Builder(
      builder: (context) {
        final stopwatch = Stopwatch()..start();
        
        final result = child;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopwatch.stop();
          final renderTime = stopwatch.elapsedMicroseconds;
          
          DebugHelper.log(
            '$name render time: $renderTimeμs',
            tag: 'PERFORMANCE',
          );
          
          // 如果渲染時間超過16ms (60fps)，發出警告
          if (renderTime > 16000 && onSlowRender != null) {
            onSlowRender!();
          }
        });
        
        return result;
      },
    );
  }
}

// 內存使用監控
class MemoryMonitor extends StatefulWidget {
  final Widget child;

  const MemoryMonitor({
    super.key,
    required this.child,
  });

  @override
  State<MemoryMonitor> createState() => _MemoryMonitorState();
}

class _MemoryMonitorState extends State<MemoryMonitor>
    with WidgetsBindingObserver {
  Timer? _timer;
  // int _memoryUsage = 0; // 暫時註解未使用的變量

  @override
  void initState() {
    super.initState();
    if (DebugHelper.isDebugMode) {
      _startMemoryMonitoring();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMemoryMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkMemoryUsage();
    });
  }

  void _checkMemoryUsage() {
    // 注意：實際的內存監控需要額外的package
    // 這裡只是示例
    DebugHelper.log('Memory check - 需要添加memory_info package', tag: 'MEMORY');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
