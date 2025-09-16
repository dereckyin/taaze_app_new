import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/book.dart';
import 'cached_image_widget.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showAddToCartButton;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onAddToCart,
    this.showAddToCartButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 書籍封面
            AspectRatio(
              aspectRatio: 0.8, // 增加高度比例，讓圖片更寬一些
              child: BookCoverImage(
                imageUrl: book.imageUrl,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),

            // 書籍資訊
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(2), // 進一步減少padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 書名
                    Text(
                      book.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 1), // 減少間距
                    // 作者
                    Text(
                      book.author,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 1), // 減少間距
                    // 評分
                    Row(
                      children: [
                        const Icon(Icons.star, size: 7, color: Colors.amber),
                        const SizedBox(width: 1),
                        Text(
                          book.rating.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 8),
                        ),
                        const SizedBox(width: 1),
                        Expanded(
                          child: Text(
                            '(${book.reviewCount})',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 8,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 1), // 減少間距
                    // 價格和按鈕
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'NT\$ ${book.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showAddToCartButton)
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: IconButton(
                              onPressed: onAddToCart,
                              icon: const Icon(
                                FontAwesomeIcons.cartPlus,
                                size: 5,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(18, 18),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showAddToCartButton;

  const BookListTile({
    super.key,
    required this.book,
    this.onTap,
    this.onAddToCart,
    this.showAddToCartButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: BookCoverImage(
          imageUrl: book.imageUrl,
          width: 60,
          height: 80,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          book.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              book.author,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${book.rating} (${book.reviewCount})',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'NT\$ ${book.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: showAddToCartButton
            ? IconButton(
                onPressed: onAddToCart,
                icon: const Icon(FontAwesomeIcons.cartPlus, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}

/// 帶排行數字的書籍卡片，專用於暢銷排行榜
class RankedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showAddToCartButton;
  final int? rank; // 排行數字，如果為null則使用book.rank

  const RankedBookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onAddToCart,
    this.showAddToCartButton = true,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final displayRank = rank; // 直接使用傳入的rank參數

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 書籍封面（帶排行數字）
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 0.8,
                  child: BookCoverImage(
                    imageUrl: book.imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                // 排行數字標籤
                if (displayRank != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRankColor(displayRank),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$displayRank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 書籍資訊
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 書名
                    Text(
                      book.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontSize: 9),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 1),
                    // 作者
                    Text(
                      book.author,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 7),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 1),
                    // 評分
                    Row(
                      children: [
                        const Icon(Icons.star, size: 7, color: Colors.amber),
                        const SizedBox(width: 1),
                        Expanded(
                          child: Text(
                            '${book.rating} (${book.reviewCount})',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 6),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 1),
                    // 價格
                    Text(
                      'NT\$ ${book.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 8,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),
                    // 加入購物車按鈕
                    if (showAddToCartButton)
                      SizedBox(
                        width: double.infinity,
                        height: 20,
                        child: IconButton(
                          onPressed: onAddToCart,
                          icon: const Icon(FontAwesomeIcons.cartPlus, size: 8),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(1),
                            minimumSize: const Size(0, 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根據排行獲取對應的顏色
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!; // 金色
      case 2:
        return Colors.grey[600]!; // 銀色
      case 3:
        return Colors.brown[600]!; // 銅色
      default:
        return Colors.blue[600]!; // 藍色
    }
  }
}
