import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart' as di;
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_input_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../../features/loyalty/presentation/bloc/loyalty_bloc.dart';
import '../../features/loyalty/presentation/pages/loyalty_card_page.dart';
import '../../features/loyalty/presentation/pages/points_history_page.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/orders_list_page.dart';
import '../../features/products/presentation/bloc/products_bloc.dart';
import '../../features/products/presentation/bloc/products_event.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import '../../features/products/presentation/pages/products_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/promotions/presentation/bloc/promotions_bloc.dart';
import '../../features/promotions/presentation/pages/promotions_list_page.dart';
import '../../features/stores/domain/entities/store.dart';
import '../../features/stores/presentation/bloc/stores_bloc.dart';
import '../../features/stores/presentation/pages/store_details_page.dart';
import '../../features/stores/presentation/pages/stores_page.dart';
import '../../features/stores/presentation/pages/stores_map_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PhoneInputPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String;
          return OtpVerificationPage(phone: phone);
        },
      ),

      // Main app shell with persistent bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainPage(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          // Catalog tab
          GoRoute(
            path: '/catalog',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => di.sl<ProductsBloc>()..add(const LoadProducts()),
                child: const ProductsListPage(),
              ),
            ),
          ),
          // Category products
          GoRoute(
            path: '/catalog/:categoryId',
            pageBuilder: (context, state) {
              final categoryId = state.pathParameters['categoryId']!;
              final categoryName = state.extra as String?;
              return NoTransitionPage(
                child: BlocProvider(
                  create: (_) => di.sl<ProductsBloc>()
                    ..add(LoadProducts(categoryId: categoryId)),
                  child: ProductsListPage(
                    categoryId: categoryId,
                    categoryName: categoryName,
                  ),
                ),
              );
            },
          ),
          // Product details (inside shell - bottom nav visible)
          GoRoute(
            path: '/product/:id',
            pageBuilder: (context, state) {
              final productId = state.pathParameters['id']!;
              return MaterialPage(
                child: BlocProvider(
                  create: (_) => di.sl<ProductsBloc>()
                    ..add(LoadProductDetails(productId)),
                  child: ProductDetailsPage(productId: productId),
                ),
              );
            },
          ),
          // Cart tab
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CartPage(),
            ),
          ),
          // Profile tab
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
          // Orders
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => di.sl<OrdersBloc>()..add(const LoadOrders()),
                child: const OrdersListPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/orders/:id',
            pageBuilder: (context, state) {
              final orderId = state.pathParameters['id']!;
              return MaterialPage(
                child: BlocProvider(
                  create: (_) => di.sl<OrdersBloc>()
                    ..add(LoadOrderDetails(orderId)),
                  child: OrderDetailsPage(orderId: orderId),
                ),
              );
            },
          ),
          // Loyalty
          GoRoute(
            path: '/loyalty',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => di.sl<LoyaltyBloc>()..add(const LoadLoyaltyInfo()),
                child: const LoyaltyCardPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/loyalty/history',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => di.sl<LoyaltyBloc>()..add(const LoadLoyaltyHistory()),
                child: const PointsHistoryPage(),
              ),
            ),
          ),
          // Promotions
          GoRoute(
            path: '/promotions',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => di.sl<PromotionsBloc>()..add(const LoadPromotions()),
                child: const PromotionsListPage(),
              ),
            ),
          ),
          // Stores
          GoRoute(
            path: '/stores',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => di.sl<StoresBloc>()..add(const LoadStores()),
                child: const StoresPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/stores/:id',
            pageBuilder: (context, state) {
              final store = state.extra as Store;
              return MaterialPage(
                child: StoreDetailsPage(store: store),
              );
            },
          ),
          // Stores map
          GoRoute(
            path: '/stores-map',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BlocProvider(
                create: (_) => di.sl<StoresBloc>()..add(const LoadStores()),
                child: const StoresMapPage(),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
