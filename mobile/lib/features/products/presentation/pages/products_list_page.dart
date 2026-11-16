import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/category.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_card.dart';

/// Menu: large title, glass search field, a row of glass category chips that
/// pins under the top bar, and a two-column grid of product cards.
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
  String? _selectedCategoryId;
  Timer? _debounce;
  final _chipsKey = GlobalKey();
  final _chipsPinned = ValueNotifier<bool>(false);

  /// The bloc emits category states on the same stream as product states;
  /// keep the last product list so the grid does not flicker to a spinner.
  ProductsLoaded? _lastProducts;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    context.read<ProductsBloc>().add(const LoadCategories());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _updatePinnedChips();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ProductsBloc>().add(const LoadMoreProducts());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _chipsPinned.dispose();
    super.dispose();
  }

  void _load({String? search}) {
    context.read<ProductsBloc>().add(LoadProducts(
          categoryId: _selectedCategoryId,
          search: (search ?? _searchController.text).trim().isEmpty
              ? null
              : (search ?? _searchController.text).trim(),
        ));
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load(search: value);
    });
    setState(() {});
  }

  void _selectCategory(String? id) {
    if (_selectedCategoryId == id) return;
    setState(() => _selectedCategoryId = id);
    _load();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }


  /// Shows the floating chip row once the in-content row slides under the bar.
  void _updatePinnedChips() {
    final box = _chipsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final barBottom = MediaQuery.paddingOf(context).top + GlassTopBar.barHeight;
    final pinned = top < barBottom - 4;
    if (pinned != _chipsPinned.value) _chipsPinned.value = pinned;
  }

  Future<void> _showFilters() async {
    final result = await showGlassSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => FilterBottomSheet(
        categories: _categories,
        selectedCategoryId: _selectedCategoryId,
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedCategoryId = result['categoryId'] as String?);
      context.read<ProductsBloc>().add(LoadProducts(
            categoryId: _selectedCategoryId,
            sortBy: result['sortBy'] as String?,
            isNew: result['isNew'] as bool?,
            minPrice: result['minPrice'] as double?,
            maxPrice: result['maxPrice'] as double?,
          ));
    }
  }

  String get _title {
    if (widget.categoryName != null) return widget.categoryName!;
    return 'Меню';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return BlocConsumer<ProductsBloc, ProductsState>(
      listener: (context, state) {
        if (state is CategoriesLoaded) {
          setState(() => _categories = state.categories);
        } else if (state is ProductsLoaded) {
          _lastProducts = state;
        } else if (state is ProductsLoading) {
          _lastProducts = null;
        }
      },
      builder: (context, rawState) {
        final state = (rawState is CategoriesLoaded || rawState is CategoriesLoading) &&
                _lastProducts != null
            ? _lastProducts!
            : rawState;
        return Stack(
          children: [
            GlassPage(
              title: _title,
              eyebrow: widget.categoryId == null ? 'Кондитерская Ширин' : null,
              controller: _scrollController,
              backgroundIntensity: 0.8,
              onBack: widget.categoryId != null
                  ? () => context.canPop() ? context.pop() : context.go('/catalog')
                  : null,
              actions: [
                GlassIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Фильтры',
                  onTap: _showFilters,
                ),
              ],
              onRefresh: () async => _load(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: GlassTextField(
                      controller: _searchController,
                      hint: 'Торт, эклер, латте…',
                      icon: Icons.search_rounded,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      suffix: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.cancel_rounded,
                                    size: 20, color: AppColors.textLight),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: KeyedSubtree(
                    key: _chipsKey,
                    child: _buildCategoryChips(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ..._buildBody(state),
              ],
            ),
            // Floating copy of the chips, pinned under the top bar.
            Positioned(
              top: topInset + GlassTopBar.barHeight,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _chipsPinned,
                builder: (context, pinned, child) => IgnorePointer(
                  ignoring: !pinned,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    offset: pinned ? Offset.zero : const Offset(0, -0.3),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: pinned ? 1 : 0,
                      child: child,
                    ),
                  ),
                ),
                child: _buildCategoryChips(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          GlassChip(
            label: 'Все',
            selected: _selectedCategoryId == null,
            onTap: () => _selectCategory(null),
          ),
          for (final c in _categories) ...[
            const SizedBox(width: 8),
            GlassChip(
              label: c.name,
              selected: _selectedCategoryId == c.id,
              onTap: () => _selectCategory(c.id),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBody(ProductsState state) {
    if (state is ProductsLoaded) {
      if (state.products.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: _EmptyState(
              onReset: () {
                _searchController.clear();
                _selectCategory(null);
                _load(search: '');
              },
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: ProductCard.gridAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= state.products.length) {
                  return const Center(child: LoadingWidget(size: 24));
                }
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                );
              },
              childCount:
                  state.products.length + (state.hasReachedMax ? 0 : 1),
            ),
          ),
        ),
      ];
    }
    if (state is ProductsError) {
      return [
        SliverToBoxAdapter(
          child: _MessageState(
            icon: Icons.wifi_off_rounded,
            title: 'Не удалось загрузить меню',
            message: state.message,
            action: GlassButton(label: 'Повторить', onTap: _load),
          ),
        ),
      ];
    }
    return const [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 96),
          child: LoadingWidget(),
        ),
      ),
    ];
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return _MessageState(
      icon: Icons.search_off_rounded,
      title: 'Ничего не нашли',
      message: 'Попробуйте другое слово или сбросьте фильтры',
      action: GlassButton(label: 'Показать всё', onTap: onReset),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 56, 40, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: AppColors.textLight),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.heading3, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          action,
        ],
      ),
    );
  }
}
