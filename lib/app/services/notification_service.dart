import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // OneSignal App ID - You need to replace this with your actual ID from dashboard
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
      // Navigate to specific screen based on additionalData
      final data = event.notification.additionalData;
      if (data != null && data.containsKey('productId')) {
        // Use go_router to navigate if needed (requires a static navigator key or context)
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
