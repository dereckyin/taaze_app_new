import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/second_hand_application_provider.dart';
import '../providers/auth_provider.dart';
import '../models/second_hand_application.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_app_bar.dart';
import 'second_hand_application_detail_screen.dart';

class SecondHandApplicationListScreen extends StatefulWidget {
  const SecondHandApplicationListScreen({super.key});

  @override
  State<SecondHandApplicationListScreen> createState() => _SecondHandApplicationListScreenState();
}

class _SecondHandApplicationListScreenState extends State<SecondHandApplicationListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreApplications();
    }
  }

  Future<void> _loadApplications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<SecondHandApplicationProvider>();

    if (authProvider.authToken == null) {
      return;
    }

    final paginated = await applicationProvider.getApplicationsByCustomer(
      authToken: authProvider.authToken,
      page: _currentPage,
      pageSize: _pageSize,
      append: !refresh && _currentPage > 1,
    );

    if (paginated != null && mounted) {
      setState(() {
        _hasMore = _currentPage < paginated.totalPages;
      });
    }
  }

  Future<void> _loadMoreApplications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadApplications();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadApplications(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '二手書申請單',
        showBackButton: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) {
            return _buildNotLoggedInState();
          }

          return Consumer<SecondHandApplicationProvider>(
            builder: (context, applicationProvider, child) {
              if (applicationProvider.isLoading && applicationProvider.applications.isEmpty) {
                return const Center(child: LoadingWidget());
              }

              if (applicationProvider.error != null && applicationProvider.applications.isEmpty) {
                return _buildErrorState(applicationProvider.error!);
              }

              final applications = applicationProvider.applications;
              if (applications.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: Column(
                  children: [
                    // 結果統計
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Text(
                        '共 ${applications.length} 筆申請單',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),

                    // 申請單列表
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: applications.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= applications.length) {
                            return _buildLoadingMoreIndicator();
                          }

                          final application = applications[index];
                          return _buildApplicationCard(application);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              '請先登入',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '登入後即可查看您的申請單',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              '尚無申請單',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '您目前沒有任何二手書申請單',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(SecondHandBookApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecondHandApplicationDetailScreen(
                applicationId: application.id ?? '',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '申請單編號: ${application.id ?? 'N/A'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (application.custName != null) ...[
                _buildInfoRow(Icons.person, '姓名', application.custName!),
                const SizedBox(height: 8),
              ],
              if (application.custMobile != null) ...[
                _buildInfoRow(Icons.phone, '電話', application.custMobile!),
                const SizedBox(height: 8),
              ],
              if (application.address != null) ...[
                _buildInfoRow(
                  Icons.location_on,
                  '地址',
                  '${application.cityId ?? ''}${application.townId ?? ''} ${application.address ?? ''}',
                ),
                const SizedBox(height: 8),
              ],
              _buildInfoRow(
                Icons.local_shipping,
                '配送方式',
                _getDeliveryTypeText(application.deliveryType),
              ),
              if (application.createdAt != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  '申請日期',
                  _formatDate(application.createdAt!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _getDeliveryTypeText(DeliveryType type) {
    switch (type) {
      case DeliveryType.home:
        return '宅配';
      case DeliveryType.store:
        return '超商取貨';
      case DeliveryType.post:
        return '郵寄';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('載入更多...'),
                ],
              )
            : const Text('沒有更多資料了', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
