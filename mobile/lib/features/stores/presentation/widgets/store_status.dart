import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Open/closed status derived from a free-form working hours string such as
/// "09:00 - 22:00", "Ежедневно 8:00–21:30" or "Круглосуточно".
/// Returns null when the hours can't be parsed, so the UI simply hides it.
class StoreStatus {
  final bool isOpen;
  final String label;

  const StoreStatus({required this.isOpen, required this.label});

  static final _range = RegExp(
    r'(\d{1,2})[:.](\d{2})\s*[-–—]\s*(\d{1,2})[:.](\d{2})',
  );

  static StoreStatus? fromHours(String? hours, {DateTime? now}) {
    if (hours == null || hours.trim().isEmpty) return null;
    final lower = hours.toLowerCase();
    if (lower.contains('круглосуточно') || lower.contains('24/7')) {
      return const StoreStatus(isOpen: true, label: 'Открыто круглосуточно');
    }
    final m = _range.firstMatch(hours);
    if (m == null) return null;

    final open = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    var close = int.parse(m.group(3)!) * 60 + int.parse(m.group(4)!);
    final t = now ?? DateTime.now();
    final current = t.hour * 60 + t.minute;

    String fmt(int minutes) {
      final mm = minutes % (24 * 60);
      return '${(mm ~/ 60).toString().padLeft(2, '0')}:${(mm % 60).toString().padLeft(2, '0')}';
    }

    bool isOpen;
    if (close == open) {
      isOpen = true;
    } else if (close > open) {
      isOpen = current >= open && current < close;
    } else {
      // Overnight, e.g. 10:00 – 02:00.
      isOpen = current >= open || current < close;
      close += 24 * 60;
    }

    return isOpen
        ? StoreStatus(isOpen: true, label: 'Открыто до ${fmt(close)}')
        : StoreStatus(isOpen: false, label: 'Закрыто · откроется в ${fmt(open)}');
  }
}

/// Small status pill: green dot "Открыто до 22:00" / grey "Закрыто".
class StoreStatusPill extends StatelessWidget {
  final StoreStatus status;
  final bool compact;

  const StoreStatusPill({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = status.isOpen ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Distance pill shown next to a store ("1.2 км").
class StoreDistancePill extends StatelessWidget {
  final String distance;

  const StoreDistancePill({super.key, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            distance,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
