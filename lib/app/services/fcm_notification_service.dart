import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
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

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'iraqbid_general',
    'Iraq Bid Notifications',
    description: 'Notifications for bids, auctions, wins, and updates',
    importance: Importance.high,
  );

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleNotificationClick(data);
          } catch (_) {}
        }
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    }
  }

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('🔥 Firebase Core successfully initialized');
      }

      // 1b. Initialize local notifications & Android channel
      await _initLocalNotifications();

      // 2. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Enable iOS foreground presentation
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Token refresh listener
      _fcm.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('🔄 [FCM Token Refreshed]: $newToken');
        }
        await _registerTokenWithBackend(newToken);
      });

      // 5. Foreground message listener (App is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('💬 [FCM Foreground]: ${message.notification?.title} - ${message.notification?.body}');
        }
        final notification = message.notification;
        final title = notification?.title ?? message.data['title']?.toString();
        final body = notification?.body ?? message.data['body']?.toString();
        if (title != null && body != null && Platform.isAndroid) {
          _localNotifications.show(
            message.hashCode,
            title,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel.id,
                _androidChannel.name,
                channelDescription: _androidChannel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@drawable/ic_notification',
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 6. Notification Click / Tap Handler (App in background or killed)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message.data);
      });

      // 7. Check if app was opened from a terminated state notification click
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage.data);
      }

      _initialized = true;
      await apiService.logFcmClientEvent('init_ok');
    } catch (e) {
      await apiService.logFcmClientEvent('init_err', detail: e.toString());
      if (kDebugMode) {
        print('⚠️ [FCM NotificationService Init Notice]: $e');
      }
    }
  }

  Future<void> requestPermissionAndSyncToken() async {
    try {
      await init();
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) {
        print('🔔 FCM Notification Permission Status: ${settings.authorizationStatus}');
      }
      await apiService.logFcmClientEvent('perm_${settings.authorizationStatus.name}');
      await registerCurrentToken();
    } catch (e) {
      await apiService.logFcmClientEvent('perm_sync_err', detail: e.toString());
      if (kDebugMode) {
        print('⚠️ [FCM Permission/Sync Notice]: $e');
      }
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('🖱️ [FCM Notification Clicked] data: $data');
    }
    try {
      final dest = data['destinationScreen'] ?? data['destination'] ?? data['screen'];
      final rawId = data['relatedId'] ?? data['productId'] ?? data['id'];
      final relatedId = (rawId != null && rawId.toString().trim().isNotEmpty) ? rawId.toString().trim() : null;

      if (dest == 'product' && relatedId != null) {
        AppRouter.router.push('/product-details/$relatedId');
      } else if (dest == 'vip_arena' || dest == 'vip') {
        final code = data['containerCode'] ?? '#G-102';
        AppRouter.router.push('/vip/arena?code=$code');
      } else if (dest == 'orders' || dest == 'wins') {
        AppRouter.router.push('/wins');
      } else if (dest == 'wallet') {
        AppRouter.router.push('/wallet');
      } else if (dest == 'auctions' || dest == 'home') {
        AppRouter.router.go('/home');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM navigation routing error: $e');
      }
    }
  }

  Future<void> registerCurrentToken() async {
    try {
      await init();
      final token = await _fcm.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('📱 [FCM Token]: $token');
        }
        await _registerTokenWithBackend(token);
      } else {
        await apiService.logFcmClientEvent('token_null');
      }
    } catch (e) {
      await apiService.logFcmClientEvent('get_token_err', detail: e.toString());
    }
  }

  Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await apiService.registerFcmToken(fcmToken, platform);
      if (kDebugMode) {
        print('✅ FCM Token successfully synced to Iraq Bid database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM Token sync failed: $e');
      }
    }
  }
}
