import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'glass_buttons.dart';
import 'glass_style.dart';
import 'glass_tab_bar.dart';
import 'liquid_background.dart';

/// Standard screen in the Liquid Glass design.
///
/// - Large title that scrolls with content; once it scrolls away a compact
///   title fades in on a glass top bar (iOS navigation behaviour).
/// - Back / action buttons are round glass buttons floating over content.
/// - Liquid background behind everything; content scrolls under the bars.
/// - [bottomBar] floats above the tab bar (e.g. "Оформить заказ").
///
/// Pass content as [slivers]. Wrap box widgets in `SliverToBoxAdapter`
/// or use [GlassPage.box] for a single non-sliver body.
class GlassPage extends StatefulWidget {
  final String? title;

  /// Small text above the large title (e.g. "Кондитерская Ширин").
  final String? eyebrow;

  /// Show the big title in the content. When false only the compact bar title is shown.
  final bool largeTitle;

  final List<Widget> slivers;
  final List<Widget> actions;

  /// Leading widget. Defaults to a glass back button when the route can pop.
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;

  /// Floating area above the tab bar (primary action, totals).
  final Widget? bottomBar;

  /// Pull-to-refresh.
  final Future<void> Function()? onRefresh;

  /// Whether the floating tab bar is visible below this page.
  final bool hasTabBar;

  final double backgroundIntensity;
  final ScrollController? controller;

  const GlassPage({
    super.key,
    this.title,
    this.eyebrow,
    this.largeTitle = true,
    required this.slivers,
    this.actions = const [],
    this.leading,
    this.showBack = true,
    this.onBack,
    this.bottomBar,
    this.onRefresh,
    this.hasTabBar = true,
    this.backgroundIntensity = 1,
    this.controller,
  });

  /// Convenience for a single box body.
  GlassPage.box({
    Key? key,
    String? title,
    String? eyebrow,
    bool largeTitle = true,
    required Widget child,
    List<Widget> actions = const [],
    Widget? leading,
    bool showBack = true,
    VoidCallback? onBack,
    Widget? bottomBar,
    Future<void> Function()? onRefresh,
    bool hasTabBar = true,
    double backgroundIntensity = 1,
    ScrollController? controller,
  }) : this(
          key: key,
          title: title,
          eyebrow: eyebrow,
          largeTitle: largeTitle,
          slivers: [SliverToBoxAdapter(child: child)],
          actions: actions,
          leading: leading,
          showBack: showBack,
          onBack: onBack,
          bottomBar: bottomBar,
          onRefresh: onRefresh,
          hasTabBar: hasTabBar,
          backgroundIntensity: backgroundIntensity,
          controller: controller,
        );

  @override
  State<GlassPage> createState() => _GlassPageState();
}

class _GlassPageState extends State<GlassPage> {
  final ValueNotifier<double> _offset = ValueNotifier(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      _offset.value = n.metrics.pixels;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomClearance = widget.hasTabBar
        ? GlassTabBarMetrics.clearance(context)
        : MediaQuery.paddingOf(context).bottom + 24;
    final bottomBarSpace = widget.bottomBar != null ? 84.0 : 0.0;

    final canPop = GoRouter.of(context).canPop() || Navigator.of(context).canPop();
    final leading = widget.leading ??
        (widget.showBack && (canPop || widget.onBack != null)
            ? GlassIconButton(
                key: const ValueKey('glass-back'),
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 19,
                tooltip: 'Назад',
                onTap: widget.onBack ?? () => context.pop(),
              )
            : null);

    Widget scroll = CustomScrollView(
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: topInset + GlassTopBar.barHeight + 4),
        ),
        if (widget.largeTitle && widget.title != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.eyebrow != null) ...[
                    Text(
                      widget.eyebrow!.toUpperCase(),
                      style: AppTextStyles.overline.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(widget.title!, style: AppTextStyles.display),
                ],
              ),
            ),
          ),
        ...widget.slivers,
        SliverToBoxAdapter(child: SizedBox(height: bottomClearance + bottomBarSpace)),
      ],
    );

    if (widget.onRefresh != null) {
      scroll = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        edgeOffset: topInset + GlassTopBar.barHeight,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: scroll,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        intensity: widget.backgroundIntensity,
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: scroll,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _offset,
                builder: (context, offset, _) {
                  // Compact title appears once the large title has scrolled away.
                  final threshold = widget.largeTitle ? 44.0 : 0.0;
                  final progress = widget.largeTitle
                      ? ((offset - threshold) / 24).clamp(0.0, 1.0)
                      : 1.0;
                  final barGlass = (offset / 16).clamp(0.0, 1.0);
                  return GlassTopBar(
                    title: widget.title,
                    titleOpacity: progress,
                    glassOpacity: barGlass,
                    leading: leading,
                    actions: widget.actions,
                  );
                },
              ),
            ),
            if (widget.bottomBar != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: (widget.hasTabBar
                        ? GlassTabBarMetrics.clearance(context) - 8
                        : MediaQuery.paddingOf(context).bottom + 12),
                child: widget.bottomBar!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Top bar: floating glass buttons with a frosted strip that fades in as
/// content scrolls underneath ("scroll edge effect").
class GlassTopBar extends StatelessWidget {
  static const double barHeight = 56;

  final String? title;
  final double titleOpacity;
  final double glassOpacity;
  final Widget? leading;
  final List<Widget> actions;

  const GlassTopBar({
    super.key,
    this.title,
    this.titleOpacity = 1,
    this.glassOpacity = 1,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: topInset + barHeight,
      child: Stack(
        children: [
          // Frosted scroll edge. Fades in with scroll, fades out at the bottom edge.
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: glassOpacity,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: GlassStyle.regular.copyWith(blur: 22).backdropFilter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withValues(alpha: 0.86),
                            AppColors.background.withValues(alpha: 0.55),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: topInset,
            height: barHeight,
            child: Row(
              children: [
                if (leading != null) leading! else const SizedBox(width: 44),
                Expanded(
                  // Hidden title is removed from the tree so it doesn't
                  // duplicate the large title for screen readers and tests.
                  child: titleOpacity <= 0 || title == null
                      ? const SizedBox.shrink()
                      : Opacity(
                          opacity: titleOpacity,
                          child: Text(
                            title!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading3.copyWith(fontSize: 17),
                          ),
                        ),
                ),
                if (actions.isEmpty)
                  const SizedBox(width: 44)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
