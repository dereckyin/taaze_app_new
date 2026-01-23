import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/second_hand_application_provider.dart';
import '../providers/auth_provider.dart';
import '../models/second_hand_application.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_widget.dart';

class SecondHandApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const SecondHandApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<SecondHandApplicationDetailScreen> createState() => _SecondHandApplicationDetailScreenState();
}

class _SecondHandApplicationDetailScreenState extends State<SecondHandApplicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplication();
    });
  }

  Future<void> _loadApplication() async {
    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<SecondHandApplicationProvider>();

    if (authProvider.authToken == null) {
      return;
    }

    await applicationProvider.getApplicationById(
      authToken: authProvider.authToken,
      id: widget.applicationId,
    );

    await applicationProvider.getApplicationItems(
      authToken: authProvider.authToken,
      applicationId: widget.applicationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '申請單詳情',
        showBackButton: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) {
            return _buildNotLoggedInState();
          }

          return Consumer<SecondHandApplicationProvider>(
            builder: (context, applicationProvider, child) {
              final items = applicationProvider.currentApplicationItems;
              final application = applicationProvider.currentApplication;
              
              // Show loading only if we have no data at all
              if (applicationProvider.isLoading &&
                  application == null &&
                  items.isEmpty) {
                return const Center(child: LoadingWidget());
              }

              // Show error only if we have no data at all
              if (applicationProvider.error != null &&
                  application == null &&
                  items.isEmpty) {
                return _buildErrorState(applicationProvider.error!);
              }

              // If we have no items and no application, show empty state
              if (application == null && items.isEmpty) {
                return _buildEmptyState();
              }

              // Create a minimal application object if we have items but no application
              final displayApplication = application ?? 
                SecondHandBookApplication(
                  id: widget.applicationId,
                  deliveryType: DeliveryType.home,
                );

              return RefreshIndicator(
                onRefresh: _loadApplication,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildApplicationInfo(displayApplication),
                      const SizedBox(height: 24),
                      _buildItemsSection(items),
                    ],
                  ),
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
              '登入後即可查看申請單詳情',
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
              onPressed: _loadApplication,
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
              '找不到申請單',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationInfo(SecondHandBookApplication application) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '申請單資訊',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('申請單編號', application.id ?? 'N/A'),
            if (application.custName != null)
              _buildInfoRow('姓名', application.custName!),
            if (application.custMobile != null)
              _buildInfoRow('電話', application.custMobile!),
            if (application.address != null)
              _buildInfoRow(
                '地址',
                '${application.cityId ?? ''}${application.townId ?? ''} ${application.address ?? ''}',
              ),
            if (application.zip != null) _buildInfoRow('郵遞區號', application.zip!),
            _buildInfoRow(
              '配送方式',
              _getDeliveryTypeText(application.deliveryType),
            ),
            if (application.telDay != null)
              _buildInfoRow('日間電話', application.telDay!),
            if (application.telNight != null)
              _buildInfoRow('夜間電話', application.telNight!),
            if (application.sprodAskNo != null)
              _buildInfoRow('詢問單號', application.sprodAskNo!),
            if (application.createdAt != null)
              _buildInfoRow('申請日期', _formatDate(application.createdAt!)),
            if (application.updatedAt != null)
              _buildInfoRow('更新日期', _formatDate(application.updatedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<SecondHandBookApplicationItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '申請項目 (${items.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '此申請單沒有項目',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildItemCard(item, index + 1);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(SecondHandBookApplicationItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '項目 $index',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildItemInfoRow('商品編號', item.prodId ?? ''),
          _buildItemInfoRow('原始商品編號', item.orgProdId),
          _buildItemInfoRow('商品等級', item.prodRank.value),
          _buildItemInfoRow('商品標記', _getProductMarkText(item.prodMark)),
          _buildItemInfoRow('售價', 'NT\$ ${item.salePrice.toStringAsFixed(0)}'),
          if (item.otherMark != null && item.otherMark!.isNotEmpty)
            _buildItemInfoRow('其他備註', item.otherMark!),
        ],
      ),
    );
  }

  Widget _buildItemInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
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

  String _getProductMarkText(ProductMark mark) {
    switch (mark) {
      case ProductMark.new_:
        return '全新';
      case ProductMark.used:
        return '二手';
      case ProductMark.damaged:
        return '損壞';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
