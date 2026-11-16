import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';

class Story {
  final String id;
  final String title;
  final String previewImage;
  final List<StorySlide> slides;
  final bool isViewed;

  const Story({
    required this.id,
    required this.title,
    required this.previewImage,
    required this.slides,
    this.isViewed = false,
  });
}

class StorySlide {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final String? buttonAction;
  final int durationSeconds;

  const StorySlide({
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.buttonText,
    this.buttonAction,
    this.durationSeconds = 5,
  });
}

/// Row of story bubbles: unseen stories get the brand ring, seen ones a
/// quiet hairline. Tapping springs the bubble (glass press feel).
class StoriesWidget extends StatelessWidget {
  final List<Story> stories;
  final Function(int storyIndex) onStoryTap;

  const StoriesWidget({
    super.key,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _StoryItem(
          story: stories[index],
          onTap: () => onStoryTap(index),
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;

  const _StoryItem({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      glowColor: Colors.transparent,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isViewed
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                border: story.isViewed
                    ? Border.all(
                        color: AppColors.textLight.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
                boxShadow: story.isViewed
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2.5),
                  color: AppColors.surface,
                ),
                child: ClipOval(
                  child: Image.network(
                    story.previewImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.primarySoft,
                      child: Center(
                        child: Icon(
                          Icons.photo_rounded,
                          color: AppColors.primary.withValues(alpha: 0.5),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontWeight: story.isViewed ? FontWeight.w600 : FontWeight.w700,
                color: story.isViewed
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
