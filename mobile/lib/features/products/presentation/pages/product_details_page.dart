import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/add_to_cart_animation.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../domain/entities/product.dart';
import '../widgets/product_card.dart';
import '../widgets/custom_cake_section.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';

/// Product page: a full-bleed photo with floating clear-glass back and
/// favourite buttons, the details on a solid card that slides up over the
/// photo, and a floating glass bar with a stepper and the "В корзину" action.
class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  static const double _cardOverlap = 32;
  static const double _bottomBarHeight = 54;

  final _pageController = PageController();
  final GlobalKey _heroKey = GlobalKey();
  final ValueNotifier<double> _offset = ValueNotifier(0);
  bool _isFavorite = false;
  int _quantity = 1;
  final _cakeWishes = CustomCakeWishes();

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(LoadProductDetails(widget.productId));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _offset.dispose();
    _cakeWishes.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/catalog');

  void _addToCart(Product product) {
    final provider = CartAnimationProvider.of(context);
    if (provider != null) {
      provider.controller.animateToCart(
        productKey: _heroKey,
        cartKey: provider.cartIconKey,
        productWidget: SizedBox(
          width: 64,
          height: 64,
          child: ProductImage(url: product.mainImage, radius: 16, iconSize: 24),
        ),
      );
    }
    final inscription = _cakeWishes.inscription.text.trim();
    final wishes = _cakeWishes.wishes.text.trim();
    context.read<CartBloc>().add(AddToCart(
          product,
          quantity: _quantity,
          inscription: product.isPreorder && inscription.isNotEmpty ? inscription : null,
          wishes: product.isPreorder && wishes.isNotEmpty ? wishes : null,
          referencePhotoUrl: product.isPreorder ? _cakeWishes.photoUrl.value : null,
        ));
    _showAddedToast(product);
    _cakeWishes.clear();
    setState(() => _quantity = 1);
  }

  /// Glass toast with an "Открыть" action, floating above the bottom bar.
  void _showAddedToast(Product product) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final bottom =
        GlassTabBarMetrics.clearance(context) - 8 + _bottomBarHeight + 10;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          content: LiquidGlass.capsule(
            style: GlassStyle.dark.copyWith(
              tint: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
            padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${product.name} × $_quantity в корзине',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    context.go('/cart');
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Открыть',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          if (state is ProductDetailsLoaded) return _buildLoaded(state.product);
          if (state is ProductDetailsError) {
            return _buildPlaceholder(_buildError(state.message));
          }
          if (state is ProductDetailsLoading) {
            return _buildPlaceholder(const LoadingWidget());
          }
          return _buildPlaceholder(const SizedBox.shrink());
        },
      ),
    );
  }

  /// Loading / error: liquid background with a back button.
  Widget _buildPlaceholder(Widget child) {
    return LiquidBackground(
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopBar(
              glassOpacity: 0,
              leading: GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 19,
                tooltip: 'Назад',
                onTap: _back,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(Product product) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final heroHeight = (media.size.height * 0.56).clamp(320.0, 560.0);
    final collapseAt =
        heroHeight - _cardOverlap - topInset - GlassTopBar.barHeight;
    final barBottom = GlassTabBarMetrics.clearance(context) - 8;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
              _offset.value = n.metrics.pixels;
            }
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // One sliver on purpose: a viewport paints earlier slivers on
              // top, so a separate card sliver would end up under the photo.
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(product, heroHeight),
                    Transform.translate(
                      offset: const Offset(0, -_cardOverlap),
                      child: _buildCard(product, barBottom),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Floating top controls; a frosted bar with the name fades in once
        // the photo has scrolled away.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _offset,
            builder: (context, offset, _) {
              final collapsed = offset > collapseAt;
              final glass = ((offset - collapseAt + 16) / 16).clamp(0.0, 1.0);
              final style = collapsed ? GlassStyle.regular : GlassStyle.clear;
              return GlassTopBar(
                title: product.name,
                titleOpacity: ((offset - collapseAt) / 24).clamp(0.0, 1.0),
                glassOpacity: glass,
                leading: GlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 19,
                  tooltip: 'Назад',
                  style: style,
                  onTap: _back,
                ),
                actions: [
                  GlassIconButton(
                    icon: _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: _isFavorite ? AppColors.primary : null,
                    tooltip: 'Избранное',
                    style: style,
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: barBottom,
          child: Row(
            children: [
              _GlassStepper(
                quantity: _quantity,
                height: _bottomBarHeight,
                onChanged: (q) => setState(() => _quantity = q.clamp(1, 99)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: product.isAvailable ? 'В корзину' : 'Нет в наличии',
                  trailing: formatPrice(product.price * _quantity),
                  prominent: true,
                  expanded: true,
                  height: _bottomBarHeight,
                  onTap: product.isAvailable ? () => _addToCart(product) : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(Product product, double height) {
    final hasPager = product.images.length > 1;
    return SizedBox(
      height: height,
      child: ValueListenableBuilder<double>(
        valueListenable: _offset,
        builder: (context, offset, child) {
          // Stretch on pull-down, gentle parallax on scroll-up.
          final top = offset < 0 ? offset : offset * 0.4;
          final extra = offset < 0 ? -offset : 0.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: top,
                left: 0,
                right: 0,
                height: height + extra,
                child: child!,
              ),
            ],
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            KeyedSubtree(
              key: _heroKey,
              child: hasPager
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: product.images.length,
                      itemBuilder: (_, i) => ProductImage(
                        url: product.images[i],
                        radius: 0,
                        iconSize: 96,
                      ),
                    )
                  : ProductImage(
                      url: product.mainImage,
                      radius: 0,
                      iconSize: 96,
                    ),
            ),
            // Soft shade under the status bar so the glass buttons read.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (hasPager)
              Positioned(
                left: 0,
                right: 0,
                bottom: _cardOverlap + 14,
                child: Center(
                  child: LiquidGlass.capsule(
                    style: GlassStyle.clear,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: product.images.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 7,
                        dotHeight: 7,
                        spacing: 5,
                        expansionFactor: 2.6,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Product product, double barBottom) {
    final hasDescription =
        product.description != null && product.description!.trim().isNotEmpty;
    final hasComposition =
        product.composition != null && product.composition!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.isNew || product.hasDiscount) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (product.isNew) const TagBadge(text: 'НОВИНКА'),
                      if (product.hasDiscount)
                        TagBadge(
                          text: '-${product.discountPercent.toInt()}%',
                          color: AppColors.textPrimary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  product.name,
                  style: AppTextStyles.heading1.copyWith(fontSize: 26, height: 1.15),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(product.price),
                      style: AppTextStyles.display.copyWith(
                        fontSize: 28,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Text(
                        formatPrice(product.oldPrice!),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.weight != null ||
                    product.calories != null ||
                    product.categoryName != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.weight != null)
                        _Pill(
                          icon: Icons.scale_rounded,
                          text: formatWeight(product.weight!),
                        ),
                      if (product.calories != null)
                        _Pill(
                          icon: Icons.local_fire_department_rounded,
                          text: '${product.calories} ккал',
                        ),
                      if (product.categoryName != null)
                        _Pill(text: product.categoryName!, muted: true),
                    ],
                  ),
                ],
                if (hasDescription) ...[
                  const SizedBox(height: 20),
                  Text(
                    product.description!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (product.isPreorder) ...[
                  const SizedBox(height: 20),
                  CustomCakeSection(product: product, wishes: _cakeWishes),
                ],
                const SizedBox(height: 20),
                if (hasComposition) ...[
                  _FactTile(
                    title: 'Состав',
                    body: product.composition!,
                    icon: Icons.format_list_bulleted_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
                const _FactTile(
                  title: 'Хранение',
                  body:
                      'В холодильнике при +2…+6 °C. Достаньте за 20 минут до подачи.',
                  icon: Icons.ac_unit_rounded,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
          _PairsWell(current: product),
          // Room for the floating bar and the tab bar (+ the card overlap).
          SizedBox(height: barBottom + _bottomBarHeight + 24 + _cardOverlap),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            GlassButton(
              label: 'Повторить',
              icon: Icons.refresh_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                context
                    .read<ProductsBloc>()
                    .add(LoadProductDetails(widget.productId));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Minus / count / plus on a glass capsule, sized to sit next to the
/// primary button.
class _GlassStepper extends StatelessWidget {
  final int quantity;
  final double height;
  final ValueChanged<int> onChanged;

  const _GlassStepper({
    required this.quantity,
    required this.height,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, bool enabled, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: SizedBox(
          width: 40,
          height: height,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.textPrimary : AppColors.textLight,
          ),
        ),
      );
    }

    return LiquidGlass.capsule(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, quantity > 1, () => onChanged(quantity - 1)),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 26),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: AppTextStyles.price,
              ),
            ),
          ),
          button(Icons.add_rounded, quantity < 99, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _FactTile({required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.bodySmall.copyWith(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool muted;

  const _Pill({required this.text, this.icon, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final fg = muted ? AppColors.textSecondary : AppColors.textPrimary;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: muted ? AppColors.surfaceMuted : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Text(text, style: AppTextStyles.label.copyWith(fontSize: 13, color: fg)),
        ],
      ),
    );
  }
}

/// "Отлично сочетается": other popular items from the home feed.
class _PairsWell extends StatelessWidget {
  final Product current;
  const _PairsWell({required this.current});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final items = [...state.popularProducts, ...state.newProducts]
            .where((p) => p.id != current.id)
            .fold<List<Product>>([], (acc, p) {
              if (!acc.any((e) => e.id == p.id)) acc.add(p);
              return acc;
            })
            .take(6)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Отлично сочетается'),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 164,
                  child: ProductCard(
                    product: items[i],
                    onTap: () => context.push('/product/${items[i].id}'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
