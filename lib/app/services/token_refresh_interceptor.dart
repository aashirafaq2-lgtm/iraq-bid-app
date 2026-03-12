import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'storage_service.dart';
import '../utils/jwt_utils.dart';

class TokenRefreshInterceptor extends Interceptor {
  final Dio _refreshDio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];
  // Base URL will be set dynamically via setBaseUrl() from ApiService
  // Default to live production URL
  String _baseUrl = 'https://api.mazaadati.com/api/';

  TokenRefreshInterceptor() : _refreshDio = Dio();

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _refreshDio.options.baseUrl = baseUrl;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Attach access token to all requests
    final accessToken = await StorageService.getAccessToken();
    
    if (kDebugMode) {
      print('🔍 [TokenInterceptor] onRequest:');
      print('   Path: ${options.path}');
      print('   Method: ${options.method}');
      print('   Has Access Token: ${accessToken != null}');
      if (accessToken != null) {
        print('   Token preview: ${accessToken.substring(0, 30)}...');
      }
    }
    
    if (accessToken != null) {
      // 🔧 FIX: Verify token role matches SharedPreferences role before API calls
      final storedRole = await StorageService.getUserRole();
      final tokenRole = JwtUtils.getRoleFromToken(accessToken);
      
      if (tokenRole != null && storedRole != null && tokenRole != storedRole) {
        if (kDebugMode) {
          print('⚠️⚠️⚠️ ROLE MISMATCH DETECTED BEFORE API CALL! ⚠️⚠️⚠️');
          print('   Token role: $tokenRole');
          print('   SharedPreferences role: $storedRole');
          print('   Request path: ${options.path}');
          print('   Request method: ${options.method}');
          print('   Attempting to refresh token to sync roles...');
        }
        try {
          final refreshToken = await StorageService.getRefreshToken();
          if (refreshToken != null) {
            _refreshDio.options.baseUrl = _baseUrl;
            final refreshResponse = await _refreshDio.post(
              'auth/refresh',
              data: {'refreshToken': refreshToken},
            );
            
            if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
              final newAccessToken = refreshResponse.data['accessToken'] as String;
              final newRefreshToken = refreshResponse.data['refreshToken'] as String;
              final newTokenRole = JwtUtils.getRoleFromToken(newAccessToken);
              
              // Save new tokens
              await StorageService.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );
              
              // Update SharedPreferences role to match new token role
              if (newTokenRole != null) {
                final userId = await StorageService.getUserId();
                final phone = await StorageService.getUserPhone();
                final name = await StorageService.getUserName();
                final email = await StorageService.getUserEmail();
                
                if (userId != null && phone != null) {
                  await StorageService.saveUserData(
                    userId: userId,
                    role: newTokenRole,
                    phone: phone,
                    name: name,
                    email: email,
                  );
                  if (kDebugMode) {
                    print('✅ Token refreshed and roles synced: $newTokenRole');
                  }
                  
                  // Use new token for this request
                  options.headers['Authorization'] = 'Bearer $newAccessToken';
                  handler.next(options);
                  return;
                }
              }
            }
          }
        } catch (refreshError) {
          if (kDebugMode) {
            print('❌ Token refresh failed: $refreshError');
            print('   Clearing storage and forcing re-login');
          }
          await StorageService.clearAll();
          
          // Reject the request - user needs to login again
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Role mismatch - please login again',
              type: DioExceptionType.unknown,
            ),
          );
          return;
        }
        
        // If refresh didn't work, clear storage and force re-login
        if (kDebugMode) {
          print('⚠️ Token refresh did not resolve mismatch - forcing re-login');
        }
        await StorageService.clearAll();
        handler.reject(
          DioException(
            requestOptions: options,
            error: 'Role mismatch - please login again',
            type: DioExceptionType.unknown,
          ),
        );
        return;
      }
      
      // Roles match - proceed with request
      options.headers['Authorization'] = 'Bearer $accessToken';
      if (kDebugMode) {
        print('✅ Token attached to request');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ No access token found - request will be unauthenticated');
        print('   This may cause 401 errors for protected routes');
      }
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final errorData = err.response?.data;
    final errorCode = errorData is Map ? errorData['error'] : null;

    // Check if it's a token expiration error
    if (errorCode == 'token_expired' || errorCode == 'invalid_token') {
      // If already refreshing, queue this request
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _pendingRequests.add(_PendingRequest(
          requestOptions: err.requestOptions,
          completer: completer,
        ));
        try {
          final response = await completer.future;
          handler.resolve(response);
        } catch (e) {
          handler.reject(err);
        }
        return;
      }

      // Start refresh process
      _isRefreshing = true;

      try {
        final refreshToken = await StorageService.getRefreshToken();
        
        if (refreshToken == null) {
          // No refresh token - clear storage and reject
          await StorageService.clearAll();
          _isRefreshing = false;
          _pendingRequests.clear();
          return handler.next(err);
        }

        // Attempt to refresh token
        _refreshDio.options.baseUrl = _baseUrl;
        final refreshResponse = await _refreshDio.post(
          'auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
          final newAccessToken = refreshResponse.data['accessToken'] as String;
          final newRefreshToken = refreshResponse.data['refreshToken'] as String;
          final newTokenRole = JwtUtils.getRoleFromToken(newAccessToken);

          // Save new tokens
          await StorageService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          
          // 🔧 FIX: Update SharedPreferences role to match new token role
          if (newTokenRole != null) {
            final storedRole = await StorageService.getUserRole();
            if (storedRole != null && storedRole != newTokenRole) {
              if (kDebugMode) {
                print('🔄 Updating SharedPreferences role to match token: $newTokenRole');
              }
              final userId = await StorageService.getUserId();
              final phone = await StorageService.getUserPhone();
              final name = await StorageService.getUserName();
              final email = await StorageService.getUserEmail();
              
              if (userId != null && phone != null) {
                await StorageService.saveUserData(
                  userId: userId,
                  role: newTokenRole,
                  phone: phone,
                  name: name,
                  email: email,
                );
                if (kDebugMode) {
                  print('✅ SharedPreferences role updated to match token: $newTokenRole');
                }
              }
            }
          }

          // Update original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          // Retry original request
          try {
            final response = await _refreshDio.fetch(err.requestOptions);
            
            // Resolve all pending requests
            for (var pending in _pendingRequests) {
              pending.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              try {
                final pendingResponse = await _refreshDio.fetch(pending.requestOptions);
                pending.completer.complete(pendingResponse);
              } catch (e) {
                pending.completer.completeError(e);
              }
            }
            _pendingRequests.clear();
            _isRefreshing = false;

            handler.resolve(response);
          } catch (retryError) {
            _isRefreshing = false;
            _pendingRequests.clear();
            handler.next(err);
          }
        } else {
          // Refresh failed - clear storage
          await StorageService.clearAll();
          _isRefreshing = false;
          _pendingRequests.clear();
          handler.next(err);
        }
      } catch (refreshError) {
        // Refresh failed - clear storage
        await StorageService.clearAll();
        _isRefreshing = false;
        _pendingRequests.clear();
        handler.next(err);
      }
    } else {
      // Not a token error - pass through
      handler.next(err);
    }
  }
}

class _PendingRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;

  _PendingRequest({
    required this.requestOptions,
    required this.completer,
  });
}

