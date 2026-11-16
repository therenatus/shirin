import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/store.dart';
import 'store_card.dart';
import 'store_status.dart';

// -----------------------------------------------------------------------------
// Helpers shared by the stores screens
// -----------------------------------------------------------------------------

/// "850 м" / "1.2 км" from the user to the store, or '' when unknown.
String storeDistanceText(LatLng? user, Store store) {
  if (user == null || store.lat == null || store.lng == null) return '';
  final meters = Geolocator.distanceBetween(
    user.latitude,
    user.longitude,
    store.lat!,
    store.lng!,
  );
  if (meters < 1000) return '${meters.round()} м';
  return '${(meters / 1000).toStringAsFixed(1)} км';
}

Future<void> callStorePhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> openStoreInMaps(Store store) async {
  if (store.lat == null || store.lng == null) return;
  final googleMapsUrl = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${store.lat},${store.lng}',
  );
  if (await canLaunchUrl(googleMapsUrl)) {
    await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
  }
}

String storesWord(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return 'филиал';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'филиала';
  }
  return 'филиалов';
}

// -----------------------------------------------------------------------------
// Map markers
// -----------------------------------------------------------------------------

/// Store pin: white disc with a raspberry icon; selected pins fill with the
/// brand color and grow with a spring.
class StoreMapMarker extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const StoreMapMarker({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          width: selected ? 52 : 40,
          height: selected ? 52 : 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : AppColors.primary,
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.18),
                blurRadius: selected ? 18 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: selected ? Colors.white : AppColors.primary,
            size: selected ? 26 : 20,
          ),
        ),
      ),
    );
  }
}

/// "You are here" dot with a soft halo.
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secondary.withValues(alpha: 0.16),
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Floating map controls
// -----------------------------------------------------------------------------

/// Vertical stack of clear-glass buttons: locate me, zoom in, zoom out.
class MapGlassControls extends StatelessWidget {
  final bool locating;
  final bool locationError;
  final VoidCallback onLocate;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapGlassControls({
    super.key,
    required this.locating,
    required this.onLocate,
    required this.onZoomIn,
    required this.onZoomOut,
    this.locationError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        locating
            ? const LiquidGlass(
                style: GlassStyle.clear,
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(22)),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : GlassIconButton(
                icon: Icons.near_me_rounded,
                style: GlassStyle.clear,
                iconColor: locationError ? AppColors.warning : AppColors.primary,
                tooltip: 'Моё местоположение',
                onTap: onLocate,
              ),
        const SizedBox(height: 12),
        // Zoom pair grouped in one capsule, like Apple Maps.
        LiquidGlass(
          style: GlassStyle.clear,
          width: 44,
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(icon: Icons.add_rounded, onTap: onZoomIn),
              Container(
                width: 22,
                height: 1,
                color: AppColors.textPrimary.withValues(alpha: 0.12),
              ),
              _ZoomButton(icon: Icons.remove_rounded, onTap: onZoomOut),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Selected store card
// -----------------------------------------------------------------------------

/// Glass card that floats above the map for the selected store.
class SelectedStoreCard extends StatelessWidget {
  final Store store;
  final String distance;
  final VoidCallback onClose;
  final VoidCallback? onDetails;

  const SelectedStoreCard({
    super.key,
    required this.store,
    required this.distance,
    required this.onClose,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final status = StoreStatus.fromHours(store.workingHours);
    final canRoute = store.lat != null && store.lng != null;

    return LiquidGlass(
      style: GlassStyle.thick,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StoreIconTile(size: 44, selected: true),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDetails,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading3.copyWith(fontSize: 17),
                            ),
                          ),
                          if (onDetails != null)
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textLight,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (status != null)
                            StoreStatusPill(status: status, compact: true),
                          if (distance.isNotEmpty)
                            StoreDistancePill(distance: distance),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _PlainCircleButton(
                icon: Icons.close_rounded,
                tooltip: 'Закрыть',
                onTap: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(icon: Icons.location_on_outlined, text: store.address),
                if (store.workingHours != null) ...[
                  const SizedBox(height: 6),
                  _InfoLine(icon: Icons.schedule_rounded, text: store.workingHours!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                Expanded(
                  child: _SolidCapsuleAction(
                    icon: Icons.directions_rounded,
                    label: 'Маршрут',
                    onTap: canRoute ? () => openStoreInMaps(store) : null,
                  ),
                ),
                if (store.phone != null) ...[
                  const SizedBox(width: 8),
                  _PlainCircleButton(
                    icon: Icons.phone_rounded,
                    tooltip: store.phone,
                    size: 48,
                    iconColor: AppColors.success,
                    onTap: () => callStorePhone(store.phone!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Solid brand capsule used *inside* a glass card (no glass-on-glass).
class _SolidCapsuleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SolidCapsuleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.button.copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return GlassPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      glowColor: Colors.white.withValues(alpha: 0.35),
      child: content,
    );
  }
}

/// White translucent circle button for use inside glass surfaces.
class _PlainCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final Color iconColor;

  const _PlainCircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 36,
    this.iconColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = GlassPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      glowColor: Colors.white.withValues(alpha: 0.7),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.5, color: iconColor),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

// -----------------------------------------------------------------------------
// Compact card for the horizontal strip over the map
// -----------------------------------------------------------------------------

class StoreMiniCard extends StatelessWidget {
  final Store store;
  final String distance;
  final VoidCallback onTap;

  const StoreMiniCard({
    super.key,
    required this.store,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = StoreStatus.fromHours(store.workingHours);
    return ContentCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const StoreIconTile(size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  store.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                if (status != null || distance.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (status != null)
                        Flexible(
                          child: StoreStatusPill(status: status, compact: true),
                        ),
                      if (status != null && distance.isNotEmpty)
                        const SizedBox(width: 6),
                      if (distance.isNotEmpty)
                        StoreDistancePill(distance: distance),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered loading / error placeholder used by the stores screens.
class StoresStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color color;

  const StoresStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading3),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
