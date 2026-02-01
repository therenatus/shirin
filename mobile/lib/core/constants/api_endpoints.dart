import 'dart:io';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

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
  static String claimFreeCoffee(String size) => '/loyalty/punch-cards/$size/claim';

  // Promotions
  static const String promotions = '/promotions';

  // Stores
  static const String stores = '/stores';
}
