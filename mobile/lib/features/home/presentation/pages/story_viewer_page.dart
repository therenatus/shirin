import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../widgets/stories_widget.dart';

class StoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final int initialStoryIndex;
  final Function(String storyId)? onStoryViewed;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialStoryIndex = 0,
    this.onStoryViewed,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;

  int _currentStoryIndex = 0;
  int _currentSlideIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex;
    _pageController = PageController(initialPage: widget.initialStoryIndex);

    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener(_onProgressComplete);

    _startProgress();

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Story get _currentStory => widget.stories[_currentStoryIndex];
  StorySlide get _currentSlide => _currentStory.slides[_currentSlideIndex];

  void _startProgress() {
    _progressController.duration = Duration(seconds: _currentSlide.durationSeconds);
    _progressController.forward(from: 0);
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNextSlide();
    }
  }

  void _goToNextSlide() {
    if (_currentSlideIndex < _currentStory.slides.length - 1) {
      setState(() => _currentSlideIndex++);
      _startProgress();
    } else {
      _goToNextStory();
    }
  }

  void _goToPreviousSlide() {
    if (_currentSlideIndex > 0) {
      setState(() => _currentSlideIndex--);
      _startProgress();
    } else {
      _goToPreviousStory();
    }
  }

  void _goToNextStory() {
    widget.onStoryViewed?.call(_currentStory.id);

    if (_currentStoryIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentStoryIndex = index;
      _currentSlideIndex = 0;
    });
    _startProgress();
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx;
    final width = constraints.maxWidth;

    if (x < width / 3) {
      _goToPreviousSlide();
    } else if (x > width * 2 / 3) {
      _goToNextSlide();
    }
  }

  void _onLongPressStart(_) {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _onLongPressEnd(_) {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.stories.length,
        itemBuilder: (context, storyIndex) {
          final story = widget.stories[storyIndex];
          final isCurrentStory = storyIndex == _currentStoryIndex;
          final slide = isCurrentStory
              ? story.slides[_currentSlideIndex]
              : (story.slides.isNotEmpty ? story.slides[0] : null);

          return LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) => _onTapDown(details, constraints),
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (slide != null) _buildSlideImage(slide),

                    // Scrims so the glass controls and captions read.
                    const _Scrim(begin: Alignment.topCenter, strength: 0.5),
                    const _Scrim(begin: Alignment.bottomCenter, strength: 0.65),

                    if (slide != null) _buildCaption(slide, padding.bottom),

                    // Top UI
                    Positioned(
                      top: padding.top + 8,
                      left: 12,
                      right: 12,
                      child: Column(
                        children: [
                          if (isCurrentStory)
                            Row(
                              children: List.generate(
                                story.slides.length,
                                (index) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: _buildProgressBar(index),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Flexible(child: _buildStoryChip(story)),
                              const Spacer(),
                              GlassIconButton(
                                icon: Icons.close_rounded,
                                style: GlassStyle.dark,
                                iconSize: 22,
                                tooltip: 'Закрыть',
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bottom action
                    if (isCurrentStory && _currentSlide.buttonText != null)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: padding.bottom + 20,
                        child: GlassButton(
                          label: _currentSlide.buttonText!,
                          prominent: true,
                          expanded: true,
                          // Handle button action
                          onTap: () => Navigator.pop(context),
                        ),
                      ),

                    // Pause indicator
                    Center(
                      child: IgnorePointer(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          scale: _isPaused ? 1 : 0.6,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _isPaused ? 1 : 0,
                            child: const LiquidGlass(
                              style: GlassStyle.dark,
                              width: 72,
                              height: 72,
                              borderRadius: BorderRadius.all(Radius.circular(36)),
                              child: Icon(
                                Icons.pause_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Avatar + title on a smoked glass capsule.
  Widget _buildStoryChip(Story story) {
    return LiquidGlass.capsule(
      style: GlassStyle.dark,
      height: 44,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            ),
            child: ClipOval(
              child: Image.network(
                story.previewImage,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideImage(StorySlide slide) {
    return Image.network(
      slide.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.secondary,
        child: Center(
          child: Icon(
            Icons.image_rounded,
            color: Colors.white.withValues(alpha: 0.54),
            size: 64,
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(StorySlide slide, double bottomInset) {
    if (slide.title == null && slide.subtitle == null) {
      return const SizedBox.shrink();
    }
    final shadows = [
      Shadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 12),
    ];
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottomInset + (slide.buttonText != null ? 96 : 48),
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slide.title != null)
              Text(
                slide.title!,
                style: AppTextStyles.heading1.copyWith(
                  color: Colors.white,
                  height: 1.15,
                  shadows: shadows,
                ),
              ),
            if (slide.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                slide.subtitle!,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  shadows: shadows,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int index) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        double progress = 0;
        if (index < _currentSlideIndex) {
          progress = 1;
        } else if (index == _currentSlideIndex) {
          progress = _progressController.value;
        }
        return Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Scrim extends StatelessWidget {
  final Alignment begin;
  final double strength;

  const _Scrim({required this.begin, required this.strength});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: Alignment.center,
            colors: [
              Colors.black.withValues(alpha: strength),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
