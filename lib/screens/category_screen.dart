import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/product_category.dart';
import '../providers/cart_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_app_bar.dart';
import 'book_detail_screen.dart';
import 'book_list_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String? initialCategoryName;
  
  const CategoryScreen({super.key, this.initialCategoryName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // Track which level 1 categories are expanded
  final Set<String> _expandedCategories = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    // Expand the initial category if provided
    if (widget.initialCategoryName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _expandInitialCategory();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _expandInitialCategory() {
    final bookProvider = context.read<BookProvider>();
    final levelOneCategories = bookProvider.productCategories
        .where((category) => category.level == 1)
        .toList();
    
    // Find the category by name and expand it
    for (int index = 0; index < levelOneCategories.length; index++) {
      final category = levelOneCategories[index];
      if (category.name == widget.initialCategoryName) {
        setState(() {
          _expandedCategories.add(category.id);
        });
        // Scroll to the expanded category after it's rendered
        // First scroll to approximate position, then fine-tune with ensureVisible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCategoryByIndex(index, category.id);
        });
        break;
      }
    }
  }

  void _scrollToCategoryByIndex(int index, String categoryId) {
    if (!_scrollController.hasClients) {
      // If scroll controller isn't ready, wait and retry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCategoryByIndex(index, categoryId);
      });
      return;
    }

    // Check if the item is already in viewport
    final currentPosition = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;
    
    // Use a more conservative estimate for item height (just the header, not expanded content)
    // This prevents overscrolling - we'll let ensureVisible do the fine-tuning
    const double estimatedItemHeight = 80.0; // Just header height estimate
    final double targetOffset = index * estimatedItemHeight;
    
    // Check if item is likely already visible
    final itemStart = targetOffset;
    final itemEnd = targetOffset + estimatedItemHeight;
    final viewportStart = currentPosition;
    final viewportEnd = currentPosition + viewportHeight;
    
    // If item is already in viewport, just use ensureVisible
    if (itemStart >= viewportStart && itemEnd <= viewportEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureCategoryVisible(categoryId, retries: 5);
      });
      return;
    }
    
    // For items outside viewport, scroll to approximate position first
    // Use a more conservative offset (don't subtract padding to avoid overscrolling)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final scrollOffset = targetOffset.clamp(0.0, maxScroll);
    
    // Scroll to approximate position (this will cause ListView to render items in that area)
    // Use a shorter duration and less aggressive scroll
    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ).then((_) {
      // Wait for the widget to be rendered after scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Now try to ensure the category is visible
          _ensureCategoryVisible(categoryId, retries: 5);
        });
      });
    });
  }

  void _ensureCategoryVisible(String categoryId, {int retries = 5}) {
    final key = _categoryKeys[categoryId];
    if (key?.currentContext != null) {
      try {
        final context = key!.currentContext!;
        if (context.mounted) {
          // Use alignment 0.0 to position at the top
          // This prevents overscrolling while still showing the category clearly
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.0, // Position at the top of viewport
          );
          return; // Success, no need to retry
        }
      } catch (e) {
        // If it fails, we'll retry below
      }
    }
    
    // If context is not available yet or ensureVisible failed, retry after a delay
    if (retries > 0) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _ensureCategoryVisible(categoryId, retries: retries - 1);
      });
    }
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '分類', showBackButton: true),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, child) {
          if (bookProvider.isLoading) {
            return const Center(child: LoadingWidget());
          }

          // Get only level 1 categories
          final levelOneCategories = bookProvider.productCategories
              .where((category) => category.level == 1)
              .toList();

          if (levelOneCategories.isEmpty) {
            return const Center(
              child: Text('暫無分類資料'),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: levelOneCategories.length,
            itemBuilder: (context, index) {
              final category = levelOneCategories[index];
              final isExpanded = _expandedCategories.contains(category.id);
              final hasChildren = category.children != null && category.children!.isNotEmpty;

              // Create a key for this category if it doesn't exist
              if (!_categoryKeys.containsKey(category.id)) {
                _categoryKeys[category.id] = GlobalKey();
              }

              return Container(
                key: _categoryKeys[category.id],
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分類標題 (clickable)
                    InkWell(
                      onTap: hasChildren ? () => _toggleCategory(category.id) : null,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
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
                              ProductCategory.getIcon(category.name),
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            if (hasChildren)
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Level 2 categories (shown when expanded)
                    if (isExpanded && hasChildren)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: category.children!.map((childCategory) {
                            final books = bookProvider.getBooksByCategory(childCategory.name);
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
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookListScreen(
                                            title: childCategory.name,
                                            category: childCategory.name,
                                            categoryId: childCategory.id,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              childCategory.name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (books.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    GridView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 0.6,
                                          ),
                                      itemCount: books.length,
                                      itemBuilder: (context, bookIndex) {
                                        final book = books[bookIndex];
                                        return BookCard(
                                          book: book,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BookDetailScreen(book: book),
                                              ),
                                            );
                                          },
                                          onAddToCart: () {
                                            context.read<CartProvider>().addToCart(book);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('已將《${book.title}》加入購物車'),
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
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
}
