import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/store.dart';
import '../widgets/store_map_widgets.dart';
import '../widgets/store_status.dart';

/// Store details: an edge-to-edge hero (live map snapshot of the store, or the
/// brand tile when it has no coordinates) with a floating glass back button,
/// content on solid cards, and "Позвонить" floating above the tab bar.
class StoreDetailsPage extends StatefulWidget {
  final Store store;

  const StoreDetailsPage({super.key, required this.store});

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  static const double _heroHeight = 340;
  final ValueNotifier<double> _offset = ValueNotifier(0);

  Store get store => widget.store;
  bool get _hasCoords => store.lat != null && store.lng != null;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/stores');

  @override
  Widget build(BuildContext context) {
    final status = StoreStatus.fromHours(store.workingHours);
    final clearance = GlassTabBarMetrics.clearance(context);

    final Widget? bottomAction = store.phone != null
        ? GlassButton(
            label: 'Позвонить',
            icon: Icons.phone_rounded,
            prominent: true,
            expanded: true,
            onTap: () => callStorePhone(store.phone!),
          )
        : _hasCoords
            ? GlassButton(
                label: 'Построить маршрут',
                icon: Icons.directions_rounded,
                prominent: true,
                expanded: true,
                onTap: () => openStoreInMaps(store),
              )
            : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        intensity: 0.8,
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
                  _offset.value = n.metrics.pixels;
                }
                return false;
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: _heroHeight, child: _buildHero()),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTitleCard(status),
                            const SizedBox(height: 16),
                            _buildInfoCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: clearance + (bottomAction != null ? 84 : 0) - 24,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _offset,
                builder: (context, offset, _) {
                  final start = _heroHeight - 140;
                  final glass = ((offset - start) / 40).clamp(0.0, 1.0);
                  final title = ((offset - start - 40) / 30).clamp(0.0, 1.0);
                  return GlassTopBar(
                    title: store.name,
                    titleOpacity: title,
                    glassOpacity: glass,
                    leading: GlassIconButton(
                      key: const ValueKey('glass-back'),
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 19,
                      tooltip: 'Назад',
                      style: glass < 0.5 ? GlassStyle.clear : GlassStyle.regular,
                      onTap: _back,
                    ),
                  );
                },
              ),
            ),
            if (bottomAction != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: clearance - 8,
                child: bottomAction,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    Widget hero;
    if (_hasCoords) {
      final point = LatLng(store.lat!, store.lng!);
      hero = IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            // Nudge the pin above the overlapping card.
            initialCenter: LatLng(store.lat! - 0.0012, store.lng!),
            initialZoom: 15.5,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.shirin.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 60,
                  height: 60,
                  child: StoreMapMarker(selected: true, onTap: () {}),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      hero = DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight,
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const Icon(
                Icons.storefront_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        hero,
        // Fade into the page background under the overlapping card.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleCard(StoreStatus? status) {
    return ContentCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'КОНДИТЕРСКАЯ ШИРИН',
            style: AppTextStyles.overline.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(store.name, style: AppTextStyles.heading1),
          if (status != null) ...[
            const SizedBox(height: 12),
            StoreStatusPill(status: status),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final rows = <Widget>[
      _InfoRow(
        icon: Icons.location_on_outlined,
        title: 'Адрес',
        value: store.address,
        actionLabel: _hasCoords ? 'Маршрут' : null,
        onTap: _hasCoords ? () => openStoreInMaps(store) : null,
      ),
      if (store.workingHours != null)
        _InfoRow(
          icon: Icons.schedule_rounded,
          title: 'Режим работы',
          value: store.workingHours!,
        ),
      if (store.phone != null)
        _InfoRow(
          icon: Icons.phone_outlined,
          title: 'Телефон',
          value: store.phone!,
          highlight: true,
          onTap: () => callStorePhone(store.phone!),
        ),
    ];

    return ContentCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 16,
                color: AppColors.divider,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final bool highlight;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: highlight ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                actionLabel!,
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
