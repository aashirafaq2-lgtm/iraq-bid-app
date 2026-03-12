import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../models/product_model.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static const String _keyNotifications = 'local_notifications';
  static const String _keyLastProductId = 'last_notified_product_id';
  static const String _keyNotifiedWinIds = 'notified_win_ids';

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  List<NotificationModel> _notifications = [];

  Future<void> init() async {
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keyNotifications);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _notifications = jsonList.map((j) => NotificationModel.fromJson(j)).toList();
        // Sort by date descending (newest first)
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _updateUnreadCount();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading local notifications: $e');
      }
    }
  }

  void _updateUnreadCount() {
    unreadCountNotifier.value = _notifications.where((n) => !n.read).length;
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_keyNotifications, jsonString);
      _updateUnreadCount();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local notifications: $e');
      }
    }
  }

  List<NotificationModel> getNotifications({String? filter}) {
    if (filter == 'read') {
      return _notifications.where((n) => n.read).toList();
    } else if (filter == 'unread') {
      return _notifications.where((n) => !n.read).toList();
    }
    return List.from(_notifications);
  }

  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updated = NotificationModel(
        id: _notifications[index].id,
        type: _notifications[index].type,
        title: _notifications[index].title,
        message: _notifications[index].message,
        userId: _notifications[index].userId,
        read: true,
        createdAt: _notifications[index].createdAt,
      );
      _notifications[index] = updated;
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => NotificationModel(
      id: n.id,
      type: n.type,
      title: n.title,
      message: n.message,
      userId: n.userId,
      read: true,
      createdAt: n.createdAt,
    )).toList();
    await _saveNotifications();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final int newId = DateTime.now().millisecondsSinceEpoch;
    final notification = NotificationModel(
      id: newId,
      type: type, // 'product', 'win', 'bid'
      title: title,
      message: message,
      read: false,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notification); // Add to top
    await _saveNotifications();
  }

  // --- Trigger Logic ---

  // Check for new products
  Future<void> trackNewProduct(ProductModel latestProduct) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int lastId = prefs.getInt(_keyLastProductId) ?? 0;

      // Ensure we don't notify for the same product twice, and only if it's actually newer
      if (latestProduct.id > lastId) {
        // Simple check: if lastId was 0 (first run), maybe don't notify? 
        // Or notify just once "Welcome to BidMaster".
        // Let's assume on first run we record the ID but don't notify to avoid spamming notification on fresh install.
        
        if (lastId != 0) {
           await addNotification(
            title: 'New Product Available!',
            message: 'Check out the new item: ${latestProduct.title}',
            type: 'product',
          );
        }
        
        await prefs.setInt(_keyLastProductId, latestProduct.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking new product: $e');
      }
    }
  }

  // Check for wins
  Future<void> trackWin(int bidId, String productName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> notifiedWins = prefs.getStringList(_keyNotifiedWinIds) ?? [];
      
      final String bidIdStr = bidId.toString();
      if (!notifiedWins.contains(bidIdStr)) {
        await addNotification(
          title: 'Congratulations! You Won!',
          message: 'You have won the auction for $productName. Tap to view details.',
          type: 'win',
        );
        
        notifiedWins.add(bidIdStr);
        await prefs.setStringList(_keyNotifiedWinIds, notifiedWins);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking win: $e');
      }
    }
  }
}
