import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/punch_card.dart';
import 'punch_card_strip.dart';

/// A single punch card rendered as a glass strip. A full card shows
/// 'Покажите QR на кассе': the free coffee is given out by staff after
/// scanning the customer's QR, there is no client-side claim.
class PunchCardWidget extends StatelessWidget {
  final PunchCard punchCard;
  final double width;

  const PunchCardWidget({
    super.key,
    required this.punchCard,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    final ready = punchCard.isComplete && !punchCard.freeItemClaimed;
    return SizedBox(
      width: width,
      child: PunchCardGlassTile(
        title: ready ? 'Бесплатный кофе ждёт' : punchCard.sizeName,
        sizeLabel: punchCard.size.name,
        current: punchCard.currentPunches,
        max: punchCard.maxPunches,
        ready: ready,
      ),
    );
  }
}

/// "Плюс один" section: title and a horizontal row of glass punch cards.
class PunchCardsSection extends StatelessWidget {
  final List<PunchCard> punchCards;

  const PunchCardsSection({
    super.key,
    required this.punchCards,
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
          child: Text('Плюс один', style: AppTextStyles.heading2),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: punchCards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                PunchCardWidget(punchCard: punchCards[index]),
          ),
        ),
      ],
    );
  }
}
