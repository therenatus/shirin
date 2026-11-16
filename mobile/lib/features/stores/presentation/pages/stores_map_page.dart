import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/store.dart';
import '../bloc/stores_bloc.dart';
import '../widgets/store_map_widgets.dart';

/// Full-screen store map (`/stores-map`): edge-to-edge tiles with floating
/// clear-glass controls and a glass card for the selected store.
class StoresMapPage extends StatefulWidget {
  const StoresMapPage({super.key});

  @override
  State<StoresMapPage> createState() => _StoresMapPageState();
}

class _StoresMapPageState extends State<StoresMapPage> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  Store? _selectedStore;
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Default center: Bishkek, Kyrgyzstan
  static const LatLng _defaultCenter = LatLng(42.8746, 74.5698);
  static const double _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    void fail(String message) {
      if (!mounted) return;
      setState(() {
        _locationError = message;
        _isLoadingLocation = false;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        fail('Службы геолокации отключены');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          fail('Доступ к геолокации запрещен');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        fail('Доступ к геолокации запрещен навсегда');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      fail('Не удалось определить местоположение');
    }
  }

  void _centerOnUserLocation() {
    if (_userLocation != null && _mapReady) {
      _mapController.move(_userLocation!, 15.0);
    } else {
      _getCurrentLocation();
    }
  }

  void _zoom(double delta) {
    if (!_mapReady) return;
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + delta,
    );
  }

  void _onMarkerTap(Store store) {
    setState(() => _selectedStore = store);
    if (_mapReady) {
      _mapController.move(
        LatLng(store.lat!, store.lng!),
        _mapController.camera.zoom,
      );
    }
  }

  void _close() =>
      context.canPop() ? context.pop() : context.go('/stores');

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<StoresBloc, StoresState>(
        builder: (context, state) {
          Widget body;
          if (state is StoresError) {
            body = LiquidBackground(
              child: Center(
                child: StoresStateMessage(
                  icon: Icons.cloud_off_rounded,
                  color: AppColors.error,
                  title: 'Не удалось загрузить',
                  message: state.message,
                  action: GlassButton(
                    label: 'Повторить',
                    icon: Icons.refresh_rounded,
                    onTap: () =>
                        context.read<StoresBloc>().add(const LoadStores()),
                  ),
                ),
              ),
            );
          } else if (state is StoresLoaded) {
            body = _buildMap(state.stores);
          } else {
            body = const LiquidBackground(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: body),
              // Top controls: back, title capsule, back-to-list.
              Positioned(
                top: topInset + 6,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 19,
                      style: GlassStyle.clear,
                      tooltip: 'Назад',
                      onTap: _close,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: LiquidGlass.capsule(
                          style: GlassStyle.clear,
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              'Карта магазинов',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading3.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassIconButton(
                      icon: Icons.format_list_bulleted_rounded,
                      style: GlassStyle.clear,
                      tooltip: 'Список магазинов',
                      onTap: _close,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(List<Store> stores) {
    final topInset = MediaQuery.paddingOf(context).top;
    final storesWithCoords =
        stores.where((s) => s.lat != null && s.lng != null).toList();
    final bottom = GlassTabBarMetrics.clearance(context) - 8;
    final showLocationError = _locationError != null && _userLocation == null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation ??
                (storesWithCoords.isNotEmpty
                    ? LatLng(
                        storesWithCoords.first.lat!,
                        storesWithCoords.first.lng!,
                      )
                    : _defaultCenter),
            initialZoom: _defaultZoom,
            onMapReady: () => _mapReady = true,
            onTap: (_, _) => setState(() => _selectedStore = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.shirin.app',
            ),
            MarkerLayer(
              markers: [
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 36,
                    height: 36,
                    child: const UserLocationMarker(),
                  ),
                ...storesWithCoords.map((store) {
                  return Marker(
                    point: LatLng(store.lat!, store.lng!),
                    width: 60,
                    height: 60,
                    child: StoreMapMarker(
                      selected: _selectedStore?.id == store.id,
                      onTap: () => _onMarkerTap(store),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Status bar scrim.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + 72,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Location problem banner.
        if (showLocationError)
          Positioned(
            top: topInset + 62,
            left: 16,
            right: 72,
            child: LiquidGlass.capsule(
              style: GlassStyle.thick,
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locationError!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _getCurrentLocation,
                    tooltip: 'Повторить',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Map controls.
        Positioned(
          right: 16,
          top: topInset + 62,
          child: MapGlassControls(
            locating: _isLoadingLocation,
            locationError: showLocationError,
            onLocate: _centerOnUserLocation,
            onZoomIn: () => _zoom(1),
            onZoomOut: () => _zoom(-1),
          ),
        ),

        // Selected store card.
        Positioned(
          left: 16,
          right: 16,
          bottom: bottom,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _selectedStore == null
                ? const SizedBox.shrink()
                : SelectedStoreCard(
                    key: ValueKey(_selectedStore!.id),
                    store: _selectedStore!,
                    distance: storeDistanceText(_userLocation, _selectedStore!),
                    onClose: () => setState(() => _selectedStore = null),
                    onDetails: () => context.push(
                      '/stores/${_selectedStore!.id}',
                      extra: _selectedStore,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
