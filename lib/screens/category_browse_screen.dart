import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_category.dart';
import '../providers/book_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_widget.dart';
import 'book_list_screen.dart';

/// 博客來式左右雙欄分類：左 L1、右 L2 子分類。
class CategoryBrowseScreen extends StatefulWidget {
  final String? initialCategoryName;
  final String? initialCategoryId;

  const CategoryBrowseScreen({
    super.key,
    this.initialCategoryName,
    this.initialCategoryId,
  });

  @override
  State<CategoryBrowseScreen> createState() => _CategoryBrowseScreenState();
}

class _CategoryBrowseScreenState extends State<CategoryBrowseScreen> {
  String? _selectedId;
  final ScrollController _leftScrollController = ScrollController();
  final Map<String, GlobalKey> _leftKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialSelection());
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    super.dispose();
  }

  List<ProductCategory> _levelOne(BookProvider bookProvider) {
    return bookProvider.productCategories
        .where((c) => c.level == 1)
        .toList();
  }

  void _applyInitialSelection() {
    if (!mounted) return;
    final bookProvider = context.read<BookProvider>();
    final levelOne = _levelOne(bookProvider);
    if (levelOne.isEmpty) return;

    ProductCategory? match;
    if (widget.initialCategoryId != null &&
        widget.initialCategoryId!.isNotEmpty) {
      for (final c in levelOne) {
        if (c.id == widget.initialCategoryId) {
          match = c;
          break;
        }
      }
    }
    if (match == null &&
        widget.initialCategoryName != null &&
        widget.initialCategoryName!.isNotEmpty) {
      for (final c in levelOne) {
        if (c.name == widget.initialCategoryName) {
          match = c;
          break;
        }
      }
    }
    match ??= levelOne.first;

    setState(() => _selectedId = match!.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollLeftToSelected(match!.id);
    });
  }

  void _scrollLeftToSelected(String categoryId) {
    final key = _leftKeys[categoryId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.15,
    );
  }

  ProductCategory? _selectedCategory(List<ProductCategory> levelOne) {
    if (levelOne.isEmpty) return null;
    if (_selectedId == null) return levelOne.first;
    for (final c in levelOne) {
      if (c.id == _selectedId) return c;
    }
    return levelOne.first;
  }

  void _openChild(ProductCategory child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookListScreen(
          title: child.name,
          category: child.name,
          categoryId: child.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: const CustomAppBar(title: '分類', showBackButton: true),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          if (bookProvider.isLoading &&
              bookProvider.productCategories.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          final levelOne = _levelOne(bookProvider);
          if (levelOne.isEmpty) {
            return const Center(child: Text('暫無分類資料'));
          }

          final selected = _selectedCategory(levelOne)!;
          if (_selectedId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedId = selected.id);
            });
          }

          final children = selected.children ?? const <ProductCategory>[];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左欄：大類
              Container(
                width: MediaQuery.sizeOf(context).width * 0.34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: ListView.builder(
                  controller: _leftScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: levelOne.length,
                  itemBuilder: (context, index) {
                    final cat = levelOne[index];
                    final isSelected = cat.id == selected.id;
                    _leftKeys.putIfAbsent(cat.id, () => GlobalKey());

                    return KeyedSubtree(
                      key: _leftKeys[cat.id],
                      child: Material(
                        color: isSelected
                            ? primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedId = cat.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? primary
                                          : Colors.grey[850],
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 右欄：子分類
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFFF7F7F7),
                  child: children.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selected.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '此分類尚無子分類',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => _openChild(selected),
                                  child: const Text('直接瀏覽此分類'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        selected.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 0,
                                  crossAxisSpacing: 0,
                                  childAspectRatio: 3.2,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final child = children[index];
                                    final showDivider = index.isOdd;
                                    return InkWell(
                                      onTap: () => _openChild(child),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: showDivider
                                                ? BorderSide(
                                                    color: Colors.grey[300]!,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                            bottom: BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          color: Colors.white,
                                        ),
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          child.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[850],
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: children.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
