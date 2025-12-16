import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/book.dart';
import '../providers/cart_provider.dart';
import '../providers/ai_chat_provider.dart';
import 'ai_chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/cached_image_widget.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '書籍詳情', showBackButton: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 書籍封面和基本資訊
            _buildBookHeader(context),

            // 書籍詳細資訊
            _buildBookDetails(context),

            // AI 專區（Talk to the Book + Podcast 試聽）
            _buildAiAssistant(context),

            // 書籍描述
            _buildBookDescription(context),

            // 評論區域
            _buildReviewsSection(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBookHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 書籍封面
          BookCoverImage(
            imageUrl: book.imageUrl,
            width: 120,
            height: 160,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),

          const SizedBox(width: 16),

          // 書籍基本資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Text(
                  '作者：${book.author}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),

                Text(
                  '出版社：${book.publisher}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),

                Text(
                  '出版日期：${_formatDate(book.publishDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),

                // 評分
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${book.rating}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${book.reviewCount} 評論)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 價格
                Text(
                  'NT\$ ${book.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('書籍資訊', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          _buildDetailRow(context, 'ISBN', book.isbn),
          _buildDetailRow(context, '頁數', '${book.pages} 頁'),
          _buildDetailRow(context, '分類', book.category),
          _buildDetailRow(context, '庫存狀態', book.isAvailable ? '有庫存' : '缺貨'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildBookDescription(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('內容簡介', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            book.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistant(BuildContext context) {
    final presetQuestions = [
      '請幫我抓取《${book.title}》的大綱',
      '這本書適合哪些讀者？',
      '讀完《${book.title}》能獲得的三個重點是什麼？',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.pink),
              const SizedBox(width: 8),
              Text(
                'AI 專區',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '快速提問或開啟對話，AI 可根據本書提供摘要、讀者族群與重點收穫。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetQuestions.map((q) {
              return ActionChip(
                label: Text(q),
                onPressed: () {
                  // 發送預設問題並開啟 AI 對話畫面
                  context.read<AiChatProvider>().sendMessage(q);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiChatScreen(),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildPodcastCard(context),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiChatScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('開啟問答'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastCard(BuildContext context) {
    const samplePodcastUrl =
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.headset, color: Colors.pink, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '有聲書試聽',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '播放本書的 AI 聲音導讀，約 30 秒摘要',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _launchPodcastSample(context, samplePodcastUrl),
            icon: const Icon(Icons.play_arrow),
            label: const Text('播放試聽'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPodcastSample(
    BuildContext context,
    String url,
  ) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法開啟試聽連結')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('開啟失敗：$e')),
        );
      }
    }
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('讀者評論', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // 模擬評論
          _buildReviewItem(context, '張小明', '這本書內容豐富，講解詳細，非常適合初學者學習。', 5),
          _buildReviewItem(context, '李小華', '實用的技術書籍，推薦給想要學習的開發者。', 4),
          _buildReviewItem(context, '王小強', '書中的範例程式碼很完整，跟著做就能學會。', 5),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    BuildContext context,
    String name,
    String comment,
    int rating,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              ...List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 收藏按鈕
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已加入收藏')));
              },
              icon: const Icon(FontAwesomeIcons.heart),
              label: const Text('收藏'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 加入購物車按鈕
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: book.isAvailable
                  ? () {
                      context.read<CartProvider>().addToCart(book);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已將《${book.title}》加入購物車'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(FontAwesomeIcons.cartPlus),
              label: Text(book.isAvailable ? '加入購物車' : '缺貨'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: book.isAvailable
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
