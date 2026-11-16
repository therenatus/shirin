# Shirin — Liquid Glass design rules

The app follows Apple's Liquid Glass language (iOS 26+), implemented in pure
Flutter (no native views, no shader packages). Import everything from
`shared/widgets/liquid_glass/liquid_glass_kit.dart`.

## Layers
1. **Background** — `LiquidBackground` (soft drifting rose blobs). `GlassPage` adds it for you.
2. **Content** — photos, product info, orders, text, lists. Sits on solid
   `ContentCard`s (white, radius 24, soft shadow) or directly on the background.
   Content is never glass: it must stay crisp.
3. **Controls** — floating glass: tab bar, top bar, back/action buttons
   (`GlassIconButton`), buttons (`GlassButton`), chips (`GlassChip`),
   segmented controls (`GlassSegmented`), fields (`GlassTextField`),
   sheets (`showGlassSheet`), toasts (`showGlassToast`), control groups (`GlassCard`).

## Rules
- At most **one** brand-tinted action per screen: `GlassButton(prominent: true)`
  or `GlassStyle.prominent`. Everything else is neutral glass.
- Controls over photos/maps use `GlassStyle.clear`; over video/stories use `GlassStyle.dark`.
- Shapes: capsules for buttons/chips/fields, circles for icon buttons, radius 24–26
  for cards, 34 for sheets. Concentric corners: inner radius = outer radius − padding.
- Spacing: 20 pt screen gutters, 12–16 between cards, 8 between controls.
- Type: Manrope via `AppTextStyles`. Large titles use `AppTextStyles.display`
  (handled by `GlassPage`). Section titles `heading2`.
- Every screen inside the tab shell uses `GlassPage` (large title that collapses
  into a glass top bar, glass back button, bottom clearance for the floating tab bar).
  Full-screen flows outside the shell (splash, login, OTP, story viewer) build
  their own layout but still use `LiquidBackground` and glass controls.
- Scrollables must end with `GlassTabBarMetrics.clearance(context)` of space if
  not using `GlassPage` (the tab bar floats over content).
- Primary actions that must always be reachable go in `GlassPage.bottomBar`
  (floats above the tab bar).
- Motion: springy (`Curves.easeOutBack`, 250–450 ms). Glass grows slightly when
  pressed (built into `LiquidGlass(onTap:)`). Haptic tick on taps (built in).
- Brand color `AppColors.primary` (#D81B60) is for the selected state, prices
  highlights and the single prominent action — not for large fills.
- Don't stack glass on glass except the tab-bar droplet / segmented thumb.
