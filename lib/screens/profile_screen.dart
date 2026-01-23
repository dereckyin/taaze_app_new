import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'order_list_screen.dart';
import 'watchlist_screen.dart';
import 'draft_list_screen.dart';
import 'second_hand_application_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '個人資料',
        showBackButton: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) {
            return _buildNotLoggedInState(context);
          }

          final user = authProvider.user!;
          return _buildProfileContent(context, user);
        },
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
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
              '登入後即可查看個人資料和訂單',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('立即登入'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 用戶頭像和基本資訊
          _buildUserHeader(context, user),
          
          // 功能選單
          _buildMenuSection(context),
          
          // 登出按鈕
          _buildLogoutSection(context),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 頭像
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 姓名
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 電子郵件
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // // 註冊日期
          // Text(
          //   '註冊於 ${_formatDate(user.createdAt)}',
          //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //     color: Colors.grey[500],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.shopping_bag_outlined,
            title: '我的訂單',
            subtitle: '查看訂單狀態',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderListScreen(),
                ),
              );
            },
          ),
          
          _buildMenuItem(
            context,
            icon: Icons.favorite_outline,
            title: '我的暫存',
            subtitle: '查看暫存的書籍',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WatchlistScreen(),
                ),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.list_alt,
            title: '上架草稿',
            subtitle: '查看上架草稿列表',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DraftListScreen(),
                ),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.list_alt,
            title: '二手書申請紀錄',
            subtitle: '查看二手書申請紀錄列表',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecondHandApplicationListScreen(),
                ),
              );
            },
          ),
          
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: '關於我們',
            subtitle: '應用程式資訊',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: ListTile(
          leading: const Icon(
            Icons.logout,
            color: Colors.red,
          ),
          title: const Text(
            '登出',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () {
            _showLogoutDialog(context);
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認登出'),
        content: const Text('您確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('登出'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '讀冊新生活',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.book,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Text('TAAZE讀冊生活網路書店'),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
