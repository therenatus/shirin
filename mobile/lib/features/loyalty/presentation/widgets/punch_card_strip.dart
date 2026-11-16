import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/punch_card.dart';
import '../bloc/punch_cards_bloc.dart';

/// "Плюс один": horizontal strip of coffee punch cards as glass strips.
/// Provides its own bloc so it can sit on any page.
///
/// A full card does not have a claim button: staff hand out the free coffee
/// after scanning the customer's QR, so the card just says so.
class PunchCardStrip extends StatelessWidget {
  final VoidCallback? onTap;

  const PunchCardStrip({super.key, this.onTap});

  static const double _height = 132;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PunchCardsBloc>()..add(const LoadPunchCards()),
      child: BlocBuilder<PunchCardsBloc, PunchCardsState>(
        builder: (context, state) {
          final cards = switch (state) {
            PunchCardsLoaded s => s.punchCards,
            _ => const <PunchCard>[],
          };
          if (cards.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: _height,
                child: PunchCardGlassTile(
                  title: 'Каждый 7-й кофе бесплатно',
                  sizeLabel: null,
                  current: 0,
                  max: 6,
                  onTap: onTap,
                ),
              ),
            );
          }
          final single = cards.length == 1;
          return SizedBox(
            // Room for the glass shadow below the tiles.
            height: _height + 16,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = cards[i];
                final ready = c.isComplete && !c.freeItemClaimed;
                final width = MediaQuery.sizeOf(context).width - (single ? 40 : 56);
                return SizedBox(
                  width: width,
                  child: PunchCardGlassTile(
                    title: ready
                        ? 'Бесплатный кофе ждёт'
                        : '${c.maxPunches + 1}-й кофе бесплатно',
                    sizeLabel: c.size.name,
                    current: c.currentPunches,
                    max: c.maxPunches,
                    ready: ready,
                    onTap: onTap,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// One punch card on glass: title, size badge, stamp track, gift badge.
class PunchCardGlassTile extends StatelessWidget {
  final String title;
  final String? sizeLabel;
  final int current;
  final int max;
  final bool ready;
  final VoidCallback? onTap;

  const PunchCardGlassTile({
    super.key,
    required this.title,
    required this.sizeLabel,
    required this.current,
    required this.max,
    this.ready = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = ready || (max > 0 && current >= max);
    return LiquidGlass(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (sizeLabel != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          sizeLabel!,
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (ready)
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          // Free coffee is given out by staff after scanning the QR code.
                          'Покажите QR на кассе',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '$current из $max',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                const SizedBox(height: 12),
                _StampTrack(current: current, max: max),
              ],
            ),
          ),
          const SizedBox(width: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.bonusCardGradient,
                    )
                  : null,
              color: done ? null : AppColors.primary.withValues(alpha: 0.1),
              boxShadow: done
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              done ? Icons.card_giftcard_rounded : Icons.coffee_rounded,
              size: 26,
              color: done ? Colors.white : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StampTrack extends StatelessWidget {
  final int current;
  final int max;
  const _StampTrack({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    if (max <= 0) return const SizedBox(height: 10);
    return Row(
      children: [
        for (var i = 0; i < max; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250 + i * 40),
              curve: Curves.easeOutBack,
              height: 10,
              decoration: BoxDecoration(
                color: i < current
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          if (i < max - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}
