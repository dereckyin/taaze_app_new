import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/book.dart';

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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 0.8, // 增加高度比例，讓圖片更寬一些
                child: CachedNetworkImage(
                  imageUrl: book.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.book, size: 50, color: Colors.grey),
                  ),
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
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 80,
            child: CachedNetworkImage(
              imageUrl: book.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.book, color: Colors.grey),
              ),
            ),
          ),
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
