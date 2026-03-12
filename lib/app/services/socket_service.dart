import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'storage_service.dart';
import 'api_service.dart';

class SocketService extends ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void init() async {
    final token = await StorageService.getAccessToken();
    if (token == null) return;

    final baseUrl = ApiService.baseUrl.replaceFirst('/api/', '').replaceFirst('/api', '');
    
    socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .build());

    socket?.onConnect((_) {
      _isConnected = true;
      notifyListeners();
      if (kDebugMode) print('✅ Socket Connected');
    });

    socket?.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      if (kDebugMode) print('❌ Socket Disconnected');
    });

    socket?.onConnectError((err) {
      if (kDebugMode) print('⚠️ Socket Connect Error: $err');
    });

    // Listen for global notifications
    socket?.on('notification', (data) {
      if (kDebugMode) print('🔔 Socket Notification: $data');
      // Here you could trigger LocalNotificationService or update UI
    });
  }

  void joinProductRoom(String productId) {
    socket?.emit('join_product', productId);
    if (kDebugMode) print('🚪 Joined Room: Product $productId');
  }

  void leaveProductRoom(String productId) {
    socket?.emit('leave_product', productId);
    if (kDebugMode) print('🚶 Left Room: Product $productId');
  }

  void onBidUpdate(Function(Map<String, dynamic>) callback) {
    socket?.on('bid_updated', (data) {
      if (kDebugMode) print('💰 Bid Updated via Socket: $data');
      callback(Map<String, dynamic>.from(data));
    });
  }

  void disposeSocket() {
    socket?.dispose();
    socket = null;
    _isConnected = false;
  }
}

final socketService = SocketService();
