import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/ai_listing_wizard_provider.dart';
import '../providers/auth_provider.dart';
import 'identified_books_list_screen.dart';
import 'login_screen.dart';
import 'barcode_scanner_screen.dart';
import 'draft_list_screen.dart';

class AiListingWizardScreen extends StatefulWidget {
  const AiListingWizardScreen({super.key});

  @override
  State<AiListingWizardScreen> createState() => _AiListingWizardScreenState();
}

class _AiListingWizardScreenState extends State<AiListingWizardScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 進入時檢查登入狀態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  Future<void> _checkAuthAndRedirect() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.authToken == null || authProvider.authToken!.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('使用 AI 上架精靈前請先登入會員。')),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      // 如果登入後還是沒 token，或是使用者取消登入回來的，就退出此頁面
      if (!mounted) return;
      final finalToken = context.read<AuthProvider>().authToken;
      if (finalToken == null || finalToken.isEmpty) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI上架精靈'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Selector<AiListingWizardProvider, bool>(
          selector: (_, p) => p.identifiedBooks.isNotEmpty,
          builder: (context, hasBooks, child) {
            // 如果有識別結果，顯示重新識別按鈕而不是返回按鈕
            if (hasBooks) {
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
          Selector<AiListingWizardProvider, ({bool hasSelected, int selectedCount, bool isLoading})>(
            selector: (_, p) => (
              hasSelected: p.hasSelectedBooks,
              selectedCount: p.selectedBooks.length,
              isLoading: p.isLoading,
            ),
            builder: (context, state, child) {
              if (state.hasSelected) {
                return TextButton(
                  onPressed: state.isLoading ? null : _showSubmitApplicationDialog,
                  child: const Text(
                    '提交申請單',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Selector<AiListingWizardProvider, ({bool isLoading, String? error, bool hasBooks})>(
        selector: (_, provider) => (
          isLoading: provider.isLoading,
          error: provider.error,
          hasBooks: provider.identifiedBooks.isNotEmpty,
        ),
        builder: (context, state, child) {
          if (state.isLoading) {
            return _buildLoadingState();
          }

          if (state.error != null) {
            return _buildErrorState(state.error!);
          }

          if (state.hasBooks) {
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
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('識別失敗', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
              Selector<AiListingWizardProvider, int>(
                selector: (_, p) => p.identifiedBooks.length,
                builder: (context, count, _) => Text(
                  '找到 $count 本書籍',
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ),
              Selector<AiListingWizardProvider, int>(
                selector: (_, p) => p.selectedBooks.length,
                builder: (context, selectedCount, _) {
                  if (selectedCount > 0) {
                    return Text(
                      '已選擇 $selectedCount 本書籍',
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
        const Expanded(child: IdentifiedBooksListScreen()),
      ],
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 70,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'AI上架精靈',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '拍攝或上傳書櫃照片，AI將自動識別書籍並幫您快速上架',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 拍照按鈕
                SizedBox(
                  width: double.infinity,
                  height: 52,
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

                const SizedBox(height: 12),

                // 從相簿選擇按鈕
                SizedBox(
                  width: double.infinity,
                  height: 52,
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

                const SizedBox(height: 12),

                // 條碼掃描按鈕
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final auth = context.read<AuthProvider>();
                      if (auth.authToken == null || auth.authToken!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('請先登入後再掃描條碼')),
                        );
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                        return;
                      }

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BarcodeScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('掃描條碼單本上架'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 查看上架草稿
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _openDraftList,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('查看上架草稿'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 使用說明
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '使用說明',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                              fontSize: 14,
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
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Future<void> _openDraftList() async {
    final auth = context.read<AuthProvider>();
    if (auth.authToken == null || auth.authToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入後查看上架草稿')),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DraftListScreen(),
      ),
    );
  }

  Future<void> _showSubmitApplicationDialog() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入後再提交申請單')),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上架申請說明'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '感謝您使用 AI 上架精靈！',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• 提交後，系統將書單列表放置二手書上架申請。'),
            SizedBox(height: 8),
            Text(
              '• 若需修改詳細書籍資料，請至 TAAZE 官網的「二手書上架申請」進行更新。',
              style: TextStyle(color: Colors.blueGrey),
            ),
            SizedBox(height: 12),
            Text('確認目前選擇的書籍無誤並提交嗎？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<AiListingWizardProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final authProvider = context.read<AuthProvider>();
              
              Navigator.pop(context); // 關閉對話框

              final success = await provider.submitApplication(
                authToken: authProvider.authToken,
              );

              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('二手書申請單提交成功！'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? '提交失敗'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('確認提交'),
          ),
        ],
      ),
    );
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
