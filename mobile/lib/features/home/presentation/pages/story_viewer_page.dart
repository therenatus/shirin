import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.stories.length,
        itemBuilder: (context, storyIndex) {
          final story = widget.stories[storyIndex];
          final isCurrentStory = storyIndex == _currentStoryIndex;

          return LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) => _onTapDown(details, constraints),
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Story Image
                    if (isCurrentStory)
                      _buildSlideContent(story.slides[_currentSlideIndex])
                    else if (story.slides.isNotEmpty)
                      _buildSlideContent(story.slides[0]),

                    // Dark gradient overlay at top
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Dark gradient overlay at bottom
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Top UI
                    SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          // Progress bars
                          if (isCurrentStory)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: List.generate(
                                  story.slides.length,
                                  (index) => Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      child: _buildProgressBar(index),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // Story avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      story.previewImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title
                                Expanded(
                                  child: Text(
                                    story.title,
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Close button
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom content
                    if (isCurrentStory && _currentSlide.buttonText != null)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: MediaQuery.of(context).padding.bottom + 24,
                        child: _buildActionButton(),
                      ),

                    // Pause indicator
                    if (_isPaused)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.pause_rounded,
                            color: Colors.white,
                            size: 32,
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

  Widget _buildSlideContent(StorySlide slide) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.network(
          slide.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primary,
            child: const Center(
              child: Icon(Icons.image_rounded, color: Colors.white54, size: 64),
            ),
          ),
        ),
        // Text overlay
        if (slide.title != null || slide.subtitle != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: slide.buttonText != null ? 100 : 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slide.title != null)
                  Text(
                    slide.title!,
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                if (slide.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    slide.subtitle!,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(int index) {
    double progress = 0;
    if (index < _currentSlideIndex) {
      progress = 1;
    } else if (index == _currentSlideIndex) {
      progress = _progressController.value;
    }

    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        if (index == _currentSlideIndex) {
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

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: () {
        // Handle button action
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD81B60), Color(0xFFE91E63)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _currentSlide.buttonText!,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
