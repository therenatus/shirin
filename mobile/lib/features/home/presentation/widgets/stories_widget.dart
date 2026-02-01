import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

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
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _StoryItem(
              story: story,
              onTap: () => onStoryTap(index),
            ),
          );
        },
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Avatar with gradient border
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.isViewed
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF6B9D),
                        Color(0xFFFF8E53),
                        Color(0xFFFFC86B),
                      ],
                    ),
              border: story.isViewed
                  ? Border.all(color: AppColors.textLight.withValues(alpha: 0.5), width: 2)
                  : null,
              boxShadow: story.isViewed
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.network(
                  story.previewImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
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
          // Title
          SizedBox(
            width: 76,
            child: Text(
              story.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: story.isViewed ? FontWeight.w600 : FontWeight.w700,
                color: story.isViewed ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
