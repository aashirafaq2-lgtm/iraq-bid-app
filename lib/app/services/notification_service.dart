import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../router/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // TODO: Replace with your actual OneSignal App ID from https://app.onesignal.com
  // Steps: OneSignal Dashboard → Your App → Settings → Keys & IDs → OneSignal App ID
  static const String _appId = "YOUR_ONESIGNAL_APP_ID";

  Future<void> init() async {
    // Debugging
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    // Initialize OneSignal
    OneSignal.initialize(_appId);

    // Request permissions
    OneSignal.Notifications.requestPermission(true);

    // Handle incoming notifications when app is open
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      if (kDebugMode) {
        print('🔔 OneSignal Foreground Notification: ${event.notification.title}');
      }
      // You can choose to show it or not
      // event.preventDefault() to stop notification, otherwise it shows automatically
    });

    // Handle notification clicks
    OneSignal.Notifications.addClickListener((event) {
      if (kDebugMode) {
        print('🖱️ OneSignal Notification Clicked: ${event.notification.title}');
      }
      // Navigate to product details screen if productId is available
      final data = event.notification.additionalData;
      if (data != null && data.containsKey('productId')) {
        final productId = data['productId'].toString();
        // Use GoRouter to navigate to product details
        try {
          AppRouter.router.push('/product-details/$productId');
        } catch (e) {
          if (kDebugMode) {
            print('❌ Navigation error on notification click: $e');
          }
        }
      }
    });

    // Link user phone/ID for targeted notifications
    await _linkUser();
  }

  Future<void> _linkUser() async {
    final userId = await StorageService.getUserId();
    final phone = await StorageService.getUserPhone();
    
    if (userId != null) {
      OneSignal.login(userId.toString());
      if (phone != null) {
        // External ID helps target specific users from backend
        OneSignal.User.addAlias("phone", phone);
      }
    }
  }

  void logout() {
    OneSignal.logout();
  }
}

final notificationService = NotificationService();
