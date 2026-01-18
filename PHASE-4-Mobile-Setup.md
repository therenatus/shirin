# ФАЗА 4: Flutter Mobile - Настройка и архитектура

## 🎯 Цели фазы
- Настроить Flutter проект
- Создать архитектуру Clean Architecture + BLoC
- Настроить цветовую схему и темы
- Настроить routing и DI
- Создать API client
- Реализовать Auth feature

## ⏱ Длительность: 5-7 дней

## 📋 Предварительные требования
- Flutter SDK установлен (3.16+)
- Android Studio / Xcode настроены
- Backend API работает

---

## 🚀 Инструкции для Claude Code

### Шаг 1: Создание Flutter проекта

```bash
cd mobile

# Создай Flutter проект
flutter create . --org kg.shirin --platforms=android,ios

# Создай структуру папок
mkdir -p lib/core/constants
mkdir -p lib/core/network
mkdir -p lib/core/storage
mkdir -p lib/core/utils
mkdir -p lib/core/error
mkdir -p lib/features/auth/data/models
mkdir -p lib/features/auth/data/datasources
mkdir -p lib/features/auth/data/repositories
mkdir -p lib/features/auth/domain/entities
mkdir -p lib/features/auth/domain/usecases
mkdir -p lib/features/auth/domain/repositories
mkdir -p lib/features/auth/presentation/bloc
mkdir -p lib/features/auth/presentation/pages
mkdir -p lib/features/auth/presentation/widgets
mkdir -p lib/shared/widgets
```

---

### Шаг 2: Настройка pubspec.yaml

**Файл: `mobile/pubspec.yaml`**

```yaml
name: shirin_app
description: Мобильное приложение кондитерской Ширин
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Network
  dio: ^5.4.0
  retrofit: ^4.0.3
  pretty_dio_logger: ^1.3.1
  
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  
  # UI
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  lottie: ^3.0.0
  carousel_slider: ^4.2.1
  
  # QR Code
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.5
  
  # Maps
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Chat
  socket_io_client: ^2.0.3
  
  # Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
  
  # Image Picker
  image_picker: ^1.0.5
  
  # URL Launcher
  url_launcher: ^6.2.2
  
  # Utilities
  intl: ^0.18.1
  get_it: ^7.6.4
  auto_route: ^7.8.4
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  retrofit_generator: ^8.0.4
  auto_route_generator: ^7.3.2
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

**Установи зависимости:**

```bash
flutter pub get
```

---

### Шаг 3: Создание цветовой схемы

**Файл: `lib/core/constants/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (из логотипа Ширин)
  static const Color primary = Color(0xFFD81B60);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color primaryLight = Color(0xFFFF5C8D);
  
  // Secondary colors
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFF8BBD0);
  
  // Background
  static const Color background = Color(0xFFFFF5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFF0F3);
  
  // Text
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Other
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  
  AppColors._();
}
```

**Файл: `lib/core/constants/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
  
  AppTheme._();
}
```

---

### Шаг 4: Настройка API Client

**Файл: `lib/core/network/api_config.dart`**

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api/v1'; // iOS simulator
  // static const String baseUrl = 'https://api.shirin.kg/api/v1'; // Production
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  ApiConfig._();
}
```

**Файл: `lib/core/network/dio_client.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to requests
          final token = await _secureStorage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 (unauthorized)
          if (error.response?.statusCode == 401) {
            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry original request
              return handler.resolve(await _retry(error.requestOptions));
            }
          }
          return handler.next(error);
        },
      ),
    );
    
    // Add logger in debug mode
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
  }
  
  Dio get dio => _dio;
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];
      
      await _secureStorage.write(key: 'access_token', value: newAccessToken);
      await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
      
      return true;
    } catch (e) {
      await _secureStorage.deleteAll();
      return false;
    }
  }
  
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
```

---

### Шаг 5: Настройка Dependency Injection

**Файл: `lib/core/di/injection_container.dart`**

```dart
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => DioClient());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  
  // TODO: Register features dependencies here
}
```

---

### Шаг 6: Создание Auth Feature

**Файл: `lib/features/auth/data/models/user_model.dart`**

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

class UserModel extends Equatable {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final int loyaltyPoints;
  final String qrCode;
  
