import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/store.dart';
import 'store_status.dart';

/// Store row on a solid [ContentCard]: icon tile, name, address, open/closed
/// status, working hours and (optionally) the distance from the user.
class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  /// Pre-formatted distance, e.g. "850 м". Hidden when null/empty.
  final String? distance;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final status = StoreStatus.fromHours(store.workingHours);
    return ContentCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StoreIconTile(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        store.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading3.copyWith(fontSize: 16),
                      ),
                    ),
                    if (distance != null && distance!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      StoreDistancePill(distance: distance!),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  store.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
                if (status != null || store.workingHours != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (status != null) StoreStatusPill(status: status),
                      if (store.workingHours != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                store.workingHours!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded pastel tile with a storefront icon.
class StoreIconTile extends StatelessWidget {
  final double size;
  final bool selected;

  const StoreIconTile({super.key, this.size = 48, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        Icons.storefront_rounded,
        color: selected ? Colors.white : AppColors.primary,
        size: size / 2,
      ),
    );
  }
}
