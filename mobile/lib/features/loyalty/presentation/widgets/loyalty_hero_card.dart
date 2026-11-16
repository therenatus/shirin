import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Russian name for a loyalty level coming from the API.
String loyaltyLevelName(String level) => switch (level.toLowerCase()) {
      'bronze' => 'Бронза',
      'silver' => 'Серебро',
      'gold' => 'Золото',
      'platinum' => 'Платина',
      _ => level,
    };

/// The Shirin loyalty card: a vivid berry gradient with a glassy sheen and
/// a bright rim, like a pass in Wallet. Shows the points balance and level;
/// [child] adds extra content under the balance (e.g. the QR tile) and
/// [trailing] sits in the top-right corner.
class LoyaltyHeroCard extends StatelessWidget {
  final int points;
  final String? level;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;

  const LoyaltyHeroCard({
    super.key,
    required this.points,
    this.level,
    this.trailing,
    this.child,
    this.onTap,
  });

  static const double radius = 28;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.bonusCardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Soft light blobs give the gradient depth.
            Positioned(
              right: -60,
              top: -70,
              child: _Blob(size: 200, alpha: 0.18),
            ),
            Positioned(
              left: -40,
              bottom: -80,
              child: _Blob(size: 180, alpha: 0.10),
            ),
            // Diagonal glass sheen across the top.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, 0.38, 0.39, 1],
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'ШИРИН',
                        style: AppTextStyles.overline.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (level != null) _LevelBadge(level: level!),
                      const Spacer(),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Баланс бонусов',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$points',
                            style: AppTextStyles.display.copyWith(
                              color: Colors.white,
                              fontSize: 44,
                              height: 1.05,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _pointsWord(points),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 18),
                    child!,
                  ],
                ],
              ),
            ),
            // Specular rim.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return _Pressable(onTap: onTap!, child: card);
  }

  static String _pointsWord(int n) {
    final r10 = n % 10, r100 = n % 100;
    if (r10 == 1 && r100 != 11) return 'балл';
    if (r10 >= 2 && r10 <= 4 && (r100 < 12 || r100 > 14)) return 'балла';
    return 'баллов';
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            loyaltyLevelName(level),
            style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double alpha;
  const _Blob({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Gentle press-in scale with a haptic tick, for a solid (non-glass) card.
class _Pressable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _Pressable({required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
