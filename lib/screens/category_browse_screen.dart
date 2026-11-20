import 'dart:ui' show PathMetric;

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

  /// 業種：11 中文書、14 中文電子書、25 中文電子雜誌
  final String prodCatId;
  final String title;

  const CategoryBrowseScreen({
    super.key,
    this.initialCategoryName,
    this.initialCategoryId,
    this.prodCatId = '11',
    this.title = '分類',
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<BookProvider>();
      await provider.loadCategories(prodCatId: widget.prodCatId);
      if (!mounted) return;
      _applyInitialSelection();
    });
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    super.dispose();
  }

  List<ProductCategory> _levelOne(BookProvider bookProvider) {
    return bookProvider.levelOneCategoryTreeFor(widget.prodCatId);
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

  void _openCategory(ProductCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookListScreen(
          title: category.name,
          category: category.name,
          categoryId: category.id,
          prodCatId: widget.prodCatId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(title: widget.title, showBackButton: true),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          final levelOne = _levelOne(bookProvider);
          if ((bookProvider.isLoadingCategories || bookProvider.isLoading) &&
              levelOne.isEmpty) {
            return const Center(child: LoadingWidget());
          }

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
              _buildLeftPane(levelOne: levelOne, selected: selected, primary: primary),
              Expanded(
                child: _buildRightPane(
                  selected: selected,
                  children: children,
                  primary: primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftPane({
    required List<ProductCategory> levelOne,
    required ProductCategory selected,
    required Color primary,
  }) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.32,
      child: ColoredBox(
        color: Colors.white,
        child: ListView.builder(
          controller: _leftScrollController,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
          itemCount: levelOne.length,
          itemBuilder: (context, index) {
            final cat = levelOne[index];
            final isSelected = cat.id == selected.id;
            _leftKeys.putIfAbsent(cat.id, () => GlobalKey());

            return KeyedSubtree(
              key: _leftKeys[cat.id],
              child: Padding(
                // 選中膠囊略向右伸出，蓋住右欄一點
                padding: EdgeInsets.fromLTRB(
                  8,
                  3,
                  isSelected ? 0 : 10,
                  3,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => _selectedId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.25,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? primary
                                    : Colors.grey[850],
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRightPane({
    required ProductCategory selected,
    required List<ProductCategory> children,
    required Color primary,
  }) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 12, 12, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
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
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BrowseAllChip(
                    primary: primary,
                    onTap: () => _openCategory(selected),
                  ),
                ),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _TwoColumnLinks(
                    items: children,
                    primary: primary,
                    onTap: _openCategory,
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Text(
                    '此分類尚無子分類，可直接瀏覽全部',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseAllChip extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;

  const _BrowseAllChip({
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.7)),
          ),
          child: Text(
            '瀏覽全部',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoColumnLinks extends StatelessWidget {
  final List<ProductCategory> items;
  final Color primary;
  final ValueChanged<ProductCategory> onTap;

  const _TwoColumnLinks({
    required this.items,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = <ProductCategory>[];
    final right = <ProductCategory>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        left.add(items[i]);
      } else {
        right.add(items[i]);
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _column(left)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: primary.withValues(alpha: 0.35),
              ),
              child: const SizedBox(width: 1),
            ),
          ),
          Expanded(child: _column(right)),
        ],
      ),
    );
  }

  Widget _column(List<ProductCategory> columnItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in columnItems)
          Material(
            type: MaterialType.transparency,
            // 避免 InkWell/Material 裁掉 CJK 首字左緣（「中」最明顯）
            clipBehavior: Clip.none,
            child: InkWell(
              onTap: () => onTap(item),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 11, 4, 11),
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dash = 4.0;
    const gap = 3.0;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height);

    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
