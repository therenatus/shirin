import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/store_card.dart';
import '../widgets/store_map_widgets.dart';

enum _StoresMode { list, map }

/// "Магазины" tab: a glass segmented control switches between a searchable
/// list of store cards and a full-screen map with floating glass controls.
class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  _StoresMode _mode = _StoresMode.list;
  bool _mapVisited = false;
  bool _mapReady = false;

  Store? _selectedStore;
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  String _searchQuery = '';
  List<Store> _filteredStores = [];

  // Default center: Bishkek, Kyrgyzstan
  static const LatLng _defaultCenter = LatLng(42.8746, 74.5698);
  static const double _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    context.read<StoresBloc>().add(const LoadStores());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
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
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _filterStores(List<Store> stores) {
    if (_searchQuery.isEmpty) {
      _filteredStores = stores;
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredStores = stores
          .where((store) =>
              store.name.toLowerCase().contains(q) ||
              store.address.toLowerCase().contains(q))
          .toList();
    }
  }

  void _setMode(_StoresMode mode) {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      if (mode == _StoresMode.map) _mapVisited = true;
    });
  }

  void _onStoreSelected(Store store) {
    HapticFeedback.lightImpact();
    setState(() => _selectedStore = store);
    if (_mapReady && store.lat != null && store.lng != null) {
      _mapController.move(LatLng(store.lat!, store.lng!), 15.0);
    }
  }

  void _openDetails(Store store) {
    context.push('/stores/${store.id}', extra: store);
  }

  void _centerOnUserLocation() {
    HapticFeedback.lightImpact();
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoresBloc, StoresState>(
      builder: (context, state) {
        final showMap = state is StoresLoaded && _mapVisited;
        // Always an IndexedStack so the list page keeps its state (scroll
        // position) when the map is first built.
        return IndexedStack(
          index: showMap && _mode == _StoresMode.map ? 1 : 0,
          sizing: StackFit.expand,
          children: [
            _buildListPage(state),
            if (showMap)
              _buildMapView(state.stores)
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // List mode
  // ---------------------------------------------------------------------------

  Widget _buildModeSwitch() {
    return GlassSegmented<_StoresMode>(
      values: _StoresMode.values,
      selected: _mode,
      labelOf: (m) => m == _StoresMode.list ? 'Список' : 'Карта',
      onChanged: _setMode,
    );
  }

  Widget _buildListPage(StoresState state) {
    final slivers = <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        sliver: SliverToBoxAdapter(child: _buildModeSwitch()),
      ),
    ];

    if (state is StoresError) {
      slivers.add(
        SliverToBoxAdapter(
          child: StoresStateMessage(
            icon: Icons.cloud_off_rounded,
            color: AppColors.error,
            title: 'Не удалось загрузить',
            message: state.message,
            action: GlassButton(
              label: 'Повторить',
              icon: Icons.refresh_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<StoresBloc>().add(const LoadStores());
              },
            ),
          ),
        ),
      );
    } else if (state is StoresLoaded) {
      _filterStores(state.stores);
      slivers.addAll(_buildLoadedSlivers(state.stores));
    } else {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Загружаем филиалы...', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return GlassPage(
      title: 'Магазины',
      eyebrow: 'Кондитерская Ширин',
      showBack: false,
      onRefresh: () async => context.read<StoresBloc>().add(const LoadStores()),
      slivers: slivers,
    );
  }

  List<Widget> _buildLoadedSlivers(List<Store> allStores) {
    if (allStores.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: StoresStateMessage(
            icon: Icons.storefront_outlined,
            title: 'Нет магазинов',
            message: 'Скоро здесь появятся наши филиалы',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverToBoxAdapter(
          child: GlassTextField(
            controller: _searchController,
            hint: 'Поиск по названию или адресу',
            icon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() {
              _searchQuery = value;
              _filterStores(allStores);
            }),
            suffix: _searchQuery.isEmpty
                ? null
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _filterStores(allStores);
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 20,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        sliver: SliverToBoxAdapter(
          child: Text(
            '${allStores.length} ${storesWord(allStores.length)}'.toUpperCase(),
            style: AppTextStyles.overline,
          ),
        ),
      ),
      if (_filteredStores.isEmpty)
        const SliverToBoxAdapter(
          child: StoresStateMessage(
            icon: Icons.search_off_rounded,
            title: 'Ничего не найдено',
            message: 'Попробуйте изменить запрос',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: _filteredStores.length,
            itemBuilder: (context, index) {
              final store = _filteredStores[index];
              return StoreCard(
                store: store,
                distance: storeDistanceText(_userLocation, store),
                onTap: () => _openDetails(store),
              );
            },
          ),
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Map mode
  // ---------------------------------------------------------------------------

  Widget _buildMapView(List<Store> stores) {
    final topInset = MediaQuery.paddingOf(context).top;
    final storesWithCoords =
        stores.where((s) => s.lat != null && s.lng != null).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
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
              onTap: (_, _) {
                setState(() => _selectedStore = null);
                FocusScope.of(context).unfocus();
              },
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
                    final isSelected = _selectedStore?.id == store.id;
                    return Marker(
                      point: LatLng(store.lat!, store.lng!),
                      width: 60,
                      height: 60,
                      child: StoreMapMarker(
                        selected: isSelected,
                        onTap: () => _onStoreSelected(store),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Soft top scrim keeps the status bar legible over busy tiles.
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

          Positioned(
            top: topInset + 8,
            left: 20,
            right: 20,
            child: _buildModeSwitch(),
          ),

          Positioned(
            right: 16,
            top: topInset + 72,
            child: MapGlassControls(
              locating: _isLoadingLocation,
              onLocate: _centerOnUserLocation,
              onZoomIn: () => _zoom(1),
              onZoomOut: () => _zoom(-1),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: GlassTabBarMetrics.clearance(context) - 8,
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
              child: _selectedStore != null
                  ? Padding(
                      key: ValueKey('selected-${_selectedStore!.id}'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SelectedStoreCard(
                        store: _selectedStore!,
                        distance:
                            storeDistanceText(_userLocation, _selectedStore!),
                        onClose: () => setState(() => _selectedStore = null),
                        onDetails: () => _openDetails(_selectedStore!),
                      ),
                    )
                  : _buildStoreStrip(storesWithCoords),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreStrip(List<Store> stores) {
    if (stores.isEmpty) return const SizedBox.shrink(key: ValueKey('empty'));
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = stores.length == 1 ? width - 32 : (width - 32) * 0.82;
    return SizedBox(
      key: const ValueKey('strip'),
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        clipBehavior: Clip.none,
        itemCount: stores.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final store = stores[index];
          return SizedBox(
            width: cardWidth,
            child: StoreMiniCard(
              store: store,
              distance: storeDistanceText(_userLocation, store),
              onTap: () => _onStoreSelected(store),
            ),
          );
        },
      ),
    );
  }
}
