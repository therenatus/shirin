import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/stories_widget.dart';
import 'story_viewer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _heroController = PageController();
  int _currentHeroIndex = 0;
  late final _autoScrollTimer = _startAutoScroll();

  // Viewed stories tracking
  final Set<String> _viewedStories = {};

  // Stories data with slides
  late final List<Story> _stories = [
    Story(
      id: 'promo',
      title: 'Акции',
      previewImage: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&q=80',
      slides: [
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=800&q=80',
          title: 'Скидка 20%',
          subtitle: 'На все торты до конца месяца',
          buttonText: 'Смотреть торты',
        ),
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
          title: 'Бесплатная доставка',
          subtitle: 'При заказе от 1000 сом',
        ),
      ],
      isViewed: _viewedStories.contains('promo'),
    ),
    Story(
      id: 'new',
      title: 'Новинки',
      previewImage: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200&q=80',
      slides: [
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
          title: 'Новый чизкейк',
          subtitle: 'Попробуйте наш новый малиновый чизкейк',
          buttonText: 'Заказать',
        ),
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80',
          title: 'Макаруны',
          subtitle: '6 новых вкусов уже в меню!',
        ),
      ],
      isViewed: _viewedStories.contains('new'),
    ),
    Story(
      id: 'hits',
      title: 'Хиты',
      previewImage: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=200&q=80',
      slides: [
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80',
          title: 'Топ продаж',
          subtitle: 'Наполеон - самый популярный торт',
        ),
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=800&q=80',
          title: 'Эклеры',
          subtitle: 'Любимые всеми эклеры с заварным кремом',
        ),
      ],
      isViewed: _viewedStories.contains('hits'),
    ),
    Story(
      id: 'desserts',
      title: 'Десерты',
      previewImage: 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=200&q=80',
      slides: [
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=800&q=80',
          title: 'Коллекция десертов',
          subtitle: 'Более 50 видов десертов',
          buttonText: 'Смотреть все',
        ),
      ],
      isViewed: _viewedStories.contains('desserts'),
    ),
    Story(
      id: 'coffee',
      title: 'Кофе',
      previewImage: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&q=80',
      slides: [
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80',
          title: 'Авторский кофе',
          subtitle: 'Попробуйте наш фирменный латте',
          buttonText: 'К напиткам',
        ),
        const StorySlide(
          imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800&q=80',
          title: '6-й кофе бесплатно',
          subtitle: 'Собирайте штампы и получайте кофе в подарок',
        ),
      ],
      isViewed: _viewedStories.contains('coffee'),
    ),
  ];

  _startAutoScroll() {
    return Stream.periodic(const Duration(seconds: 4)).listen((_) {
      if (_heroController.hasClients) {
        final nextPage = (_currentHeroIndex + 1) % 5;
        _heroController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const LoadHomeData());
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _heroController.dispose();
    super.dispose();
  }

  void _openStoryViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerPage(
            stories: _stories,
            initialStoryIndex: index,
            onStoryViewed: (storyId) {
              setState(() {
                _viewedStories.add(storyId);
              });
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const LoadingWidget();
          }
          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.read<HomeBloc>().add(const LoadHomeData()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          if (state is HomeLoaded) {
            return _buildContent(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(HomeLoaded state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section
          _buildHeroSection(state),

          // Bottom cards section
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Stories Section - MOVED TO TOP
                  _buildStoriesSection(),

                  const SizedBox(height: 20),

                  // QR and Promo Cards Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // QR Code Card
                        Expanded(
                          flex: 2,
                          child: _buildQRCard(),
                        ),
                        const SizedBox(width: 12),
                        // Promo Cards Column
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildPromoCard(
                                title: 'Соберите\nсвой напиток',
                                badge: 'Новое',
                                imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=200&q=80',
                              ),
                              const SizedBox(height: 10),
                              _buildChallengeCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Punch Cards Section (Плюс один)
                  _buildPunchCardsSection(),

                  const SizedBox(height: 24),

                  // Promo Banners
                  _buildPromoBannersSection(),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    // Rebuild stories with current viewed state
    final stories = _stories.map((s) => Story(
      id: s.id,
      title: s.title,
      previewImage: s.previewImage,
      slides: s.slides,
      isViewed: _viewedStories.contains(s.id),
    )).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Истории',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StoriesWidget(
          stories: stories,
          onStoryTap: _openStoryViewer,
        ),
      ],
    );
  }

  Widget _buildHeroSection(HomeLoaded state) {
    final featuredProducts = state.newProducts.isNotEmpty
        ? state.newProducts
        : state.popularProducts;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Stack(
        children: [
          // Full screen product image carousel
          if (featuredProducts.isNotEmpty)
            PageView.builder(
              controller: _heroController,
              itemCount: featuredProducts.length.clamp(0, 5),
              onPageChanged: (index) {
                setState(() => _currentHeroIndex = index);
              },
              itemBuilder: (context, index) {
                final product = featuredProducts[index];
                return GestureDetector(
                  onTap: () => context.push('/product/${product.id}'),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Full background image
                      product.mainImage.isNotEmpty
                          ? Image.network(
                              product.mainImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),

                      // Gradient overlay for text
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),

                      // Product info at bottom
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // New badge
                            if (product.isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Новинка',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                            // Product name
                            Text(
                              product.name,
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),

                            // Price and weight
                            Text(
                              '${product.price.toInt()} с${product.weight != null ? ' · ${product.weight!.toInt()} гр' : ''}',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            _buildPlaceholderImage(),

          // Address bar at top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAddressButton(),
                  _buildFavoritesButton(),
                ],
              ),
            ),
          ),

          // Page indicators
          if (featuredProducts.isNotEmpty)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  featuredProducts.length.clamp(0, 5),
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentHeroIndex == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentHeroIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB8A4D9),
            Color(0xFFE8C4B8),
            Color(0xFFDEB8A8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 80,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildAddressButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Адрес доставки',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildQRCard() {
    return GestureDetector(
      onTap: () => context.push('/loyalty'),
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.purple.withValues(alpha: 0.15),
              AppColors.purple.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 80,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Points
            Row(
              children: [
                Text(
                  '1725',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'KG',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard({
    required String title,
    required String badge,
    required String imageUrl,
  }) {
    return Container(
      height: 95,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 65,
              height: 65,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 65,
                height: 65,
                color: AppColors.primarySoft,
                child: const Icon(Icons.coffee_rounded, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Челленджи',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: AppColors.purple,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchCardsSection() {
    // Mock punch cards data - filter out cards with 0 progress
    final allCards = [
      _PunchCardData(name: 'Кофе S', current: 3, max: 6),
      _PunchCardData(name: 'Кофе M', current: 6, max: 6),
      _PunchCardData(name: 'Кофе L', current: 0, max: 6), // Won't show - 0 progress
    ];

    // Only show cards with at least 1 punch
    final punchCards = allCards.where((c) => c.current > 0).toList();

    if (punchCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Плюс один',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: punchCards.length,
            itemBuilder: (context, index) {
              final card = punchCards[index];
              return _buildPunchCard(card);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPunchCard(_PunchCardData card) {
    final isComplete = card.current >= card.max;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9C27B0), // Deep purple
            Color(0xFFE91E63), // Pink
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Left side - text and dots
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.name,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${card.current} из ${card.max}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress pills - oval shaped
                      Row(
                        children: List.generate(card.max, (index) {
                          final isFilled = index < card.current;
                          return Container(
                            width: 22,
                            height: 12,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: isFilled
                                  ? const Color(0xFF7CB342) // Lime green
                                  : Colors.white.withValues(alpha: 0.25),
                              boxShadow: isFilled
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF7CB342).withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                // Right side - gift icon when complete
                if (isComplete)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8BC34A),
                          Color(0xFF689F38),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF689F38).withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBannersSection() {
    final banners = [
      _BannerData(
        badge: 'Акция',
        title: 'Скидка 20%\nна все торты',
        subtitle: 'До конца месяца',
        imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300&q=80',
        gradientColors: [const Color(0xFF7B1FA2), const Color(0xFFE91E63)],
      ),
      _BannerData(
        badge: 'Новинка',
        title: 'Попробуйте\nновые эклеры',
        subtitle: '6 новых вкусов',
        imageUrl: 'https://images.unsplash.com/photo-1550617931-e17a7b70dce2?w=300&q=80',
        gradientColors: [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
      ),
      _BannerData(
        badge: 'Бесплатно',
        title: 'Доставка\nот 1000 сом',
        subtitle: 'По всему городу',
        imageUrl: 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=300&q=80',
        gradientColors: [const Color(0xFFFF6F00), const Color(0xFFFFCA28)],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Акции и предложения',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return _buildPromoBanner(banners[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner(_BannerData banner) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: banner.gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: banner.gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Left side - text
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          banner.badge,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        banner.title,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner.subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right side - image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    banner.imageUrl,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        size: 40,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsBanner() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B1FA2), // Deep purple
            Color(0xFFE91E63), // Pink
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration circles
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left side - text
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Акция',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Скидка 20%\nна все торты',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'До конца месяца',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side - image
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300&q=80',
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.cake_rounded,
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                    ),
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

class _PunchCardData {
  final String name;
  final int current;
  final int max;

  const _PunchCardData({
    required this.name,
    required this.current,
    required this.max,
  });
}

class _BannerData {
  final String badge;
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Color> gradientColors;

  const _BannerData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.gradientColors,
  });
}
