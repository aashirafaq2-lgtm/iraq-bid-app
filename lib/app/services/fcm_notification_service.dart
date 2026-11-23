import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../router/app_router.dart';

// Background message handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('🌙 [FCM Background Message]: ${message.messageId} | ${message.notification?.title}');
  }
}

class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('🔥 Firebase Core successfully initialized');
      }

      // 2. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request User Permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('🔔 FCM Notification Permission Granted: ${settings.authorizationStatus}');
        }

        // 4. Retrieve FCM Device Token
        final token = await _fcm.getToken();
        if (token != null) {
          if (kDebugMode) {
            print('📱 [FCM Token]: $token');
          }
          await _registerTokenWithBackend(token);
        }

        // 5. Token refresh listener
        _fcm.onTokenRefresh.listen((newToken) async {
          if (kDebugMode) {
            print('🔄 [FCM Token Refreshed]: $newToken');
          }
          await _registerTokenWithBackend(newToken);
        });

        // 6. Foreground message listener (App is open)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('💬 [FCM Foreground]: ${message.notification?.title} - ${message.notification?.body}');
          }
        });

        // 7. Notification Click / Tap Handler (App in background or killed)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationClick(message.data);
        });

        // Check if app was opened from a terminated state notification click
        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationClick(initialMessage.data);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM NotificationService Init Notice]: $e');
      }
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('🖱️ [FCM Notification Clicked] data: $data');
    }
    try {
      final dest = data['destinationScreen'] ?? data['screen'];
      final relatedId = data['relatedId'] ?? data['productId'] ?? data['id'];

      if (dest == 'product' && relatedId != null) {
        AppRouter.router.push('/product-details/$relatedId');
      } else if (dest == 'vip_arena' || dest == 'vip') {
        final code = data['containerCode'] ?? '#G-102';
        AppRouter.router.push('/vip/arena?code=$code');
      } else if (dest == 'orders' || dest == 'wins') {
        AppRouter.router.push('/wins');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM navigation routing error: $e');
      }
    }
  }

  Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      final token = await StorageService.getToken();
      final userId = await StorageService.getUserId();
      if (userId == null) return;

      final platform = Platform.isIOS ? 'ios' : 'android';
      await apiService.registerFcmToken(fcmToken, platform);
      if (kDebugMode) {
        print('✅ FCM Token successfully synced to Iraq Bid database for user: $userId');
      }
    } catch (e) {
      // Background retry on next launch
    }
  }
}