  const UserModel({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    required this.loyaltyPoints,
    required this.qrCode,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phone: json['phone'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      loyaltyPoints: json['loyaltyPoints'],
      qrCode: json['qrCode'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'loyaltyPoints': loyaltyPoints,
      'qrCode': qrCode,
    };
  }
  
  User toEntity() {
    return User(
      id: id,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      loyaltyPoints: loyaltyPoints,
      qrCode: qrCode,
    );
  }
  
  @override
  List<Object?> get props => [id, phone, firstName, lastName, loyaltyPoints, qrCode];
}
```

**Файл: `lib/features/auth/domain/entities/user.dart`**

```dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final int loyaltyPoints;
  final String qrCode;
  
  const User({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    required this.loyaltyPoints,
    required this.qrCode,
  });
  
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return phone;
  }
  
  @override
  List<Object?> get props => [id, phone, firstName, lastName, loyaltyPoints, qrCode];
}
```

**Файл: `lib/features/auth/data/datasources/auth_remote_datasource.dart`**

```dart
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendCode(String phone);
  Future<AuthResponse> verifyCode(String phone, String code);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
  
  AuthRemoteDataSourceImpl({required this.dioClient});
  
  @override
  Future<void> sendCode(String phone) async {
    await dioClient.dio.post('/auth/send-code', data: {'phone': phone});
  }
  
  @override
  Future<AuthResponse> verifyCode(String phone, String code) async {
    final response = await dioClient.dio.post(
      '/auth/verify-code',
      data: {'phone': phone, 'code': code},
    );
    
    return AuthResponse.fromJson(response.data);
  }
  
  @override
  Future<void> logout() async {
    await dioClient.dio.post('/auth/logout');
  }
}

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  
  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}
```

**Файл: `lib/features/auth/data/datasources/auth_local_datasource.dart`**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> cacheTokens(String accessToken, String refreshToken);
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  
  AuthLocalDataSourceImpl({required this.secureStorage});
  
  @override
  Future<void> cacheTokens(String accessToken, String refreshToken) async {
    await secureStorage.write(key: 'access_token', value: accessToken);
    await secureStorage.write(key: 'refresh_token', value: refreshToken);
  }
  
  @override
  Future<void> cacheUser(UserModel user) async {
    await secureStorage.write(
      key: 'user',
      value: jsonEncode(user.toJson()),
    );
  }
  
  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = await secureStorage.read(key: 'user');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }
  
  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: 'access_token');
  }
  
  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: 'refresh_token');
  }
  
  @override
  Future<void> clearCache() async {
    await secureStorage.deleteAll();
  }
}
```

**Файл: `lib/features/auth/data/repositories/auth_repository_impl.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
  Future<Either<Failure, void>> sendCode(String phone) async {
    try {
      await remoteDataSource.sendCode(phone);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, User>> verifyCode(String phone, String code) async {
    try {
      final response = await remoteDataSource.verifyCode(phone, code);
      
      await localDataSource.cacheTokens(
        response.accessToken,
        response.refreshToken,
      );
      await localDataSource.cacheUser(response.user);
      
      return Right(response.user.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getCachedUser();
      if (userModel != null) {
        return Right(userModel.toEntity());
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
```

**Создай файлы для domain layer:**

- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/domain/usecases/send_code.dart`
- `lib/features/auth/domain/usecases/verify_code.dart`
- `lib/features/auth/domain/usecases/get_current_user.dart`
- `lib/features/auth/domain/usecases/logout.dart`

**Создай BLoC:**

- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/presentation/bloc/auth_event.dart`
- `lib/features/auth/presentation/bloc/auth_state.dart`

---

### Шаг 7: Создание основного app.dart

**Файл: `lib/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';

class ShirinApp extends StatelessWidget {
  const ShirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatus()),
        ),
      ],
      child: MaterialApp(
        title: 'Ширин',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}
```

**Файл: `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await di.init();
  
  runApp(const ShirinApp());
}
```

---

## ✅ Критерии приемки Фазы 4

- [ ] Flutter проект создан и структура настроена
- [ ] Зависимости установлены
- [ ] Цветовая схема настроена (розовые тона)
- [ ] Темы приложения настроены
- [ ] DioClient с interceptors создан
- [ ] Dependency Injection (GetIt) настроен
- [ ] Auth feature data layer создан
- [ ] Auth feature domain layer создан
- [ ] Приложение компилируется без ошибок
- [ ] Можно запустить на эмуляторе/симуляторе

---

## 📝 Коммит изменений

```bash
git add mobile/
git commit -m "Phase 4: Flutter setup - Architecture, Theme, DI, Auth feature structure"
```

---

## ➡️ Следующая фаза

После завершения Фазы 4, переходи к **PHASE-5-Mobile-Core-Features.md** для реализации основных UI экранов (Auth, Home, Products, Cart, Profile).
