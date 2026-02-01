class AppConstants {
  AppConstants._();

  // OTP
  static const int otpLength = 4;
  static const int otpResendSeconds = 60;

  // Phone
  static const String phonePrefix = '+996';
  static const int phoneLength = 9;
  static const String phoneMask = '+996 (###) ## ## ##';

  // Animation
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Pagination
  static const int defaultPageSize = 20;
}
