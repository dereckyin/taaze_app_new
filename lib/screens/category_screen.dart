import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/book_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_app_bar.dart';
import 'book_detail_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '分類',
        showBackButton: true,
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          if (bookProvider.isLoading) {
            return const Center(child: LoadingWidget());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookProvider.categories.length,
            itemBuilder: (context, index) {
              final category = bookProvider.categories[index];
              final books = bookProvider.getBooksByCategory(category);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分類標題
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _getCategoryIcon(category),
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        Text(
                          '${books.length} 本書',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 書籍列表
                    GridView.builder(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,        // 一列 2 個
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.6,    // 調整卡片比例
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return BookCard(
                          book: book,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(book: book),
                              ),
                            );
                          },
                          onAddToCart: () {
                            context.read<CartProvider>().addToCart(book);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已將《${book.title}》加入購物車'),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        );
                      },
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '程式設計':
        return FontAwesomeIcons.code;
      case '設計':
        return FontAwesomeIcons.palette;
      case '人工智慧':
        return FontAwesomeIcons.robot;
      case '資料庫':
        return FontAwesomeIcons.database;
      case '網路安全':
        return FontAwesomeIcons.shield;
      case '雲端運算':
        return FontAwesomeIcons.cloud;
      case '區塊鏈':
        return FontAwesomeIcons.link;
      default:
        return FontAwesomeIcons.book;
    }
  }
}
