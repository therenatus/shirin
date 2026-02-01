import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../network/api_interceptors.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/send_code.dart';
import '../../features/auth/domain/usecases/verify_code.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/loyalty/data/datasources/loyalty_remote_datasource.dart';
import '../../features/loyalty/data/repositories/loyalty_repository_impl.dart';
import '../../features/loyalty/domain/repositories/loyalty_repository.dart';
import '../../features/loyalty/domain/usecases/get_loyalty_history.dart';
import '../../features/loyalty/domain/usecases/get_loyalty_info.dart';
import '../../features/loyalty/domain/usecases/get_punch_cards.dart';
import '../../features/loyalty/domain/usecases/claim_free_coffee.dart';
import '../../features/loyalty/presentation/bloc/loyalty_bloc.dart';
import '../../features/loyalty/presentation/bloc/punch_cards_bloc.dart';
import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/get_order_by_id.dart';
import '../../features/orders/domain/usecases/get_orders.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/products/data/datasources/products_remote_datasource.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/domain/repositories/products_repository.dart';
import '../../features/products/domain/usecases/get_categories.dart';
import '../../features/products/domain/usecases/get_product_by_id.dart';
import '../../features/products/domain/usecases/get_products.dart';
import '../../features/products/presentation/bloc/products_bloc.dart';
import '../../features/promotions/data/datasources/promotions_remote_datasource.dart';
import '../../features/promotions/data/repositories/promotions_repository_impl.dart';
import '../../features/promotions/domain/repositories/promotions_repository.dart';
import '../../features/promotions/domain/usecases/get_promotions.dart';
import '../../features/promotions/presentation/bloc/promotions_bloc.dart';
import '../../features/stores/data/datasources/stores_remote_datasource.dart';
import '../../features/stores/data/repositories/stores_repository_impl.dart';
import '../../features/stores/domain/repositories/stores_repository.dart';
import '../../features/stores/domain/usecases/get_stores.dart';
import '../../features/stores/presentation/bloc/stores_bloc.dart';
import '../../features/addresses/data/datasources/addresses_remote_datasource.dart';
import '../../features/addresses/data/repositories/addresses_repository_impl.dart';
import '../../features/addresses/domain/repositories/addresses_repository.dart';
import '../../features/addresses/domain/usecases/get_addresses.dart';
import '../../features/addresses/domain/usecases/create_address.dart';
import '../../features/addresses/domain/usecases/update_address.dart';
import '../../features/addresses/domain/usecases/delete_address.dart';
import '../../features/addresses/domain/usecases/set_default_address.dart';
import '../../features/addresses/presentation/bloc/addresses_bloc.dart';
import '../../features/orders/domain/usecases/create_order.dart';
import '../../features/auth/domain/usecases/update_profile.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(sl()),
  );
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(authInterceptor: sl()),
  );

  // Auth - Data Sources
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDatasource>(
    () => AuthLocalDatasourceImpl(sl()),
  );

  // Auth - Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  // Auth - Use Cases
  sl.registerLazySingleton(() => SendCode(sl()));
  sl.registerLazySingleton(() => VerifyCode(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  // Auth - BLoC
  sl.registerFactory(
    () => AuthBloc(
      sendCode: sl(),
      verifyCode: sl(),
      getCurrentUser: sl(),
      logout: sl(),
    ),
  );

  // Products - Data Sources
  sl.registerLazySingleton<ProductsRemoteDatasource>(
    () => ProductsRemoteDatasourceImpl(sl()),
  );

  // Products - Repository
  sl.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(sl()),
  );

  // Products - Use Cases
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => GetProductById(sl()));

  // Products - BLoC
  sl.registerFactory(
    () => ProductsBloc(
      getProducts: sl(),
      getCategories: sl(),
      getProductById: sl(),
    ),
  );

  // Cart
  sl.registerLazySingleton(() => CartLocalDatasource());
  sl.registerFactory(() => CartBloc(sl()));

  // Home - BLoC
  sl.registerFactory(
    () => HomeBloc(
      getCategories: sl(),
      getProducts: sl(),
    ),
  );

  // Orders - Data Sources
  sl.registerLazySingleton<OrdersRemoteDatasource>(
    () => OrdersRemoteDatasourceImpl(sl()),
  );

  // Orders - Repository
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(
      sl<OrdersRemoteDatasource>(),
      sl<AuthLocalDatasource>(),
    ),
  );

  // Orders - Use Cases
  sl.registerLazySingleton(() => GetOrders(sl()));
  sl.registerLazySingleton(() => GetOrderById(sl()));
  sl.registerLazySingleton(() => CreateOrder(sl()));

  // Orders - BLoC
  sl.registerFactory(
    () => OrdersBloc(getOrders: sl(), getOrderById: sl()),
  );

  // Loyalty - Data Sources
  sl.registerLazySingleton<LoyaltyRemoteDatasource>(
    () => LoyaltyRemoteDatasourceImpl(sl()),
  );

  // Loyalty - Repository
  sl.registerLazySingleton<LoyaltyRepository>(
    () => LoyaltyRepositoryImpl(
      sl<LoyaltyRemoteDatasource>(),
      sl<AuthLocalDatasource>(),
    ),
  );

  // Loyalty - Use Cases
  sl.registerLazySingleton(() => GetLoyaltyInfo(sl()));
  sl.registerLazySingleton(() => GetLoyaltyHistory(sl()));
  sl.registerLazySingleton(() => GetPunchCards(sl()));
  sl.registerLazySingleton(() => ClaimFreeCoffee(sl()));

  // Loyalty - BLoC
  sl.registerFactory(
    () => LoyaltyBloc(getLoyaltyInfo: sl(), getLoyaltyHistory: sl()),
  );

  // Punch Cards - BLoC
  sl.registerFactory(
    () => PunchCardsBloc(getPunchCards: sl(), claimFreeCoffee: sl()),
  );

  // Promotions - Data Sources
  sl.registerLazySingleton<PromotionsRemoteDatasource>(
    () => PromotionsRemoteDatasourceImpl(sl()),
  );

  // Promotions - Repository
  sl.registerLazySingleton<PromotionsRepository>(
    () => PromotionsRepositoryImpl(
      sl<PromotionsRemoteDatasource>(),
      sl<AuthLocalDatasource>(),
    ),
  );

  // Promotions - Use Cases
  sl.registerLazySingleton(() => GetPromotions(sl()));

  // Promotions - BLoC
  sl.registerFactory(
    () => PromotionsBloc(getPromotions: sl()),
  );

  // Stores - Data Sources
  sl.registerLazySingleton<StoresRemoteDatasource>(
    () => StoresRemoteDatasourceImpl(sl()),
  );

  // Stores - Repository
  sl.registerLazySingleton<StoresRepository>(
    () => StoresRepositoryImpl(
      sl<StoresRemoteDatasource>(),
      sl<AuthLocalDatasource>(),
    ),
  );

  // Stores - Use Cases
  sl.registerLazySingleton(() => GetStores(sl()));

  // Stores - BLoC
  sl.registerFactory(
    () => StoresBloc(getStores: sl()),
  );

  // Addresses - Data Sources
  sl.registerLazySingleton<AddressesRemoteDatasource>(
    () => AddressesRemoteDatasourceImpl(sl()),
  );

  // Addresses - Repository
  sl.registerLazySingleton<AddressesRepository>(
    () => AddressesRepositoryImpl(
      sl<AddressesRemoteDatasource>(),
      sl<AuthLocalDatasource>(),
    ),
  );

  // Addresses - Use Cases
  sl.registerLazySingleton(() => GetAddresses(sl()));
  sl.registerLazySingleton(() => CreateAddress(sl()));
  sl.registerLazySingleton(() => UpdateAddress(sl()));
  sl.registerLazySingleton(() => DeleteAddress(sl()));
  sl.registerLazySingleton(() => SetDefaultAddress(sl()));

  // Addresses - BLoC
  sl.registerFactory(
    () => AddressesBloc(
      getAddresses: sl(),
      createAddress: sl(),
      updateAddress: sl(),
      deleteAddress: sl(),
      setDefaultAddress: sl(),
    ),
  );
}
