import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_text_styles.dart';
import 'liquid_glass/liquid_glass_kit.dart';

/// Legacy app bar API on top of the Liquid Glass top bar.
/// New screens should use [GlassPage], which also handles large titles.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBorder;

  const GlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBorder = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(GlassTopBar.barHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop() || GoRouter.of(context).canPop();
    final lead = leading ??
        (canPop
            ? GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 19,
                tooltip: 'Назад',
                onTap: () => context.pop(),
              )
            : null);
    if (titleWidget != null) {
      return SafeArea(
        bottom: false,
        child: SizedBox(
          height: GlassTopBar.barHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (lead != null) lead,
                const SizedBox(width: 8),
                Expanded(
                  child: DefaultTextStyle(
                    style: AppTextStyles.heading3,
                    child: Align(
                      alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
                      child: titleWidget!,
                    ),
                  ),
                ),
                ...?actions,
              ],
            ),
          ),
        ),
      );
    }
    return GlassTopBar(
      title: title,
      leading: lead,
      actions: actions ?? const [],
    );
  }
}
