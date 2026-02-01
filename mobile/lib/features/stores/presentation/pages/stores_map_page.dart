import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/entities/store.dart';
import '../bloc/stores_bloc.dart';

class StoresMapPage extends StatefulWidget {
  const StoresMapPage({super.key});

  @override
  State<StoresMapPage> createState() => _StoresMapPageState();
}

class _StoresMapPageState extends State<StoresMapPage> {
  final MapController _mapController = MapController();
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

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Службы геолокации отключены';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Доступ к геолокации запрещен';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Доступ к геолокации запрещен навсегда';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Не удалось определить местоположение';
        _isLoadingLocation = false;
      });
    }
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Карта магазинов', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Список магазинов',
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: BlocBuilder<StoresBloc, StoresState>(
        builder: (context, state) {
          if (state is StoresLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StoresError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<StoresBloc>().add(const LoadStores()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          if (state is StoresLoaded) {
            final stores = state.stores;
            final storesWithCoords =
                stores.where((s) => s.lat != null && s.lng != null).toList();

            return Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _userLocation ??
                        (storesWithCoords.isNotEmpty
                            ? LatLng(storesWithCoords.first.lat!,
                                storesWithCoords.first.lng!)
                            : _defaultCenter),
                    initialZoom: _defaultZoom,
                    onTap: (_, _) {
                      setState(() => _selectedStore = null);
                    },
                  ),
                  children: [
                    // OpenStreetMap tiles
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.shirin.app',
                    ),
                    // Markers layer
                    MarkerLayer(
                      markers: [
                        // User location marker
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        // Store markers
                        ...storesWithCoords.map((store) {
                          final isSelected = _selectedStore?.id == store.id;
                          return Marker(
                            point: LatLng(store.lat!, store.lng!),
                            width: isSelected ? 50 : 40,
                            height: isSelected ? 50 : 40,
                            child: GestureDetector(
                              onTap: () => _onMarkerTap(store),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: isSelected ? 26 : 22,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Selected store info card
                if (_selectedStore != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    child: _buildStoreInfoCard(_selectedStore!),
                  ),

                // Controls
                Positioned(
                  right: 16,
                  bottom: _selectedStore != null
                      ? MediaQuery.of(context).padding.bottom + 200
                      : MediaQuery.of(context).padding.bottom + 100,
                  child: Column(
                    children: [
                      // My location button
                      _buildControlButton(
                        _isLoadingLocation
                            ? Icons.hourglass_empty
                            : Icons.my_location,
                        _centerOnUserLocation,
                        isLoading: _isLoadingLocation,
                        hasError: _locationError != null && _userLocation == null,
                      ),
                      const SizedBox(height: 8),
                      // Zoom controls
                      _buildControlButton(Icons.add, () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildControlButton(Icons.remove, () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      }),
                    ],
                  ),
                ),

                // Location error snackbar
                if (_locationError != null && _userLocation == null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    left: 16,
                    right: 16,
                    child: GlassContainer(
                      borderRadius: 12,
                      enableBlur: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_off,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                          GestureDetector(
                            onTap: _getCurrentLocation,
                            child: const Icon(
                              Icons.refresh,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed, {
    bool isLoading = false,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                icon,
                color: hasError ? Colors.orange : AppColors.primary,
              ),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }

  Widget _buildStoreInfoCard(Store store) {
    return GlassContainer(
      borderRadius: 20,
      enableBlur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with name and close button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_userLocation != null &&
                        store.lat != null &&
                        store.lng != null)
                      Text(
                        _getDistanceText(store),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedStore = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address
          _buildInfoRow(Icons.location_on_outlined, store.address),

          // Working hours
          if (store.workingHours != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, store.workingHours!),
          ],

          // Phone
          if (store.phone != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _callPhone(store.phone!),
              child: _buildInfoRow(
                Icons.phone_outlined,
                store.phone!,
                isLink: true,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(store),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Маршрут'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (store.phone != null) ...[
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _callPhone(store.phone!),
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getDistanceText(Store store) {
    if (_userLocation == null || store.lat == null || store.lng == null) {
      return '';
    }

    final distanceInMeters = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      store.lat!,
      store.lng!,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} м от вас';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} км от вас';
    }
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isLink ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isLink ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _onMarkerTap(Store store) {
    setState(() => _selectedStore = store);
    _mapController.move(
      LatLng(store.lat!, store.lng!),
      _mapController.camera.zoom,
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openInMaps(Store store) async {
    if (store.lat == null || store.lng == null) return;

    // Try to open in Google Maps, fallback to browser
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${store.lat},${store.lng}',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}
