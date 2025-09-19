import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/ai_listing_wizard_provider.dart';
import 'identified_books_list_screen.dart';

class AiListingWizardScreen extends StatefulWidget {
  const AiListingWizardScreen({super.key});

  @override
  State<AiListingWizardScreen> createState() => _AiListingWizardScreenState();
}

class _AiListingWizardScreenState extends State<AiListingWizardScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI上架精靈'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Consumer<AiListingWizardProvider>(
          builder: (context, provider, child) {
            // 如果有識別結果，顯示重新識別按鈕而不是返回按鈕
            if (provider.identifiedBooks.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _showReidentifyOptions,
                tooltip: '重新識別',
              );
            }
            // 默認返回按鈕
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '返回',
            );
          },
        ),
        actions: [
          Consumer<AiListingWizardProvider>(
            builder: (context, provider, child) {
              if (provider.hasSelectedBooks) {
                return TextButton(
                  onPressed: provider.isLoading ? null : _importToDraft,
                  child: Text(
                    '匯入草稿 (${provider.selectedBooks.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AiListingWizardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          if (provider.identifiedBooks.isNotEmpty) {
            return _buildResultsState();
          }

          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'AI正在識別書籍...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '請稍候，這可能需要幾秒鐘',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('識別失敗', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryIdentification,
              icon: const Icon(Icons.refresh),
              label: const Text('重新識別'),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _clearAll, child: const Text('重新開始')),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsState() {
    return Column(
      children: [
        // 結果摘要
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    '識別完成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showReidentifyOptions,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重新識別'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '找到 ${context.watch<AiListingWizardProvider>().identifiedBooks.length} 本書籍',
                style: TextStyle(color: Colors.blue[600]),
              ),
              Consumer<AiListingWizardProvider>(
                builder: (context, provider, child) {
                  if (provider.hasSelectedBooks) {
                    return Text(
                      '已選擇 ${provider.selectedBooks.length} 本書籍',
                      style: TextStyle(color: Colors.blue[600]),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        // 書籍列表
        Expanded(child: IdentifiedBooksListScreen()),
      ],
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'AI上架精靈',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '拍攝或上傳書櫃照片，AI將自動識別書籍並幫您快速上架',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // 拍照按鈕
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照識別'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 從相簿選擇按鈕
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('從相簿選擇'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 使用說明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        '使用說明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 確保照片清晰，書籍封面完整可見\n'
                    '• 建議在光線充足的地方拍攝\n'
                    '• 一次最多可識別多本書籍\n'
                    '• 識別後可選擇正確版本並設定價格',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final provider = context.read<AiListingWizardProvider>();
        await provider.identifyBooks(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('拍照失敗: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final provider = context.read<AiListingWizardProvider>();
        await provider.identifyBooks(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('選擇照片失敗: ${e.toString()}');
    }
  }

  Future<void> _retryIdentification() async {
    final provider = context.read<AiListingWizardProvider>();
    if (provider.selectedImage != null) {
      await provider.reIdentify();
    }
  }

  void _clearAll() {
    context.read<AiListingWizardProvider>().clearAll();
  }

  Future<void> _importToDraft() async {
    final provider = context.read<AiListingWizardProvider>();
    final success = await provider.importToDraft();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功匯入 ${provider.selectedBooks.length} 本書籍到上架草稿'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: '查看草稿',
            textColor: Colors.white,
            onPressed: () {
              // TODO: 導航到草稿頁面
            },
          ),
        ),
      );
    } else if (mounted) {
      _showErrorSnackBar(provider.error ?? '匯入失敗');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showReidentifyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  '重新識別書籍',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照識別'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('從相簿選擇'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('清除結果'),
                onTap: () {
                  Navigator.pop(context);
                  _clearAll();
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('返回上一頁'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
