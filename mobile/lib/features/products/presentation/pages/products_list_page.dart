import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../domain/entities/category.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_card.dart';

class ProductsListPage extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const ProductsListPage({super.key, this.categoryId, this.categoryName});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  List<Category> _categories = [];
  bool _showCategories = true;

  // Category styles with images like home page
  static const List<_CategoryStyle> _categoryStyles = [
    _CategoryStyle(
      color: Color(0xFFCCE5E0),  // Teal
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80',
    ),
    _CategoryStyle(
      color: Color(0xFFF5D5E0),  // Pink
      imageUrl: 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=400&q=80',
    ),
    _CategoryStyle(
      color: Color(0xFFE8F5E9),  // Mint
      imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80',
    ),
    _CategoryStyle(
      color: Color(0xFFF3E5F5),  // Lavender
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80',
    ),
    _CategoryStyle(
      color: Color(0xFFD0E8E8),  // Turquoise
      imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&q=80',
    ),
    _CategoryStyle(
      color: Color(0xFFFFF0D5),  // Yellow/Orange
      imageUrl: 'https://images.unsplash.com/photo-1481391319762-47dff72954d9?w=400&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _showCategories = widget.categoryId == null;
    context.read<ProductsBloc>().add(LoadProducts(categoryId: widget.categoryId));
    context.read<ProductsBloc>().add(const LoadCategories());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductsBloc>().add(const LoadMoreProducts());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _showCategories = query.isEmpty && widget.categoryId == null);
    context.read<ProductsBloc>().add(LoadProducts(
          search: query.isNotEmpty ? query : null,
          categoryId: widget.categoryId,
        ));
  }

  void _showFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(categories: _categories),
    );
    if (result != null && mounted) {
      context.read<ProductsBloc>().add(LoadProducts(
            categoryId: result['categoryId'] as String?,
            sortBy: result['sortBy'] as String?,
            isNew: result['isNew'] as bool?,
            minPrice: result['minPrice'] as double?,
            maxPrice: result['maxPrice'] as double?,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Content
            Expanded(
              child: BlocConsumer<ProductsBloc, ProductsState>(
                listener: (context, state) {
                  if (state is CategoriesLoaded) {
                    _categories = state.categories;
                  }
                },
                builder: (context, state) {
                  if (state is ProductsLoading && _categories.isEmpty) {
                    return const LoadingWidget();
                  }

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Categories Grid (only when no category selected)
                      if (_showCategories && _categories.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildCategoriesGrid(),
                        ),

                      // Products Grid
                      if (state is ProductsLoaded) ...[
                        if (!_showCategories || state.products.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.68,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= state.products.length) {
                                    return const Center(
                                        child: LoadingWidget(size: 24));
                                  }
                                  final product = state.products[index];
                                  return ProductCard(
                                    product: product,
                                    onTap: () =>
                                        context.push('/product/${product.id}'),
                                    onAddToCart: () {
                                      context
                                          .read<CartBloc>()
                                          .add(AddToCart(product));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${product.name} добавлен в корзину',
                                            style: GoogleFonts.nunito(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          duration:
                                              const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: state.products.length +
                                    (state.hasReachedMax ? 0 : 1),
                              ),
                            ),
                          ),
                      ] else if (state is ProductsError)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(state.message,
                                    style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => context
                                      .read<ProductsBloc>()
                                      .add(LoadProducts(
                                          categoryId: widget.categoryId)),
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Bottom padding for nav bar
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (widget.categoryId != null)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          Expanded(
            child: Text(
              widget.categoryName ?? 'Каталог',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Filter button
          _buildHeaderButton(
            icon: Icons.tune_rounded,
            onTap: _showFilters,
          ),
          const SizedBox(width: 10),
          // Favorites button
          _buildHeaderButton(
            icon: Icons.favorite_rounded,
            isPrimary: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearch,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Я ищу...',
            hintStyle: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.textLight,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textLight,
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              if (_categories.isNotEmpty)
                Expanded(child: _buildCategoryCard(_categories[0], 0)),
              const SizedBox(width: 12),
              if (_categories.length > 1)
                Expanded(child: _buildCategoryCard(_categories[1], 1)),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2
          if (_categories.length > 2)
            Row(
              children: [
                Expanded(child: _buildCategoryCard(_categories[2], 2)),
                const SizedBox(width: 12),
                if (_categories.length > 3)
                  Expanded(child: _buildCategoryCard(_categories[3], 3)),
              ],
            ),
          if (_categories.length > 2) const SizedBox(height: 12),
          // Row 3
          if (_categories.length > 4)
            Row(
              children: [
                Expanded(child: _buildCategoryCard(_categories[4], 4)),
                const SizedBox(width: 12),
                if (_categories.length > 5)
                  Expanded(child: _buildCategoryCard(_categories[5], 5)),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    final style = _categoryStyles[index % _categoryStyles.length];

    return GestureDetector(
      onTap: () {
        context.push('/catalog/${category.id}', extra: category.name);
      },
      child: Container(
        height: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full card image
            Image.network(
              style.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: style.color,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: style.color,
                  child: Icon(
                    Icons.cake_rounded,
                    size: 50,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
            // Category name
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Text(
                category.name,
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStyle {
  final Color color;
  final String imageUrl;

  const _CategoryStyle({
    required this.color,
    required this.imageUrl,
  });
}
