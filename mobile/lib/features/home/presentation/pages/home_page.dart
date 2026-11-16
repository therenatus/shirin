import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../loyalty/domain/entities/punch_card.dart';
import '../../../loyalty/presentation/bloc/punch_cards_bloc.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/stories_widget.dart';
import 'story_viewer_page.dart';

/// Home: a full-bleed photo hero that melts into the liquid background,
/// glass category chips, stories, products on content cards, the loyalty
/// card and promos. A frosted top bar fades in once the hero scrolls away.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> _viewedStories = {};

  static const _stories = [
    Story(
      id: 'promo',
      title: 'Акции',
      previewImage:
          'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&q=80',
      slides: [
        StorySlide(
          imageUrl:
              'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=800&q=80',
          title: 'Скидка 20%',
          subtitle: 'На все торты до конца месяца',
          buttonText: 'Смотреть торты',
        ),
        StorySlide(
          imageUrl:
              'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
          title: 'Бесплатная доставка',
          subtitle: 'При заказе от 1000 сом',
        ),
      ],
    ),
    Story(
      id: 'new',
      title: 'Новинки',
      previewImage:
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200&q=80',
      slides: [
        StorySlide(
          imageUrl:
              'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
          title: 'Новый чизкейк',
          subtitle: 'Попробуйте малиновый чизкейк',
          buttonText: 'Заказать',
        ),
      ],
    ),
    Story(
      id: 'hits',
      title: 'Хиты',
      previewImage:
          'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=200&q=80',
      slides: [
        StorySlide(
          imageUrl:
              'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80',
          title: 'Топ продаж',
          subtitle: 'Наполеон — самый популярный торт',
        ),
      ],
    ),
    Story(
      id: 'coffee',
      title: 'Кофе',
      previewImage:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&q=80',
      slides: [
        StorySlide(
          imageUrl:
              'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80',
          title: '7-й кофе бесплатно',
          subtitle: 'Собирайте штампы и получайте кофе в подарок',
          buttonText: 'К напиткам',
        ),
      ],
    ),
    Story(
      id: 'custom',
      title: 'На заказ',
      previewImage:
          'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=200&q=80',
      slides: [
        StorySlide(
          imageUrl:
              'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=800&q=80',
          title: 'Торт к празднику',
          subtitle: 'Соберём по вашему вкусу, готовность за 2 дня',
          buttonText: 'Выбрать',
        ),
      ],
    ),
  ];

  List<Story> _storiesWithState() => _stories
      .map(
        (s) => Story(
          id: s.id,
          title: s.title,
          previewImage: s.previewImage,
          slides: s.slides,
          isViewed: _viewedStories.contains(s.id),
        ),
      )
      .toList();

  void _openStory(int index) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => StoryViewerPage(
          stories: _storiesWithState(),
          initialStoryIndex: index,
          onStoryViewed: (id) => setState(() => _viewedStories.add(id)),
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  static const _promos = [
    _Promo(
      eyebrow: 'Акция',
      title: 'Скидка 20% на торты',
      subtitle: 'До конца месяца',
      color: AppColors.primarySoft,
      image:
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80',
    ),
    _Promo(
      eyebrow: 'Новинка',
      title: 'Эклеры: 6 вкусов',
      subtitle: 'Фисташка, малина, солёная карамель',
      color: AppColors.cardYellow,
      image:
          'https://images.unsplash.com/photo-1550617931-e17a7b70dce2?w=400&q=80',
    ),
    _Promo(
      eyebrow: 'Доставка',
      title: 'Бесплатно от 1000 с',
      subtitle: 'По всему городу',
      color: AppColors.cardTeal,
      image:
          'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=400&q=80',
    ),
  ];


  final ValueNotifier<double> _offset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const LoadHomeData());
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading || state is HomeInitial) {
              return const LoadingWidget();
            }
            if (state is HomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: AppColors.textLight),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      GlassButton(
                        label: 'Повторить',
                        icon: Icons.refresh_rounded,
                        onTap: () =>
                            context.read<HomeBloc>().add(const LoadHomeData()),
                      ),
                    ],
                  ),
                ),
              );
            }
            return _buildLoaded(state as HomeLoaded);
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(HomeLoaded state) {
    final featured = <Product>[
      ...state.newProducts,
      ...state.popularProducts.where((p) => !state.newProducts.contains(p)),
    ].where((p) => p.mainImage.isNotEmpty).take(5).toList();
    final popular = state.popularProducts.take(8).toList();
    final fresh = state.newProducts.take(6).toList();
    final media = MediaQuery.of(context);
    final heroHeight = (media.size.height * 0.56).clamp(340.0, 560.0);
    final collapseAt = heroHeight - media.padding.top - GlassTopBar.barHeight - 40;

    const gap = SliverToBoxAdapter(child: SizedBox(height: 28));
    const headerGap = SliverToBoxAdapter(child: SizedBox(height: 12));

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
              _offset.value = n.metrics.pixels;
            }
            return false;
          },
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Colors.white,
            edgeOffset: media.padding.top,
            onRefresh: () async =>
                context.read<HomeBloc>().add(const LoadHomeData()),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(products: featured, height: heroHeight),
                ),
                SliverToBoxAdapter(
                  child: _CategoryChips(
                    categories: state.categories,
                    onTap: (c) => context.push('/catalog/${c.id}', extra: c.name),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: StoriesWidget(
                    stories: _storiesWithState(),
                    onStoryTap: _openStory,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                if (popular.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Популярное',
                      actionLabel: 'Всё меню',
                      onAction: () => context.go('/catalog'),
                    ),
                  ),
                  headerGap,
                  SliverToBoxAdapter(child: _ProductRow(products: popular)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CustomCakeBanner(
                      onTap: () {
                        final cakes = state.categories.where(
                          (c) => c.name.toLowerCase().contains('торт'),
                        );
                        if (cakes.isNotEmpty) {
                          context.push(
                            '/catalog/${cakes.first.id}',
                            extra: cakes.first.name,
                          );
                        } else {
                          context.go('/catalog');
                        }
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _LoyaltyCard(onTap: () => context.push('/loyalty')),
                  ),
                ),
                gap,
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Сейчас у нас',
                    actionLabel: 'Все акции',
                    onAction: () => context.push('/promotions'),
                  ),
                ),
                headerGap,
                SliverToBoxAdapter(child: _PromoCarousel(promos: _promos)),
                gap,
                if (fresh.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Новинки',
                      actionLabel: 'Все',
                      onAction: () => context.go('/catalog'),
                    ),
                  ),
                  headerGap,
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: ProductCard.gridAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCard(
                          product: fresh[i],
                          onTap: () => context.push('/product/${fresh[i].id}'),
                        ),
                        childCount: fresh.length,
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(height: GlassTabBarMetrics.clearance(context) + 8),
                ),
              ],
            ),
          ),
        ),
        // Frosted bar with the brand name fades in once the hero is gone.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (context, offset, _) => GlassTopBar(
                title: 'Ширин',
                titleOpacity: ((offset - collapseAt) / 24).clamp(0.0, 1.0),
                glassOpacity: ((offset - collapseAt + 16) / 16).clamp(0.0, 1.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-bleed product photos that auto-advance, with the name and price
/// sitting on the fade into the page and glass segment indicators.
class _Hero extends StatefulWidget {
  final List<Product> products;
  final double height;

  const _Hero({required this.products, required this.height});

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(seconds: 5);
  final _controller = PageController();
  late final AnimationController _progress;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _slideDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    if (widget.products.length > 1) _progress.forward();
  }

  void _next() {
    if (!mounted || widget.products.length < 2) return;
    final next = (_index + 1) % widget.products.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    if (widget.products.length > 1) _progress.forward(from: 0);
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    final topInset = MediaQuery.paddingOf(context).top;
    const bg = AppColors.background;

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (products.isEmpty)
            Container(color: AppColors.productTile)
          else
            PageView.builder(
              controller: _controller,
              itemCount: products.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => context.push('/product/${products[i].id}'),
                child: ProductImage(
                  url: products[i].mainImage,
                  radius: 0,
                  iconSize: 96,
                ),
              ),
            ),
          // Shade under the status bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + 80,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Long, soft fade into the page (no visible band).
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.42, 0.54, 0.64, 0.74, 0.84, 0.93, 1.0],
                    colors: [
                      bg.withValues(alpha: 0),
                      bg.withValues(alpha: 0),
                      bg.withValues(alpha: 0.06),
                      bg.withValues(alpha: 0.22),
                      bg.withValues(alpha: 0.48),
                      bg.withValues(alpha: 0.76),
                      bg.withValues(alpha: 0.94),
                      bg,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Caption
          if (products.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        key: ValueKey(_index),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (products[_index].isNew)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: TagBadge(text: 'НОВИНКА'),
                            ),
                          Text(
                            products[_index].name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading1.copyWith(fontSize: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatPrice(products[_index].price),
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (products.length > 1) ...[
                      const SizedBox(height: 14),
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < products.length; i++) ...[
                              SizedBox(
                                width: 28,
                                child: _Segment(
                                  value: i < _index
                                      ? 1
                                      : i == _index
                                          ? _progress.value
                                          : 0,
                                ),
                              ),
                              if (i < products.length - 1)
                                const SizedBox(width: 5),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final double value;
  const _Segment({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.textPrimary.withValues(alpha: 0.12),
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
    );
  }
}

/// Glass category chips under the hero. "Для вас" is the current feed.
class _CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onTap;

  const _CategoryChips({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          GlassChip(
            label: 'Для вас',
            icon: Icons.auto_awesome_rounded,
            selected: true,
            onTap: () {},
          ),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            GlassChip(label: c.name, onTap: () => onTap(c)),
          ],
        ],
      ),
    );
  }
}

