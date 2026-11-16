import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../bloc/loyalty_bloc.dart';
import '../widgets/loyalty_hero_card.dart';
import '../widgets/punch_card_strip.dart';
import '../widgets/qr_code_widget.dart';

/// The loyalty pass: balance and level on the brand card, the QR for the
/// cashier on a white tile, coffee stamps, and a link to points history.
class LoyaltyCardPage extends StatelessWidget {
  const LoyaltyCardPage({super.key});

  void _reload(BuildContext context) =>
      context.read<LoyaltyBloc>().add(const LoadLoyaltyInfo());

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyBloc, LoyaltyState>(
      builder: (context, state) {
        return GlassPage(
          title: 'Карта лояльности',
          onRefresh: () async => _reload(context),
          actions: [
            GlassIconButton(
              icon: Icons.history_rounded,
              tooltip: 'История баллов',
              onTap: () => context.push('/loyalty/history'),
            ),
          ],
          slivers: _buildBody(context, state),
        );
      },
    );
  }

  List<Widget> _buildBody(BuildContext context, LoyaltyState state) {
    if (state is LoyaltyLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }
    if (state is LoyaltyError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LiquidGlass(
                    width: 112,
                    height: 112,
                    borderRadius: BorderRadius.circular(56),
                    child: const Center(
                      child: Icon(Icons.cloud_off_rounded,
                          size: 48, color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    label: 'Повторить',
                    icon: Icons.refresh_rounded,
                    onTap: () => _reload(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    if (state is! LoyaltyInfoLoaded) return const [];

    final info = state.info;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: LoyaltyHeroCard(
            points: info.points,
            level: info.level,
            trailing: const Icon(Icons.contactless_rounded,
                color: Colors.white, size: 24),
            child: info.qrCode == null
                ? null
                : Column(
                    children: [
                      Center(
                        child: LayoutBuilder(
                          builder: (context, c) => LoyaltyQrCodeWidget(
                            data: info.qrCode!,
                            // Fits narrow screens: card width minus tile padding.
                            size: (c.maxWidth - 28).clamp(140.0, 210.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Покажите QR-код на кассе',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Text('Кофейные штампы', style: AppTextStyles.heading2),
        ),
      ),
      const SliverToBoxAdapter(child: PunchCardStrip()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverToBoxAdapter(
          child: GlassButton(
            label: 'История баллов',
            icon: Icons.history_rounded,
            expanded: true,
            onTap: () => context.push('/loyalty/history'),
          ),
        ),
      ),
    ];
  }
}
