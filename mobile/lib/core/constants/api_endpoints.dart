import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String _envUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    // A release build pointing at localhost would silently not work
    if (kReleaseMode) {
      throw StateError(
        'API_URL is not set: build with --dart-define=API_URL=https://...',
      );
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  /// Privacy policy page served by the backend at the site root.
  static String get privacyUrl =>
      '${baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '')}/privacy';

  // Auth
  static const String sendCode = '/auth/send-code';
  static const String verifyCode = '/auth/verify-code';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // User
  static const String userProfile = '/users/me';
  static const String addresses = '/addresses';
  static String addressById(String id) => '/addresses/$id';
  static String setDefaultAddress(String id) => '/addresses/$id/default';

  // Products
  static const String products = '/products';
  static const String categories = '/products/categories';

  // Orders
  static const String orders = '/orders';

  // Loyalty
  static const String loyalty = '/loyalty';
  static const String loyaltyHistory = '/loyalty/history';
  static const String punchCards = '/loyalty/punch-cards';
  static const String loyaltyQrToken = '/loyalty/qr-token';
  static const String orderPreview = '/orders/preview';
  static const String orderPaymentInfo = '/orders/payment-info';
  static const String referencePhoto = '/storage/reference-photo';

  // Promotions
  static const String promotions = '/promotions';

  // Stores
  static const String stores = '/stores';
}
