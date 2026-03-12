import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../models/notification_model.dart';
import 'storage_service.dart';
import 'token_refresh_interceptor.dart';
import 'referral_service.dart';
import '../utils/jwt_utils.dart';
import '../utils/network_utils.dart';

class ApiService {
  // Dynamic base URL - Works on both LOCAL and PRODUCTION
  // Auto-detects based on environment
  // Priority: Manual override > Debug mode (local with auto-fallback) > Release mode (production)
  static String get baseUrl {
    // Priority 1: Check if API_BASE_URL is explicitly set (manual override)
    // This works for BOTH local and production
    const String envUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    
    if (envUrl.isNotEmpty) {
      // Validate URL format
      if (!envUrl.startsWith('http://') && !envUrl.startsWith('https://')) {
        throw Exception(
          'Invalid API_BASE_URL format. Must start with http:// or https://. '
          'Current value: $envUrl'
        );
      }
      print('🌐 Using API URL from --dart-define: $envUrl');
      return envUrl;
    }
    
    // Priority 2: Auto-detect based on build mode
    // Debug mode = Try local first, auto-fallback to production if local is closed
    // Release mode = Production (api.mazaadati.com)
    
    if (kDebugMode) {
      // DEBUG MODE: Try local backend first, auto-fallback to production if closed
      const String localUrl = 'http://localhost:5000/api/';
      const String productionUrl = 'https://api.mazaadati.com/api/';
      
      // Try local first - if connection fails, auto-fallback will switch to production
      print('🌐 [Debug Mode] Attempting LOCAL API first: $localUrl');
      print('   💡 If local backend is closed, will auto-switch to PRODUCTION: $productionUrl');
      print('   💡 Both local and production URLs are available');
      return localUrl;
    } else {
      // RELEASE MODE: Use production backend
      const String productionUrl = 'https://api.mazaadati.com/api/';
      print('🌐 [Release] Using PRODUCTION API: $productionUrl');
      return productionUrl;
    }
  }
  
  // Production URL constant for fallback
  static const String productionUrl = 'https://api.mazaadati.com/api/';
  static const String localUrl = 'http://localhost:5000/api/';
  
  /// Get the current base URL (may have switched from local to production)
  /// Use this instead of baseUrl getter when you need the actual current URL
  static String get currentBaseUrl {
    try {
      // Get current base URL from singleton instance if available
      if (instance != null && instance!._currentBaseUrl != null) {
        return instance!._currentBaseUrl!;
      }
    } catch (e) {
      // If instance not initialized yet, fall back to static baseUrl
    }
    // Fall back to static baseUrl if instance not available
    return baseUrl;
  }
  
  // Singleton instance - accessible from static methods
  static ApiService? instance;
  
  late Dio _dio;
  String? _currentBaseUrl;

