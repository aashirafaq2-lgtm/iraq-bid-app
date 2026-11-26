import 'fcm_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    await FcmNotificationService().init();
  }

  void logout() {}
}

final notificationService = NotificationService();
