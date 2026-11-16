import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';

/// Paged promo banners in brand gradients, each with a clear-glass caption
/// capsule.
class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  final _controller = PageController(viewportFraction: 0.9);

  static const _banners = [
    _BannerData(
      title: 'Скидка 20%\nна торты',
      subtitle: 'При заказе через приложение',
      gradient: [AppColors.primary, AppColors.secondary],
    ),
    _BannerData(
      title: 'Новая\nколлекция',
      subtitle: 'Весенние десерты уже в меню',
      gradient: [AppColors.primaryLight, AppColors.primary],
    ),
    _BannerData(
      title: 'Бонусы x2',
      subtitle: 'За каждый заказ в выходные',
      gradient: [AppColors.secondaryLight, AppColors.primaryLight],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: _banners.length,
        controller: _controller,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: banner.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                LiquidGlass.capsule(
                  style: GlassStyle.clear,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    banner.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