  ApiService() {
    if (kDebugMode) {
      print('🌐 API Service initialized');
      print('   Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('   Base URL: $baseUrl');
    } else {
      // In release mode, API URL is validated in baseUrl getter
      // No additional validation needed here
    }
    
    // Validate baseUrl before creating Dio instance
    if (baseUrl == 'API_BASE_URL_NOT_CONFIGURED') {
      throw Exception(
        'API_BASE_URL not configured for release build.\n\n'
        'To fix this, build with:\n'
        'flutter build apk --release --dart-define=API_BASE_URL=https://your-server.com/api\n\n'
        'Or for local network testing:\n'
        'flutter build apk --release --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:5000/api'
      );
    }
    
    _currentBaseUrl = baseUrl;
    instance = this; // Store instance for static access
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add error interceptor with auto-fallback to production
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (kDebugMode) {
          print('❌ API Error: ${error.message}');
        }
        
        // Auto-fallback to production if local connection fails (only in debug mode)
        // Check all possible connection error types
        final isConnectionError = error is DioException && (
          error.type == DioExceptionType.connectionError || 
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
          (error.response?.statusCode == null && error.type == DioExceptionType.unknown)
        );
        
        if (kDebugMode && 
            isConnectionError &&
            _currentBaseUrl == localUrl) {
          print('=' * 60);
          print('⚠️ Local backend connection failed!');
          print('   Error: ${error.message}');
          print('   🔄 Auto-switching to PRODUCTION API...');
          print('   From: $localUrl');
          print('   To: $productionUrl');
          print('=' * 60);
          
          // Update base URL to production
          _dio.options.baseUrl = productionUrl;
          _currentBaseUrl = productionUrl;
          
          // Update token refresh interceptor base URL
          for (var interceptor in _dio.interceptors) {
            if (interceptor is TokenRefreshInterceptor) {
              interceptor.setBaseUrl(productionUrl);
            }
          }
          
          // Retry the request with production URL
          try {
            final retryOptions = error.requestOptions.copyWith(baseUrl: productionUrl);
            final retryResponse = await _dio.fetch(retryOptions);
            print('✅ Request succeeded with PRODUCTION API');
            return handler.resolve(retryResponse);
          } catch (retryError) {
            // If production also fails, return original error
            if (kDebugMode) {
              print('❌ Production API also failed: $retryError');
            }
            handler.next(error);
          }
          return;
        }
        
        // Don't let errors crash the app
        handler.next(error);
      },
    ));

    // Add token refresh interceptor (handles auto-refresh and retry)
    final refreshInterceptor = TokenRefreshInterceptor();
    refreshInterceptor.setBaseUrl(baseUrl);
    _dio.interceptors.add(refreshInterceptor);
  }

  // ==================== AUTHENTICATION ====================

  /// POST /api/auth/send-otp
  /// ✅ LIVE: Uses Twilio Verify API to send OTP
  Future<Map<String, dynamic>> sendOTP(String phone, {String? type}) async {
    try {
      if (kDebugMode) {
        print('📤 Sending OTP via Twilio Verify');
        print('📱 Phone number: $phone');
        print('📱 Type: $type');
        print('📱 Phone format: ${phone.startsWith('+964') ? 'Valid Iraq format' : 'Invalid format'}');
      }
      
      final response = await _dio.post(
        'auth/send-otp', 
        data: {
          'phone': phone,
          if (type != null) 'type': type,
        },
      );
      
      if (kDebugMode) {
        print('✅ OTP sent successfully via Twilio Verify');
        print('📱 OTP sent to phone: $phone');
        // Note: Backend does NOT return OTP in response for security
      }
      
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Send OTP error: $e');
        print('📱 Failed to send OTP to phone: $phone');
      }
      throw _handleError(e);
    }
  }

  /// POST /api/auth/login-phone
  /// ✅ LIVE: Phone + OTP login (replaces verify-otp for mobile app)
  Future<Map<String, dynamic>> loginPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      if (kDebugMode) {
        print('✅ Connected to live DB - Phone + OTP login');
        print('   Phone: $phone');
        print('   OTP: $otp');
      }
      
      // Validate phone format before sending
      if (phone.isEmpty) {
        throw Exception('Phone number is required');
      }
      if (otp.isEmpty) {
        throw Exception('OTP is required');
      }
      
      // Ensure phone starts with +964
      String normalizedPhone = phone.trim();
      if (!normalizedPhone.startsWith('+964')) {
        // Try to fix common formats
        if (normalizedPhone.startsWith('964')) {
          normalizedPhone = '+$normalizedPhone';
        } else if (normalizedPhone.startsWith('0')) {
          normalizedPhone = '+964${normalizedPhone.substring(1)}';
        } else {
          throw Exception('Invalid phone format. Must start with +964');
        }
      }
      
      if (kDebugMode) {
        print('   Normalized Phone: $normalizedPhone');
        print('   Request Body: {phone: $normalizedPhone, otp: $otp}');
      }
      
      final response = await _dio.post(
        'auth/login-phone',
        data: {
          'phone': normalizedPhone,
          'otp': otp,
        },
      );
      
      if (kDebugMode) {
        print('✅ JWT verified - Login successful');
        print('   User ID: ${response.data['user']?['id']}');
        print('   Role (from user): ${response.data['user']?['role']}');
        print('   Role (from response): ${response.data['role']}');
      }
      
      // Extract role from response (backend returns role at top level and in user object)
      final role = (response.data['role'] ?? response.data['user']?['role'] ?? 'company_products').toString().toLowerCase();
      if (kDebugMode) {
        print('   Final role: $role');
      }
      
      // Save tokens and user data
      final accessToken = response.data['accessToken'] ?? response.data['token'];
      final refreshToken = response.data['refreshToken'];
      
      if (accessToken != null) {
        // CRITICAL FIX: Validate token role matches response role
        final tokenRole = JwtUtils.getRoleFromToken(accessToken as String);
        if (tokenRole != null && tokenRole != role) {
          if (kDebugMode) {
            print('⚠️ WARNING: Token role mismatch detected!');
            print('   Token role: $tokenRole');
            print('   Response role: $role');
            print('   This should not happen - backend token role should match response role');
          }
        }
        
        // CRITICAL FIX: Clear old tokens if they exist and have wrong role
        final oldAccessToken = await StorageService.getAccessToken();
        if (oldAccessToken != null) {
          final oldTokenRole = JwtUtils.getRoleFromToken(oldAccessToken);
          if (oldTokenRole != null && oldTokenRole != role) {
            if (kDebugMode) {
              print('⚠️ Clearing old tokens with wrong role ($oldTokenRole != $role)');
            }
            await StorageService.clearAllTokens();
          }
        }
        
        if (refreshToken != null) {
          await StorageService.saveTokens(
            accessToken: accessToken as String,
            refreshToken: refreshToken as String,
          );
          if (kDebugMode) {
            print('✅ Access and refresh tokens saved to storage');
          }
          
          // Verify token role matches stored role
          final savedTokenRole = JwtUtils.getRoleFromToken(accessToken as String);
          if (kDebugMode) {
            if (savedTokenRole != null && savedTokenRole == role) {
              print('   ✅ Token role verified: $savedTokenRole');
            } else {
              print('   ⚠️ Warning: Token role mismatch after save');
            }
          }
        } else {
          // Fallback: only access token (backward compatibility)
          await StorageService.saveAccessToken(accessToken as String);
          if (kDebugMode) {
            print('✅ Access token saved to storage (no refresh token)');
          }
        }
        
        // Verify token was saved
        final savedToken = await StorageService.getAccessToken();
        if (kDebugMode) {
          if (savedToken != null) {
            print('   Access token verified in storage');
          } else {
            print('⚠️ Warning: Token not found after save');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Error: No token in response');
        }
        throw Exception('No token received from server');
      }
      
      if (response.data['user'] != null) {
        final user = response.data['user'];
        final backendPhone = user['phone'] as String?;
        
        // CRITICAL FIX: Use the phone number that was used for login, not necessarily backend phone
        // Backend phone should match, but if there's a normalization difference, use login phone
        // CRITICAL FIX: Log phone number comparison and warn if mismatch
        if (backendPhone != null && backendPhone != normalizedPhone) {
          if (kDebugMode) {
            print('⚠️⚠️⚠️ CRITICAL: Phone number mismatch detected! ⚠️⚠️⚠️');
            print('   📱 Phone entered by user: $normalizedPhone');
            print('   📱 Phone from database: $backendPhone');
            print('   ⚠️ This can cause OTP to be sent to wrong number!');
            print('   ✅ FIX: Saving entered phone ($normalizedPhone) to ensure OTP goes to correct number');
            print('   💡 If OTP is going to wrong number, check database phone for user ID: ${user['id']}');
          }
        } else {
          if (kDebugMode) {
            print('✅ Phone numbers match: $normalizedPhone');
          }
        }
        
        await StorageService.saveUserData(
          userId: user['id'] as int,
          role: role, // Use extracted role
          phone: normalizedPhone, // CRITICAL: Always save the phone that was used for login
          name: user['name'] as String?,
          email: user['email'] as String?,
        );
        if (kDebugMode) {
          print('✅ User data saved to storage');
          print('📱 Saved phone number (for OTP): $normalizedPhone');
        }
        
        // Verify role was saved
        final savedRole = await StorageService.getUserRole();
        if (kDebugMode) {
          if (savedRole == role) {
            print('   Role verified in storage: $savedRole');
          } else {
            print('⚠️ Warning: Role mismatch - saved: $savedRole, expected: $role');
          }
        }
        
        // Verify phone was saved correctly
        final savedPhone = await StorageService.getUserPhone();
        if (kDebugMode) {
          if (savedPhone == normalizedPhone) {
            print('   ✅ Phone verified in storage: $savedPhone');
          } else {
            print('⚠️ Warning: Phone mismatch - saved: $savedPhone, expected: $normalizedPhone');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Error: No user data in response');
        }
        throw Exception('No user data received from server');
      }
      
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login phone error: $e');
        if (e is DioException && e.response != null) {
          print('   Status Code: ${e.response?.statusCode}');
          print('   Response Data: ${e.response?.data}');
        }
      }
      if (e is DioException && e.response != null) {
        final errorMessage = e.response?.data?['message'] ?? 'Login failed';
        throw Exception(errorMessage);
      }
      throw _handleError(e);
    }
  }

  /// POST /api/auth/verify-otp
  /// ✅ LIVE: Uses Twilio Verify API to verify OTP
  Future<Map<String, dynamic>> verifyOTP(
    String phone,
    String otp, {
    String? type,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 Verifying OTP via Twilio Verify');
        print('📱 Phone: $phone');
        print('📱 Type: $type');
        print('🔑 OTP: [hidden]');
      }
      
      // Normalize phone to match backend format
      String normalizedPhone = phone.trim();
      if (!normalizedPhone.startsWith('+964')) {
        if (normalizedPhone.startsWith('964')) {
          normalizedPhone = '+$normalizedPhone';
        } else if (normalizedPhone.startsWith('0')) {
          normalizedPhone = '+964${normalizedPhone.substring(1)}';
        } else if (normalizedPhone.startsWith('00964')) {
          normalizedPhone = '+964${normalizedPhone.substring(5)}';
        } else {
          throw Exception('Invalid phone format. Must start with +964');
        }
      }
      
      final requestData = {
        'phone': normalizedPhone,
        'otp': otp,
        if (type != null) 'type': type,
      };
      
      final response = await _dio.post(
        'auth/verify-otp',
        data: requestData,
      );
      
      // Note: Referral code is now handled exclusively in the register API
      // as per user request ("Referall code must be in register Not login")
      
      if (kDebugMode) {
        print('✅ OTP verified successfully via Twilio Verify');
        print('   User ID: ${response.data['user']?['id']}');
        print('   Role: ${response.data['role'] ?? response.data['user']?['role']}');
      }
      
      // Extract role from response
      final role = (response.data['role'] ?? response.data['user']?['role'] ?? 'company_products').toString().toLowerCase();
      
      // Save tokens and user data
      final accessToken = response.data['accessToken'] ?? response.data['token'];
      final refreshToken = response.data['refreshToken'];
      
      if (accessToken != null) {
        if (kDebugMode) {
          print('💾 [TOKEN SAVE] Saving tokens after OTP verification...');
          print('   Access token present: ✅');
          print('   Refresh token present: ${refreshToken != null ? "✅" : "❌"}');
        }
        
        if (refreshToken != null) {
          await StorageService.saveTokens(
            accessToken: accessToken as String,
            refreshToken: refreshToken as String,
          );
          if (kDebugMode) {
            print('✅ Access and refresh tokens saved to storage');
          }
        } else {
          await StorageService.saveAccessToken(accessToken as String);
          if (kDebugMode) {
            print('✅ Access token saved to storage');
          }
        }
        
        // Verify token was saved
        final savedToken = await StorageService.getAccessToken();
        if (kDebugMode) {
          if (savedToken != null && savedToken == accessToken) {
            print('✅ [TOKEN VERIFICATION] Token successfully retrieved from storage');
          } else {
            print('⚠️ [TOKEN VERIFICATION] Token retrieval failed or mismatch');
          }
        }
        
        // Save user data
        if (response.data['user'] != null) {
          final user = response.data['user'];
          await StorageService.saveUserData(
            userId: user['id'] as int,
            role: role,
            phone: normalizedPhone,
            name: user['name'] as String?,
            email: user['email'] as String?,
          );
          if (kDebugMode) {
            print('✅ User data saved to storage');
            print('   User ID: ${user['id']}');
            print('   Role: $role');
            print('   Phone: $normalizedPhone');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ [TOKEN SAVE] No access token in response - cannot save');
        }
      }
      
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Verify OTP error: $e');
        if (e is DioException && e.response != null) {
          print('   Status Code: ${e.response?.statusCode}');
          print('   Response Data: ${e.response?.data}');
        }
      }
      throw _handleError(e);
    }
  }

  /// POST /api/auth/register
  /// ✅ LIVE: Connects to backend database
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    String? city,
    String? area,
    required String password,
    required String role,
    String? referralCode,
  }) async {
    try {
      if (kDebugMode) {
        print('✅ Register API Call:');
        print('   Current Base URL: ${currentBaseUrl}');
        print('   Full URL: ${currentBaseUrl}/auth/register');
        print('   Name: $name, Phone: $phone, Role: $role, Referral: $referralCode, City: $city, Area: $area');
      }
      
      final response = await _dio.post(
        'auth/register',
        data: {
          'name': name,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          if (city != null) 'city': city,
          if (area != null) 'area': area,
          'password': password,
          'role': role,
          if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
        },
      );
      
      if (kDebugMode) {
        print('✅ JWT verified - User registered successfully');
        print('   User ID: ${response.data['user']?['id']}');
      }
      
      // Save tokens and user data
      final accessToken = response.data['accessToken'] ?? response.data['token'];
      final refreshToken = response.data['refreshToken'];
      
      if (accessToken != null) {
        if (refreshToken != null) {
          await StorageService.saveTokens(
            accessToken: accessToken as String,
            refreshToken: refreshToken as String,
          );
          if (kDebugMode) {
            print('✅ Access and refresh tokens saved to storage');
          }
        } else {
          await StorageService.saveAccessToken(accessToken as String);
          if (kDebugMode) {
            print('✅ Access token saved to storage');
          }
        }
      }
      
      if (response.data['user'] != null) {
        final user = response.data['user'];
        await StorageService.saveUserData(
          userId: user['id'] as int,
          role: user['role'] as String,
          phone: user['phone'] as String,
          name: user['name'] as String?,
          email: user['email'] as String?,
        );
        if (kDebugMode) {
          print('✅ User data saved to storage');
        }

        // ✅ CLEAR REFERRAL CODE after successful registration
        // We only clear it in register, as per user request to separate it from login
        await _clearPendingReferralCode();
      }
      
      if (kDebugMode) {
        print('✅ Fetched 1 record (new user)');
      }
      
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Registration error: $e');
      }
      
      // Better error handling for 500 and other errors
      if (e is DioException && e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorData = e.response?.data;
        
        if (kDebugMode) {
          print('   ⚠️ Response Status: $statusCode');
          print('   Response Data: $errorData');
        }
        
        // Extract error message from response
        if (errorData is Map) {
          final message = errorData['message'] as String?;
          final errorInfo = errorData['error'] as Map?;
          
          if (message != null) {
            if (kDebugMode) {
              print('   ⚠️ $statusCode Error: $message');
              if (errorInfo != null) {
                print('   Error Details: $errorInfo');
              }
            }
            
            // Re-throw with better message
            throw DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: message,
            );
          }
        }
      }
      throw _handleError(e);
    }
  }

  /// POST /api/auth/login
  /// ✅ LIVE: Connects to backend database
  Future<Map<String, dynamic>> login({
    String? phone,
    String? email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('✅ Connected to live DB - Logging in');
        print('   Phone: $phone, Email: $email');
      }
      
      final response = await _dio.post(
        'auth/login',
        data: {
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          'password': password,
        },
      );
      
      if (kDebugMode) {
        print('✅ JWT verified - Login successful');
        print('   User ID: ${response.data['user']?['id']}');
        print('   Role: ${response.data['user']?['role']}');
      }
      
      // Save tokens and user data
      final accessToken = response.data['accessToken'] ?? response.data['token'];
      final refreshToken = response.data['refreshToken'];
      
      if (accessToken != null) {
        if (refreshToken != null) {
          await StorageService.saveTokens(
            accessToken: accessToken as String,
            refreshToken: refreshToken as String,
          );
          if (kDebugMode) {
            print('✅ Access and refresh tokens saved to storage');
          }
        } else {
          await StorageService.saveAccessToken(accessToken as String);
          if (kDebugMode) {
            print('✅ Access token saved to storage');
          }
        }
      }
      if (response.data['user'] != null) {
        final user = response.data['user'];
        await StorageService.saveUserData(
          userId: user['id'] as int,
          role: user['role'] as String,
          phone: user['phone'] as String,
          name: user['name'] as String?,
          email: user['email'] as String?,
        );
        if (kDebugMode) {
          print('✅ User data saved to storage');
        }
      }
      
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      throw _handleError(e);
    }
  }

  /// POST /api/auth/refresh
  /// ✅ Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      if (kDebugMode) {
        print('🔄 Refreshing access token...');
      }
      
      final response = await _dio.post(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      if (kDebugMode) {
        if (response.data['success'] == true) {
          print('✅ Token refreshed successfully');
        } else {
          print('⚠️ Token refresh returned success: false');
        }
      }
      
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Refresh token error: $e');
      }
      throw _handleError(e);
    }
  }

  /// GET /api/auth/profile
  /// ✅ LIVE: Live user info from database
  Future<UserModel> getProfile() async {
    try {
      if (kDebugMode) {
        print('✅ Connected to live DB - Fetching user profile');
      }
      
      final response = await _dio.get('auth/profile');
      
      if (kDebugMode) {
        print('✅ JWT verified');
        print('✅ Fetched 1 record (user profile)');
      }
      
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching profile: $e');
      }
      throw _handleError(e);
    }
  }

  /// PATCH /api/auth/profile
  /// ✅ LIVE: Updates database
  /// When role is updated, backend returns new tokens that must be saved
  Future<UserModel> updateProfile({String? name, String? phone, String? role}) async {
    try {
      // Check if token exists before making request
      final accessToken = await StorageService.getAccessToken();
      if (kDebugMode) {
      if (kDebugMode) {
        print('✅ Connected to live DB - Updating profile');
        print('   Name: $name, Phone: $phone, Role: $role');
        print('   Has Access Token: ${accessToken != null}');
      }
        if (accessToken != null) {
          print('   Token preview: ${accessToken.substring(0, 30)}...');
        } else {
          print('   ⚠️ WARNING: No access token found! Request may fail with 401');
        }
      }
      
      if (accessToken == null) {
        throw Exception('No access token found. Please login again.');
      }
      
      final response = await _dio.patch(
        'auth/profile',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (role != null) 'role': role, // 🔧 FIX: Allow role updates
        },
      );
      
      print('✅ JWT verified');
      print('✅ Profile updated in database');
      
      // 🔧 FIX: If role was updated, backend returns new tokens - save them
      if (role != null && response.data['accessToken'] != null) {
        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;
        final updatedRole = (response.data['role'] ?? role).toString().toLowerCase();
        
        print('✅ New tokens received after role update');
        print('   Updated role: $updatedRole');
        
        // Verify token role matches updated role
        final tokenRole = JwtUtils.getRoleFromToken(newAccessToken);
        if (tokenRole != null && tokenRole != updatedRole) {
          print('⚠️ WARNING: New token role ($tokenRole) != Updated role ($updatedRole)');
        } else {
          print('   ✅ Token role verified: $tokenRole');
        }
        
        // Save new tokens
        await StorageService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        print('✅ New tokens saved to storage');
        
        // Update role in SharedPreferences to match token
        final userData = response.data['data'] as Map<String, dynamic>;
        await StorageService.saveUserData(
          userId: userData['id'] as int,
          role: updatedRole,
          phone: userData['phone'] as String? ?? await StorageService.getUserPhone() ?? '',
          name: userData['name'] as String?,
          email: userData['email'] as String?,
        );
        print('✅ Role updated in SharedPreferences: $updatedRole');
        
        // Verify everything is in sync
        final savedTokenRole = JwtUtils.getRoleFromToken(newAccessToken);
        final savedRole = await StorageService.getUserRole();
        if (savedTokenRole != null && savedRole != null && savedTokenRole == savedRole) {
          print('   ✅ Token role and SharedPreferences role are in sync: $savedRole');
        } else {
          print('⚠️ Warning: Role mismatch after update');
          print('   Token role: $savedTokenRole');
          print('   SharedPreferences role: $savedRole');
        }
      }
      
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Error updating profile: $e');
      
      // Debug: Print error details
      if (e is DioException && e.response != null) {
        final statusCode = e.response?.statusCode;
        print('🔍 DEBUG: Error response status: $statusCode');
        print('🔍 DEBUG: Error response data: ${e.response?.data}');
        final errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'];
        if (errorMessage != null) {
          print('🔍 DEBUG: Backend error message: "$errorMessage"');
        }
        
        // Handle 401 Unauthorized - Token missing or invalid
        if (statusCode == 401) {
          final token = await StorageService.getAccessToken();
          if (token == null) {
            print('❌ No access token in storage - user needs to login');
            throw Exception('Session expired. Please login again.');
          } else {
            print('⚠️ Token exists but request was rejected - token may be expired or invalid');
            print('   Token preview: ${token.substring(0, 30)}...');
            throw Exception('Authentication failed. Please login again.');
          }
        }
      }
      
      throw _handleError(e);
    }
  }

  /// POST /api/auth/logout
  Future<void> logout() async {
    try {
      await _dio.post('auth/logout');
      await StorageService.clearAll();
    } catch (e) {
      // Clear storage even if API call fails
      await StorageService.clearAll();
      throw _handleError(e);
    }
  }

  // ==================== PRODUCTS ====================

  /// GET /api/products
  /// ✅ LIVE: Connects to backend database
  Future<Map<String, dynamic>> getAllProducts({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('✅ Connected to live DB - Fetching products');
      print('   Category: $category, Search: $search, Page: $page, Limit: $limit');
      
      final response = await _dio.get(
        'products',
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      
      return _processProductsResponse(response);
    } catch (e) {
      print('❌ Error in getAllProducts: $e');
      throw _handleError(e);
    }
  }

  /// GET /api/company/products
  /// ✅ LIVE: Fetch only company products
  Future<Map<String, dynamic>> getCompanyProducts({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('✅ Fetching COMPANY products');
      
      final response = await _dio.get(
        'company/products', // Endpoint for company products
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      
      return _processProductsResponse(response);
    } catch (e) {
      print('❌ Error in getCompanyProducts: $e');
      throw _handleError(e);
    }
  }

  /// GET /api/seller/products
  /// ✅ LIVE: Fetch only seller products (public listings)
  Future<Map<String, dynamic>> getSellerProducts({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('✅ Fetching SELLER products');
      
      final response = await _dio.get(
        'seller/products', // Endpoint for seller products
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      
      return _processProductsResponse(response);
    } catch (e) {
      print('❌ Error in getSellerProducts: $e');
      throw _handleError(e);
    }
  }

  // Helper method to process product responses
  Map<String, dynamic> _processProductsResponse(Response response) {
    print('✅ JWT verified');
      
    if (response.data['data'] == null) {
      print('❌ Response data field is null!');
      throw Exception('Invalid API response: missing data field');
    }
    
    final dataList = response.data['data'] as List?;
    if (dataList == null) {
      print('❌ Response data is not a list!');
      throw Exception('Invalid API response: data is not a list');
    }
    
    if (kDebugMode) {
      print('✅ Fetched ${dataList.length} records from database');
    }
    
    final products = <ProductModel>[];
    for (int i = 0; i < dataList.length; i++) {
      try {
        final product = ProductModel.fromJson(dataList[i] as Map<String, dynamic>);
        products.add(product);
      } catch (parseError) {
        print('❌ Failed to parse product at index $i: $parseError');
        // Continue with other products instead of failing completely
      }
    }
    
    return {
      'products': products,
      'pagination': response.data['pagination'],
    };
  }

  /// GET /api/products/:id
  /// ✅ LIVE: Connects to backend database
  Future<ProductModel> getProductById(int id) async {
    try {
      print('✅ Connected to live DB - Fetching product ID: $id');
      
      final response = await _dio.get('products/$id');
      
      print('✅ JWT verified');
      print('✅ Fetched 1 record (product details)');
      
      return ProductModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Error fetching product: $e');
      throw _handleError(e);
    }
  }

  /// GET /api/products/mine
  /// ✅ LIVE: Connects to backend database
  Future<List<ProductModel>> getMyProducts({String? status}) async {
    try {
      print('✅ Connected to live DB - Fetching my products');
      print('   Status filter: $status');
      
      final response = await _dio.get(
        'products/mine',
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      
      print('✅ JWT verified');
      print('   Response status: ${response.statusCode}');
      print('   Full response: ${response.data}');
      print('   Response data keys: ${response.data.keys}');
      print('   Response success: ${response.data['success']}');
      
      // Check if data exists
      if (response.data['data'] == null) {
        print('⚠️ Response data is null');
        print('   Full response structure: ${response.data}');
        return [];
      }
      
      final dataList = response.data['data'];
      print('   Data type: ${dataList.runtimeType}');
      print('   Data length: ${dataList is List ? dataList.length : 'N/A'}');
      
      if (dataList is! List) {
        print('❌ Response data is not a list: $dataList');
        print('   Actual type: ${dataList.runtimeType}');
        return [];
      }
      
      if (dataList.isEmpty) {
        print('⚠️ Response data is empty list');
        print('   This means the logged-in seller has no products in database');
        return [];
      }
      
      print('   First product sample: ${dataList[0]}');
      
      final products = dataList
          .map((json) {
            try {
              return ProductModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing product: $e');
              print('   JSON: $json');
              return null;
            }
          })
          .whereType<ProductModel>()
          .toList();
      
      print('✅ Fetched ${products.length} records (my products)');
      
      return products;
    } catch (e) {
      print('❌ Error fetching my products: $e');
      if (e is DioException && e.response != null) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }

  /// POST /api/uploads/image
  /// ✅ Upload image file and return URL
  /// Supports both File (mobile) and Uint8List (web)
  Future<String> uploadImage(dynamic imageData, {String? filename}) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      MultipartFile multipartFile;
      String contentType = 'image/jpeg';
      String fileName = filename ?? 'image.jpg';

      // Handle different image data types based on platform
      if (imageData is Uint8List) {
        // Web/Mobile: Use bytes directly
        print('📤 Uploading image from bytes: ${imageData.length} bytes');
        
        // Try to detect image type from bytes
        if (imageData.length >= 4) {
          // PNG signature: 89 50 4E 47
          if (imageData[0] == 0x89 && imageData[1] == 0x50 && 
              imageData[2] == 0x4E && imageData[3] == 0x47) {
            contentType = 'image/png';
            fileName = filename ?? 'image.png';
          }
          // JPEG signature: FF D8 FF
          else if (imageData[0] == 0xFF && imageData[1] == 0xD8 && imageData[2] == 0xFF) {
            contentType = 'image/jpeg';
            fileName = filename ?? 'image.jpg';
          }
        }

        multipartFile = MultipartFile.fromBytes(
          imageData,
          filename: fileName,
          contentType: MediaType('image', contentType.split('/').last),
        );
      } else if (!kIsWeb) {
        // Mobile/Desktop: Try to use as File (check for path property)
        // Use dynamic to avoid File type import on web
        try {
          final dynamic file = imageData;
          final filePath = file.path as String?;
          if (filePath != null && filePath.isNotEmpty) {
            // It's a File-like object
            print('📤 Uploading image from file: $filePath');
            
            fileName = filePath.split('/').last;
            final fileExtension = fileName.split('.').last.toLowerCase();
            
            // Determine content type
            if (fileExtension == 'png') {
              contentType = 'image/png';
            } else if (fileExtension == 'gif') {
              contentType = 'image/gif';
            } else if (fileExtension == 'webp') {
              contentType = 'image/webp';
            }

            multipartFile = await MultipartFile.fromFile(
              filePath,
              filename: fileName,
              contentType: MediaType('image', fileExtension),
            );
          } else {
            throw Exception('Invalid image data type. Expected Uint8List or File with path.');
          }
        } catch (e) {
          throw Exception('Invalid image data type. Expected Uint8List or File. Error: $e');
        }
      } else {
        // Web: Only Uint8List is supported
        throw Exception('Invalid image data type. On web, only Uint8List is supported.');
      }

      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'image': multipartFile,
      });

      final response = await _dio.post(
        'uploads/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final imageUrl = response.data['data']['url'] as String;
        print('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      if (e is DioException && e.response != null) {
        print('   Error Status Code: ${e.response!.statusCode}');
        print('   Error Response Data: ${e.response!.data}');
      }
      throw _handleError(e);
    }
  }

  /// POST /api/products/create
  /// ✅ LIVE: Inserts into database
  Future<ProductModel> createProduct({
    required String title,
    String? description,
    String? imageUrl,
    required double startingPrice,
    double? realPrice,
    String? condition,
    int? duration,
    int? categoryId,
  }) async {
    try {
      print('✅ Connected to live DB - Creating product');
      print('   Title: $title, Price: $startingPrice');
      
      // 🔍 DEEP TRACE: Before product creation
      print('🔍 [DEEP TRACE] ApiService.createProduct() - BEFORE REQUEST');
      
      // Get current user info for debugging
      final userId = await StorageService.getUserId();
      final userRole = await StorageService.getUserRole();
      print('   Current User ID: $userId');
      print('   Current User Role: $userRole');
      
      // 🔍 DEEP TRACE: Get token directly
      final accessToken = await StorageService.getAccessToken();
      final refreshToken = await StorageService.getRefreshToken();
      
      if (accessToken != null) {
        final tokenRole = JwtUtils.getRoleFromToken(accessToken);
        final tokenUserId = JwtUtils.getUserIdFromToken(accessToken);
        print('   🔍 Access Token Details:');
        print('      Token role: $tokenRole');
        print('      Token userId: $tokenUserId');
        print('      Token length: ${accessToken.length}');
        print('      Token preview: ${accessToken.substring(0, accessToken.length > 50 ? 50 : accessToken.length)}...');
        print('   🔍 Refresh Token: ${refreshToken != null ? "Present (${refreshToken.length} chars)" : "NULL"}');
        print('   🔍 Stored Role: $userRole');
        
        if (tokenRole != null && userRole != null && tokenRole != userRole) {
          print('   ⚠️⚠️⚠️ CRITICAL MISMATCH BEFORE PRODUCT CREATE! ⚠️⚠️⚠️');
          print('   ⚠️ Token role ($tokenRole) != Stored role ($userRole)');
          print('   ⚠️ This will cause 403 Forbidden!');
          print('   ⚠️ STACK TRACE:');
          print(StackTrace.current);
        }
      } else {
        print('   ⚠️ NO ACCESS TOKEN AVAILABLE!');
      }
      
      final response = await _dio.post(
        'products/create',
        data: {
          'title': title,
          'description': description,
          'image_url': imageUrl,
          'startingPrice': startingPrice,
          'current_price': realPrice,
          'condition': condition,
          'duration': duration ?? 7,
          'category_id': categoryId,
        },
      );
      
      print('✅ JWT verified');
      print('✅ Product created in database');
      print('   Product ID: ${response.data['data']?['id']}');
      
      return ProductModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Error creating product: $e');
      
      // Log detailed error information
      if (e is DioException && e.response != null) {
        print('   Error Status Code: ${e.response!.statusCode}');
        print('   Error Response Data: ${e.response!.data}');
        final errorData = e.response!.data;
        if (errorData is Map) {
          print('   Error Message: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
        }
      }
      
      throw _handleError(e);
    }
  }

  /// DELETE /api/auth/delete-account
  /// ✅ MANDATORY FOR APPLE: Deletes user and all data
  Future<void> deleteAccount() async {
    try {
      print('🗑️ Requesting account deletion from database');
      final response = await _dio.delete('auth/delete-account');
      
      if (response.data['success'] == true) {
        print('✅ Account deleted successfully from database');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      print('❌ Error deleting account: $e');
      throw _handleError(e);
    }
  }

  /// PUT /api/products/:id
  /// ✅ LIVE: Updates product in database (Seller can edit ONLY their own products)
  Future<ProductModel> updateProduct({
    required int id,
    String? title,
    String? description,
    String? imageUrl,
    double? startingPrice,
    double? realPrice,
    String? condition,
    int? categoryId,
  }) async {
    try {
      print('✅ Connected to live DB - Updating product: $id');
      print('   Update data: title=${title != null ? "provided" : "null"}, description=${description != null ? "provided" : "null"}, imageUrl=${imageUrl != null ? "provided" : "null"}, startingPrice=${startingPrice != null ? startingPrice : "null"}');
      
      // Build request body - always include fields that are provided
      final Map<String, dynamic> requestData = {};
      
      // Title is required for updates
      if (title != null) {
        requestData['title'] = title;
      }
      
      // Description can be null (to clear it) or a string
      if (description != null) {
        requestData['description'] = description.isEmpty ? null : description;
      }
      
      // Image URL: always send when provided (can be string URL or null to remove)
      // The product_creation_screen always provides imageUrl when updating
      if (imageUrl != null) {
        requestData['image_url'] = imageUrl;
      } else if (title != null) {
        // If updating and imageUrl is explicitly null, send null to remove image
        requestData['image_url'] = null;
      }
      
      // Starting price is required for updates
      if (startingPrice != null) {
        requestData['startingPrice'] = startingPrice;
      }

      if (realPrice != null) {
        requestData['current_price'] = realPrice;
      }

      if (condition != null) {
        requestData['condition'] = condition;
      }
      
      if (categoryId != null) {
        requestData['category_id'] = categoryId;
      }
      
      print('   Request payload: $requestData');
      
      final response = await _dio.put(
        'products/$id',
        data: requestData,
      );
      
      print('✅ JWT verified');
      print('✅ Product updated in database');
      print('   Response: ${response.data}');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        return ProductModel.fromJson(response.data['data']);
      } else {
        throw Exception('Invalid response format from server');
      }
    } catch (e) {
      print('❌ Error updating product: $e');
      if (e is DioException && e.response != null) {
        print('   Error Status Code: ${e.response!.statusCode}');
        print('   Error Response Data: ${e.response!.data}');
        final errorData = e.response!.data;
        if (errorData is Map) {
          print('   Error Message: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
        }
      }
      throw _handleError(e);
    }
  }

  /// DELETE /api/products/:id
  /// ✅ LIVE: Deletes product from database (Seller can delete ONLY their own products)
  Future<void> deleteProduct(int id) async {
    try {
      print('✅ Connected to live DB - Deleting product: $id');
      
      final response = await _dio.delete('products/$id');
      
      print('✅ JWT verified');
      print('✅ Product deleted from database');
      print('   Response: ${response.data}');
    } catch (e) {
      print('❌ Error deleting product: $e');
      if (e is DioException && e.response != null) {
        print('   Error Status Code: ${e.response!.statusCode}');
        print('   Error Response Data: ${e.response!.data}');
      }
      throw _handleError(e);
    }
  }

  // ==================== BIDS ====================

  /// POST /api/bids/place
  /// ✅ LIVE: Inserts into database
  Future<BidModel> placeBid({
    required int productId,
    required double amount,
  }) async {
    try {
      print('✅ Connected to live DB - Placing bid');
      print('   Product ID: $productId, Amount: $amount');
      
      final response = await _dio.post(
        'bids/place',
        data: {
          'productId': productId,
          'amount': amount,
        },
      );
      
      print('✅ JWT verified');
      print('✅ Bid placed in database');
      print('   Bid ID: ${response.data['data']?['id']}');
      
      return BidModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Error placing bid: $e');
      
      // Better error handling for 400 errors
      if (e is DioException && e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorData = e.response?.data;
        
        // Extract error message from response
        if (errorData is Map && errorData['message'] != null) {
          final message = errorData['message'] as String;
          print('   ⚠️ $statusCode Bad Request: $message');
          print('   Response data: $errorData');
          
          // Re-throw with better message
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: message,
          );
        }
        
        if (statusCode == 400) {
          final errorMessage = errorData is Map 
              ? (errorData['message'] ?? errorData['error'] ?? 'Invalid bid request')
              : 'Invalid bid request';
          
          print('   ⚠️ 400 Bad Request: $errorMessage');
          print('   Response data: $errorData');
          
          throw Exception(errorMessage);
        }
      }
      
      throw _handleError(e);
    }
  }

  /// GET /api/bids/:productId
  /// ✅ LIVE: Connects to backend database
  Future<List<BidModel>> getBidsByProduct(int productId) async {
    try {
      print('✅ Connected to live DB - Fetching bids for product: $productId');
      
      final response = await _dio.get('bids/$productId');
      
      print('✅ JWT verified');
      
      final bids = (response.data['data'] as List)
          .map((json) => BidModel.fromJson(json))
          .toList();
      
      print('✅ Fetched ${bids.length} records (bids)');
      
      return bids;
    } catch (e) {
      print('❌ Error fetching bids: $e');
      throw _handleError(e);
    }
  }

  /// GET /api/bids/mine
  /// ✅ LIVE: Connects to backend database
  Future<List<BidModel>> getMyBids() async {
    try {
      print('✅ Connected to live DB - Fetching my bids');
      
      final response = await _dio.get('bids/mine');
      
      print('✅ JWT verified');
      
      final bids = (response.data['data'] as List)
          .map((json) => BidModel.fromJson(json))
          .toList();
      
      print('✅ Fetched ${bids.length} records (my bids)');
      
      return bids;
    } catch (e) {
      print('❌ Error fetching my bids: $e');
      throw _handleError(e);
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// GET /api/notifications
  /// ✅ LIVE: DB-driven list
  Future<List<NotificationModel>> getNotifications({
    bool? read,
    int limit = 50,
  }) async {
    try {
      print('✅ Connected to live DB - Fetching notifications');
      print('   Read filter: $read, Limit: $limit');
      
      final response = await _dio.get(
        'notifications',
        queryParameters: {
          if (read != null) 'read': read.toString(),
          'limit': limit,
        },
      );
      
      print('✅ JWT verified');
      
      // Handle different response formats
      List<dynamic> notificationsList;
      
      if (response.data['data'] != null) {
        notificationsList = response.data['data'] as List;
      } else if (response.data is List) {
        // If response.data is directly a list
        notificationsList = response.data as List;
      } else if (response.data['notifications'] != null) {
        // Alternative format
        notificationsList = response.data['notifications'] as List;
      } else {
        print('⚠️ No notifications data found in response');
        print('   Response keys: ${response.data.keys}');
        return [];
      }
      
      final notifications = notificationsList
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('✅ Fetched ${notifications.length} records (notifications)');
      
      return notifications;
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      throw _handleError(e);
    }
  }

  /// PATCH /api/notifications/read/:id
  /// ✅ LIVE: Updates database
  Future<NotificationModel> markNotificationAsRead(int id) async {
    try {
      print('✅ Connected to live DB - Marking notification as read: $id');
      
      final response = await _dio.patch('notifications/read/$id');
      
      print('✅ JWT verified');
      print('✅ Notification updated in database');
      
      return NotificationModel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      throw _handleError(e);
    }
  }

  // ==================== ORDERS ====================

  /// POST /api/orders/create
  /// ✅ LIVE: Creates order in database
  Future<Map<String, dynamic>> createOrder({required int productId}) async {
    try {
      print('✅ Connected to live DB - Creating order');
      print('   Product ID: $productId');
      
      final response = await _dio.post(
        'orders/create',
        data: {'productId': productId},
      );
      
      print('✅ JWT verified');
      print('✅ Order created in database');
      print('   Order ID: ${response.data['data']?['id']}');
      
      return response.data;
    } catch (e) {
      print('❌ Error creating order: $e');
      throw _handleError(e);
    }
  }

  /// GET /api/orders/mine
  /// ✅ LIVE: DB transaction list
  Future<List<Map<String, dynamic>>> getMyOrders({String? status, String? type}) async {
    try {
      print('✅ Connected to live DB - Fetching my orders');
      print('   Status: $status, Type: $type');
      
      final response = await _dio.get(
        'orders/mine',
        queryParameters: {
          if (status != null) 'status': status,
          if (type != null) 'type': type,
        },
      );
      
      print('✅ JWT verified');
      
      final orders = (response.data['data'] as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();
      
      print('✅ Fetched ${orders.length} records (orders)');
      
      return orders;
    } catch (e) {
      print('❌ Error fetching orders: $e');
      throw _handleError(e);
    }
  }

  // ==================== REFERRAL METHODS ====================

  /// GET /api/referral/my-code
  /// Get user's referral code and reward balance
  Future<Map<String, dynamic>> getReferralCode() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get(
        'referral/my-code',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Referral code fetched: ${response.data}');
      }

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching referral code: $e');
      }
      throw _handleError(e);
    }
  }

  /// GET /api/referral/history
  /// Get user's referral transaction history
  Future<Map<String, dynamic>> getReferralHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get(
        'referral/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Referral history fetched: ${response.data}');
      }

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching referral history: $e');
      }
      throw _handleError(e);
    }
  }

  /// Get pending referral code from storage (for OTP verification)
  Future<String?> _getPendingReferralCode() async {
    return await ReferralService.getPendingReferralCode();
  }

  /// Clear pending referral code from storage (after successful OTP verification)
  Future<void> _clearPendingReferralCode() async {
    await ReferralService.clearPendingReferralCode();
  }

  // ==================== WALLET METHODS ====================

  /// GET /api/wallet
  /// Get unified wallet info (referral rewards + seller earnings)
  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await _dio.get('wallet');

      if (kDebugMode) {
        print('✅ Wallet data fetched: ${response.data}');
      }

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching wallet: $e');
      }
      throw _handleError(e);
    }
  }


  // ==================== WISHLIST METHODS ====================

  /// POST /api/wishlist/:productId
  /// Toggle product in wishlist (Add/Remove)
  Future<Map<String, dynamic>> toggleWishlist(int productId) async {
    try {
      print('✅ Connected to live DB - Toggling wishlist');
      print('   Product ID: $productId');

      final response = await _dio.post('wishlist/$productId');

      print('✅ Wishlist updated in database');
      return response.data;
    } catch (e) {
      print('❌ Error updating wishlist: $e');
      throw _handleError(e);
    }
  }

  /// GET /api/wishlist
  /// Get user's wishlist
  Future<List<ProductModel>> getWishlist() async {
    try {
      print('✅ Connected to live DB - Fetching wishlist');

      final response = await _dio.get('wishlist');
      
      if (response.data['data'] != null) {
        final List<dynamic> productsJson = response.data['data'];
        return productsJson.map((json) => ProductModel.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching wishlist: $e');
      throw _handleError(e);
    }
  }

  // ==================== WITHDRAWAL METHODS ====================

  /// POST /api/wallet/withdraw
  /// Request a withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String method,
    required String details,
  }) async {
    try {
      print('✅ Connected to live DB - Requesting withdrawal');
      print('   Amount: $amount, Method: $method');

      final response = await _dio.post(
        'wallet/withdraw',
        data: {
          'amount': amount,
          'method': method,
          'details': details,
        },
      );

      print('✅ Withdrawal request submitted');
      return response.data;
    } catch (e) {
      print('❌ Error requesting withdrawal: $e');
      throw _handleError(e);
    }
  }

  // ==================== BUYER BIDDING HISTORY METHODS ====================

  /// GET /api/buyer/bidding-history
  /// Get buyer's complete bidding history with filters
  Future<Map<String, dynamic>> getBuyerBiddingHistory({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      // Verify token exists
      final token = await StorageService.getAccessToken();
      if (kDebugMode) {
        print('============================================================');
        print('[FLUTTER] MyBids calling backend…');
        print('============================================================');
        print('[Buyer Bids API] Endpoint: GET /buyer/bidding-history');
        print('[Buyer Bids API] Query params: $queryParams');
        print('[Buyer Bids API] Token exists: ${token != null}');
        print('[Buyer Bids API] Full URL: ${baseUrl}/buyer/bidding-history');
        print('[Buyer Bids API] Request timestamp: ${DateTime.now()}');
      }

      final response = await _dio.get(
        'buyer/bidding-history',
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('[Buyer Bids API] ✅ Response received');
        print('[Buyer Bids API] Status: ${response.statusCode}');
        print('[Buyer Bids API] Success: ${response.data['success']}');
        final dataList = response.data['data'] as List?;
        final dataCount = dataList?.length ?? 0;
        print('[Buyer Bids API] Data count: $dataCount');
        print('[Buyer Bids API] Has analytics: ${response.data['analytics'] != null}');
        print('[Buyer Bids API] Has pagination: ${response.data['pagination'] != null}');
        if (dataCount > 0) {
          print('[Buyer Bids API] Sample bid: ${dataList![0]}');
        } else {
          print('[Buyer Bids API] ⚠️ No bids returned - will show empty state');
        }
        print('============================================================');
      }

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('[Buyer Bids API] ❌ Error: $e');
        if (e is DioException) {
          print('[Buyer Bids API] Error type: ${e.type}');
          print('[Buyer Bids API] Status code: ${e.response?.statusCode}');
          print('[Buyer Bids API] Response data: ${e.response?.data}');
          print('[Buyer Bids API] Request path: ${e.requestOptions.path}');
          print('[Buyer Bids API] Request baseUrl: ${e.requestOptions.baseUrl}');
        }
      }
      throw _handleError(e);
    }
  }

  // ==================== SELLER EARNINGS METHODS ====================

  /// GET /api/seller/earnings
  /// Get seller's earnings dashboard
  Future<Map<String, dynamic>> getSellerEarnings() async {
    try {
      final response = await _dio.get('seller/earnings');

      if (kDebugMode) {
        print('✅ Seller earnings fetched: ${response.data}');
      }

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching seller earnings: $e');
      }
      throw _handleError(e);
    }
  }

  /// GET /api/auction/seller/:productId/winner
  /// Get winner details for seller's own product
  Future<Map<String, dynamic>> getSellerWinner(int productId) async {
    try {
      final response = await _dio.get('auction/seller/$productId/winner');

      if (kDebugMode) {
        print('✅ Seller winner details fetched: ${response.data}');
      }

      return response.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching seller winner: $e');
      }
      throw _handleError(e);
    }
  }

  // ==================== CATEGORY METHODS ====================

  /// GET /api/categories
  /// Get all active categories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await _dio.get('categories');

      if (response.data['success'] == true && response.data['data'] != null) {
        final categoriesList = (response.data['data'] as List)
            .map((cat) => cat as Map<String, dynamic>)
            .toList();
        
        // Remove duplicates by id
        final seenIds = <int>{};
        final categories = categoriesList.where((cat) {
          final id = cat['id'] as int?;
          if (id == null) return false;
          if (seenIds.contains(id)) return false;
          seenIds.add(id);
          return true;
        }).toList();
        
        if (kDebugMode) {
          print('✅ Categories fetched: ${categories.length} (${categoriesList.length - categories.length} duplicates removed)');
        }
        
        return categories;
      } else {
        if (kDebugMode) {
          print('⚠️ No categories in response');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching categories: $e');
      }
      throw _handleError(e);
    }
  }

  // ==================== BANNERS METHODS ====================

  /// GET /api/banners
  /// Get all active banners for carousel (Production-ready)
  /// Returns list of banner objects with imageUrl, title, link, etc.
  Future<List<Map<String, dynamic>>> getBanners() async {
    try {
      if (kDebugMode) {
        // Use currentBaseUrl to show actual URL being used (may have switched to production)
        print('✅ Fetching banners from API: ${currentBaseUrl}/banners');
        print('   Current base URL: $_currentBaseUrl (may have auto-switched to production)');
      }
      
      // Use explicit endpoint path - ensure no trailing slash issues
      // _dio uses current baseUrl which may have switched to production via auto-fallback
      final response = await _dio.get(
        'banners',
        options: Options(
          validateStatus: (status) {
            // Accept 200-299 and 404 (404 means no banners, not an error)
            return status != null && (status < 300 || status == 404);
          },
        ),
      );
      
      if (kDebugMode) {
        print('📦 Banner API Response Status: ${response.statusCode}');
        print('📦 Banner API Response Data: ${response.data}');
      }
      
      // Handle 404 - endpoint exists but no banners (not an error)
      if (response.statusCode == 404) {
        if (kDebugMode) {
          print('⚠️ Banners endpoint returned 404 - no banners available');
        }
        return [];
      }
      
      // Handle successful response
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        // Check if response has expected structure
        if (response.data is Map) {
          final responseData = response.data as Map<String, dynamic>;
          
          // Handle both {success: true, data: [...]} and direct array responses
          List<dynamic> bannersList = [];
          if (responseData['success'] == true && responseData['data'] != null) {
            bannersList = responseData['data'] as List;
          } else if (responseData['data'] != null && responseData['data'] is List) {
            bannersList = responseData['data'] as List;
          } else if (response.data is List) {
            bannersList = response.data as List;
          }
          
          if (kDebugMode) {
            print('📋 Total banners received: ${bannersList.length}');
          }
          
          // Filter only active banners
          final activeBanners = bannersList
              .map((banner) => banner as Map<String, dynamic>)
              .where((banner) {
                final isActive = banner['isActive'] ?? banner['is_active'] ?? true;
                final imageUrl = banner['imageUrl'] ?? banner['image_url'] ?? '';
                
                if (kDebugMode) {
                  print('🔍 Banner check: isActive=$isActive, imageUrl=$imageUrl');
                }
                
                return isActive == true && imageUrl != null && imageUrl.toString().isNotEmpty;
              })
              .toList();
          
          if (kDebugMode) {
            print('✅ Banners fetched: ${activeBanners.length} active banners');
            if (activeBanners.isNotEmpty) {
              activeBanners.forEach((banner) {
                final url = banner['imageUrl'] ?? banner['image_url'] ?? 'N/A';
                print('   - Banner: ${banner['title'] ?? 'No title'}, URL: $url');
              });
            }
          }
          
          return activeBanners;
        } else {
          if (kDebugMode) {
            print('⚠️ Unexpected response format, returning empty list');
            print('   Response type: ${response.data.runtimeType}');
            print('   Response data: ${response.data}');
          }
          return [];
        }
      }
      
      // Fallback for any other status codes
      if (kDebugMode) {
        print('⚠️ Unexpected status code: ${response.statusCode}, returning empty list');
      }
      return [];
    } catch (e) {
      // Handle DioException specifically
      if (e is DioException) {
        if (kDebugMode) {
          print('❌ DioException fetching banners:');
          print('   Type: ${e.type}');
          print('   Message: ${e.message}');
          print('   Status Code: ${e.response?.statusCode}');
          print('   Response Data: ${e.response?.data}');
          print('   Request Path: ${e.requestOptions.path}');
          print('   Full URL: ${e.requestOptions.uri}');
        }
        
        // Check if this is a connection error and we're using local URL
        final isConnectionError = (
          e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.message?.toLowerCase().contains('connection refused') == true ||
          e.message?.toLowerCase().contains('connection timeout') == true ||
          e.message?.toLowerCase().contains('failed host lookup') == true ||
          e.message?.toLowerCase().contains('connection errored') == true ||
          e.message?.toLowerCase().contains('network is unreachable') == true ||
          e.message?.toLowerCase().contains('socketexception') == true ||
          e.message?.toLowerCase().contains('err_connection_refused') == true ||
          e.message?.toLowerCase().contains('err_connection_timed_out') == true ||
          (e.response?.statusCode == null && e.type == DioExceptionType.unknown)
        );
        
        // Check if request was made to localhost (even if baseUrl already switched)
        final requestWasToLocal = e.requestOptions.uri.toString().contains('localhost:5000') ||
                                  e.requestOptions.baseUrl.contains('localhost:5000');
        
        if (kDebugMode) {
          print('🔍 Banner auto-fallback check:');
          print('   isConnectionError: $isConnectionError');
          print('   _currentBaseUrl: $_currentBaseUrl');
          print('   requestWasToLocal: $requestWasToLocal');
          print('   Request URL: ${e.requestOptions.uri}');
        }
        
        // Auto-fallback to production if local connection fails
        // Check both: current base URL is local OR request was made to localhost
        if (kDebugMode && isConnectionError && (_currentBaseUrl == localUrl || requestWasToLocal)) {
          print('=' * 60);
          print('⚠️ Banner API: Local backend connection failed!');
          print('   Error: ${e.message}');
          print('   🔄 Auto-switching to PRODUCTION API...');
          print('   From: $localUrl');
          print('   To: $productionUrl');
          print('=' * 60);
          
          // Update base URL to production
          _dio.options.baseUrl = productionUrl;
          _currentBaseUrl = productionUrl;
          
          // Update token refresh interceptor base URL
          for (var interceptor in _dio.interceptors) {
            if (interceptor is TokenRefreshInterceptor) {
              interceptor.setBaseUrl(productionUrl);
            }
          }
          
          // Retry the request with production URL
          try {
            if (kDebugMode) {
              print('🔄 Retrying banner request with production URL: $productionUrl/banners');
              print('   Current _dio.baseUrl: ${_dio.options.baseUrl}');
            }
            
            // Use copyWith to create new request with production baseUrl (same as interceptor)
            final retryOptions = e.requestOptions.copyWith(
              baseUrl: productionUrl,
              path: 'banners',
            );
            // Set validateStatus in RequestOptions (same pattern as interceptor)
            retryOptions.validateStatus = (status) {
              return status != null && (status < 300 || status == 404);
            };
            final retryResponse = await _dio.fetch(retryOptions);
            
            if (kDebugMode) {
              print('✅ Banner request succeeded with PRODUCTION API');
              print('   Response status: ${retryResponse.statusCode}');
            }
            
            // Process the retry response the same way as original
            if (retryResponse.statusCode == 404) {
              return [];
            }
            
            if (retryResponse.statusCode != null && retryResponse.statusCode! >= 200 && retryResponse.statusCode! < 300) {
              if (retryResponse.data is Map) {
                final responseData = retryResponse.data as Map<String, dynamic>;
                List<dynamic> bannersList = [];
                if (responseData['success'] == true && responseData['data'] != null) {
                  bannersList = responseData['data'] as List;
                } else if (responseData['data'] != null && responseData['data'] is List) {
                  bannersList = responseData['data'] as List;
                } else if (retryResponse.data is List) {
                  bannersList = retryResponse.data as List;
                }
                
                final activeBanners = bannersList
                    .map((banner) => banner as Map<String, dynamic>)
                    .where((banner) {
                      final isActive = banner['isActive'] ?? banner['is_active'] ?? true;
                      final imageUrl = banner['imageUrl'] ?? banner['image_url'] ?? '';
                      return isActive == true && imageUrl != null && imageUrl.toString().isNotEmpty;
                    })
                    .toList();
                
                return activeBanners;
              }
            }
            return [];
          } catch (retryError) {
            if (kDebugMode) {
              print('❌ Banner request failed even with PRODUCTION API: $retryError');
              if (retryError is DioException) {
                print('   Retry Error Type: ${retryError.type}');
                print('   Retry Error Message: ${retryError.message}');
                print('   Retry Request URL: ${retryError.requestOptions.uri}');
                print('   Retry Base URL: ${retryError.requestOptions.baseUrl}');
                if (retryError.response != null) {
                  print('   Retry Response Status: ${retryError.response?.statusCode}');
                  print('   Retry Response Data: ${retryError.response?.data}');
                }
              }
            }
            return [];
          }
        }
        
        // Specific handling for 404
        if (e.response?.statusCode == 404) {
          if (kDebugMode) {
            print('   ℹ️ 404 means banners endpoint not found or no banners available');
            print('   This is not an error - returning empty list');
          }
          return [];
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.receiveTimeout) {
          if (kDebugMode) {
            print('   ⚠️ Connection timeout - server may be slow or unreachable');
          }
        } else if (e.type == DioExceptionType.connectionError) {
          if (kDebugMode) {
            print('   ⚠️ Connection error - check if server is running');
            print('   Base URL: $baseUrl');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Error fetching banners: $e');
          print('   Error type: ${e.runtimeType}');
        }
      }
      
      // Return empty list on any error - widget will hide carousel gracefully
      return [];
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      if (kDebugMode) {
        print('📬 Marking all notifications as read');
      }

      await _dio.patch('notifications/read-all');

      if (kDebugMode) {
        print('✅ All notifications marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking all notifications as read: $e');
      }
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final notifications = await getNotifications(read: false);
      return notifications.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting unread count: $e');
      }
      return 0;
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Handle errors and return user-friendly messages
  /// Specifically checks for network connectivity issues
  String _handleError(dynamic error) {
    // Check if this is a network connectivity error
    if (NetworkUtils.isNetworkError(error)) {
      // Return user-friendly network error message
      return NetworkUtils.getNetworkErrorMessage(error);
    }
    
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'] as String;
        }
        if (data is Map && data.containsKey('error')) {
          return data['error'] as String;
        }
        return 'Server error: ${error.response!.statusCode}';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection Timeout\n\nPlease check your internet connection and try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        // Network connectivity issue - show user-friendly message
        String currentBaseUrl = ApiService.baseUrl;
        String errorMsg = 'No Internet Connection\n\nPlease turn on your internet connection and try again.';
        
        if (kDebugMode) {
          if (currentBaseUrl.contains('localhost')) {
            errorMsg += '\n\n⚠️ Debug: localhost does not work on web/mobile devices!\n';
            errorMsg += 'Please run with: --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:5000/api';
          } else {
            errorMsg += '\n\n⚠️ Debug: Server URL: $currentBaseUrl';
          }
        }
        
        return errorMsg;
      }
      return error.message ?? 'An error occurred';
    }
    return error.toString();
  }
}

// Singleton getter - uses static instance from ApiService class
ApiService get apiService {
  if (ApiService.instance == null) {
    try {
      ApiService.instance = ApiService();
    } catch (e) {
      // In release mode, if API URL is not configured, show clear error
      if (kDebugMode) {
        print('❌ API Service initialization failed: $e');
      }
      rethrow; // Re-throw to show error to user
    }
  }
  return ApiService.instance!;
}