/// One wide loyalty card: QR tile, bonus balance and coffee stamps in a row.
class _LoyaltyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LoyaltyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PunchCardsBloc>()..add(const LoadPunchCards()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, auth) {
          final user = auth is Authenticated ? auth.user : null;
          final points = user?.loyaltyPoints ?? 0;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.textPrimary, AppColors.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: QrImageView(
                          data: user?.qrCode ?? 'SHIRIN',
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.textPrimary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'КАРТА ШИРИН',
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$points',
                                  style: AppTextStyles.heading1.copyWith(
                                    color: Colors.white,
                                    height: 1,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      _pluralPoints(points),
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            BlocBuilder<PunchCardsBloc, PunchCardsState>(
                              builder: (context, state) {
                                final cards = state is PunchCardsLoaded
                                    ? state.punchCards
                                    : const <PunchCard>[];
                                final best = cards.isEmpty
                                    ? null
                                    : cards.reduce(
                                        (a, b) =>
                                            a.currentPunches >= b.currentPunches
                                                ? a
                                                : b,
                                      );
                                final current = best?.currentPunches ?? 0;
                                final max = best?.maxPunches ?? 6;
                                return Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    Icon(
                                      Icons.local_cafe_rounded,
                                      size: 16,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 2),
                                    for (var i = 0; i < max; i++)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: i < current
                                              ? AppColors.primaryLight
                                              : Colors.white.withValues(
                                                  alpha: 0.22,
                                                ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$current/$max',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _pluralPoints(int n) {
    final r10 = n % 10, r100 = n % 100;
    if (r10 == 1 && r100 != 11) return 'балл';
    if (r10 >= 2 && r10 <= 4 && (r100 < 12 || r100 > 14)) return 'балла';
    return 'баллов';
  }
}

/// The signature service of a confectionery: cakes made to order.
class _CustomCakeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _CustomCakeBanner({required this.onTap});

  /// Vanilla accent from the category palette.
  static Color get _accent => AppColors.categoryIconColors[5];

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      onTap: onTap,
      color: AppColors.cardYellow,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 0,
            bottom: 0,
            child: Icon(
              Icons.cake_rounded,
              size: 64,
              color: _accent.withValues(alpha: 0.85),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 110, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ТОРТ НА ЗАКАЗ',
                  style: AppTextStyles.overline.copyWith(color: _accent),
                ),
                const SizedBox(height: 6),
                Text(
                  'Соберём торт к вашему празднику',
                  style: AppTextStyles.heading3.copyWith(height: 1.2),
                ),
                const SizedBox(height: 4),
                Text('От 1 кг, готовность за 2 дня', style: AppTextStyles.caption),
                const SizedBox(height: 12),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Выбрать торт',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 15, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Promo {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color color;
  final String image;

  const _Promo({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.image,
  });
}

class _PromoCarousel extends StatelessWidget {
  final List<_Promo> promos;
  const _PromoCarousel({required this.promos});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 56).clamp(240.0, 320.0);
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: promos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = promos[i];
          return SizedBox(
            width: width,
            child: ContentCard(
              onTap: () => context.go('/catalog'),
              color: p.color,
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.eyebrow.toUpperCase(),
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading3.copyWith(fontSize: 19),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 112,
                      height: double.infinity,
                      child: ProductImage(
                        url: p.image,
                        radius: 16,
                        tileColor: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final List<Product> products;
  const _ProductRow({required this.products});

  @override
  Widget build(BuildContext context) {
    // Card height follows the grid ratio (+12 bottom padding for the shadow).
    return SizedBox(
      height: 164 / ProductCard.gridAspectRatio + 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 164,
          child: ProductCard(
            product: products[i],
            onTap: () => context.push('/product/${products[i].id}'),
          ),
        ),
      ),
    );
  }
}
