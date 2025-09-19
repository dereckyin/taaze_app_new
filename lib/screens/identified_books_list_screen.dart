import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_listing_wizard_provider.dart';
import '../models/identified_book.dart';

class IdentifiedBooksListScreen extends StatelessWidget {
  const IdentifiedBooksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AiListingWizardProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.identifiedBooks.length,
          itemBuilder: (context, index) {
            final book = provider.identifiedBooks[index];
            return _buildBookCard(context, book, index);
          },
        );
      },
    );
  }

  Widget _buildBookCard(BuildContext context, IdentifiedBook book, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題行
            Row(
              children: [
                // 勾選框
                Checkbox(
                  value: book.isSelected,
                  onChanged: (value) {
                    context.read<AiListingWizardProvider>().toggleBookSelection(
                      index,
                    );
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),

                // 書籍圖片
                _buildBookImage(book),

                const SizedBox(width: 12),

                // 書籍信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.titleMain,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.qr_code, 'ISBN', book.isbnDisplay),
                      _buildInfoRow(
                        Icons.inventory,
                        '商品ID',
                        book.prodIdDisplay,
                      ),
                      _buildInfoRow(Icons.star, '書況', book.condition),
                    ],
                  ),
                ),
              ],
            ),

            // 如果已選中，顯示編輯區域
            if (book.isSelected) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // 備註輸入
              TextField(
                decoration: const InputDecoration(
                  labelText: '備註',
                  hintText: '請輸入備註（選填）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 2,
                onChanged: (value) {
                  context.read<AiListingWizardProvider>().updateBookNotes(
                    index,
                    value,
                  );
                },
              ),

              const SizedBox(height: 12),

              // 賣價輸入
              TextField(
                decoration: const InputDecoration(
                  labelText: '賣價',
                  hintText: '請輸入賣價',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  prefixText: 'NT\$ ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  context
                      .read<AiListingWizardProvider>()
                      .updateBookSellingPrice(index, price);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage(IdentifiedBook book) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: book.imageUrl != null
            ? Image.network(
                book.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage();
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.book, color: Colors.grey, size: 30),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
