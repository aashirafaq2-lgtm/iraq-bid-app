import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

/// Utility class for network connectivity checking and error handling
class NetworkUtils {
  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // Check if device has any network connection (WiFi, mobile, ethernet, etc.)
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Even if connectivity shows connected, we should verify actual internet access
      // by checking if we can reach a reliable server
      return true;
    } catch (e) {
      // If connectivity check fails, assume no internet
      return false;
    }
  }

  /// Check if error is a network connectivity issue
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      // Check for connection-related errors
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.message?.toLowerCase().contains('connection refused') == true ||
          error.message?.toLowerCase().contains('connection timeout') == true ||
          error.message?.toLowerCase().contains('failed host lookup') == true ||
          error.message?.toLowerCase().contains('connection errored') == true ||
          error.message?.toLowerCase().contains('network is unreachable') == true ||
          error.message?.toLowerCase().contains('socketexception') == true ||
          error.message?.toLowerCase().contains('err_connection_refused') == true ||
          error.message?.toLowerCase().contains('err_connection_timed_out') == true ||
          error.message?.toLowerCase().contains('err_network_changed') == true ||
          error.message?.toLowerCase().contains('no internet') == true ||
          error.message?.toLowerCase().contains('network unavailable') == true ||
          (error.response?.statusCode == null && error.type == DioExceptionType.unknown);
    }
    return false;
  }

  /// Get user-friendly error message for network issues
  static String getNetworkErrorMessage(dynamic error) {
    if (isNetworkError(error)) {
      return 'No Internet Connection\n\nPlease turn on your internet connection and try again.';
    }
    
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection Timeout\n\nPlease check your internet connection and try again.';
      }
    }
    
    return 'Network Error\n\nPlease check your internet connection and try again.';
  }
}

