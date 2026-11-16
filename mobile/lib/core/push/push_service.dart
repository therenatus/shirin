import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../features/notifications/data/notifications_repository.dart';

/// Push notifications through Firebase Cloud Messaging.
///
/// Firebase needs the project's config files (GoogleService-Info.plist for
/// iOS, google-services.json for Android). Without them [init] leaves push
/// disabled and the app works as before: notifications are still listed in
/// the app, they just don't pop up.
class PushService {
  final NotificationsRepository _repository;
  bool _enabled = false;
  StreamSubscription<String>? _tokenRefresh;

  /// Called when a push arrives while the app is open.
  void Function(RemoteMessage message)? onForegroundMessage;

  /// Called with the order id when the user taps a push about an order.
  void Function(String orderId)? onOpenOrder;

  PushService(this._repository);

  bool get enabled => _enabled;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _enabled = true;
    } catch (e) {
      debugPrint('Push disabled: Firebase is not configured ($e)');
      return;
    }

    FirebaseMessaging.onMessage.listen((m) => onForegroundMessage?.call(m));
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    // App launched by tapping a push while it was closed
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Let the first screen build before navigating
      Future.delayed(
        const Duration(milliseconds: 600),
        () => _handleTap(initial),
      );
    }
  }

  void _handleTap(RemoteMessage message) {
    final orderId = message.data['orderId'];
    if (orderId is String && orderId.isNotEmpty) onOpenOrder?.call(orderId);
  }

  /// After sign-in: ask permission (iOS) and send this device's token.
  Future<void> registerForUser() async {
    if (!_enabled) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await _repository.registerPushToken(token);
      await _tokenRefresh?.cancel();
      _tokenRefresh = messaging.onTokenRefresh.listen(
        _repository.registerPushToken,
      );
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Signed out: stop following token changes (the server forgets the token).
  Future<void> unregister() async {
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
  }
}
