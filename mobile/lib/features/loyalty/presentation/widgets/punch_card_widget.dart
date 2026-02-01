import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/punch_card.dart';

class PunchCardWidget extends StatelessWidget {
  final PunchCard punchCard;
  final VoidCallback? onClaim;

  const PunchCardWidget({
    super.key,
    required this.punchCard,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = punchCard.isComplete && !punchCard.freeItemClaimed;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isComplete
                    ? [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.85),
                        AppColors.primaryDark.withValues(alpha: 0.85),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isComplete ? onClaim : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              punchCard.sizeName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isComplete)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.card_giftcard,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        punchCard.progressText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          punchCard.maxPunches,
                          (index) => Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < punchCard.currentPunches
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: index < punchCard.currentPunches
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 10,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (isComplete) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Забрать',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PunchCardsSection extends StatelessWidget {
  final List<PunchCard> punchCards;
  final Function(CoffeeSize)? onClaim;

  const PunchCardsSection({
    super.key,
    required this.punchCards,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    if (punchCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Плюс один',
            style: AppTextStyles.heading3,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: punchCards.length,
            itemBuilder: (context, index) {
              final card = punchCards[index];
              return PunchCardWidget(
                punchCard: card,
                onClaim: card.isComplete && !card.freeItemClaimed
                    ? () => onClaim?.call(card.size)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
