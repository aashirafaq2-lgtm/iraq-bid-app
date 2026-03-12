import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/app_localizations.dart';
import '../utils/network_utils.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _currentStep = 0; // 0: phone, 1: OTP
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  String _selectedCountryCode = '+964'; // Default to Iraq for backend compatibility
  bool _isLoading = false;
  bool _isPhoneValid = false;
  int _otpAttempts = 0;
  String _normalizedPhone = ''; // Store normalized phone for verification
  bool _acceptedTerms = false; // Terms and Conditions acceptance

  static const int _maxOTPAttempts = 5;

  // No hardcoded colors - using theme colors

  // Backend currently supports Iraq only - limiting to Iraq codes
  final List<CountryCode> _countryCodes = [
    CountryCode(code: '+964', country: '🇮🇶 Iraq', maxLength: 10), // +964 is already shown, user enters 10 digits
  ];

  int get _maxPhoneLength {
    return _countryCodes
        .firstWhere((c) => c.code == _selectedCountryCode)
        .maxLength;
  }

  bool get _isPhoneNumberValid {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    // User enters exactly 10 digits (since +964 is already shown)
    return phoneDigits.length == 10;
  }

  void _validatePhoneNumber() {
    final isValid = _isPhoneNumberValid;
    if (_isPhoneValid != isValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handlePhoneSubmit() async {
    // Validate Iraq (+964) restriction
    if (_selectedCountryCode != '+964') {
      _showError(
        AppLocalizations.of(context)?.invalidPhone ?? 'Invalid Phone Number',
        AppLocalizations.of(context)?.onlyIraqNumbers ?? 'Only Iraq (+964) numbers are allowed.',
      );
      return;
    }

    if (!_isPhoneValid) {
      _showError(
        AppLocalizations.of(context)?.invalidPhone ?? 'Invalid Phone Number',
        AppLocalizations.of(context)?.enterValidPhone ?? 'Please enter a valid phone number',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Normalize phone number to match backend normalizeIraqPhone() rules
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      String normalizedPhone = '';
      
      // Apply backend normalization rules
      if (phoneDigits.startsWith('0')) {
        normalizedPhone = '+964${phoneDigits.substring(1)}';
      } else if (phoneDigits.startsWith('00964')) {
        normalizedPhone = '+964${phoneDigits.substring(5)}';
      } else if (phoneDigits.startsWith('964')) {
        normalizedPhone = '+$phoneDigits';
      } else if (_selectedCountryCode == '+964') {
        normalizedPhone = '$_selectedCountryCode$phoneDigits';
      } else {
        _showError('Invalid Phone Number', 'Only Iraq (+964) numbers are allowed.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Validate phone format (must start with +964 and have exactly 10 digits after)
      if (!normalizedPhone.startsWith('+964')) {
        _showError('Invalid Phone Number', 'Only Iraq (+964) numbers are allowed.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Validate phone length (Iraq format: +964 + exactly 10 digits)
      final digitsAfterPrefix = normalizedPhone.substring(4); // Remove '+964'
      if (digitsAfterPrefix.length != 10) {
        _showError(
          AppLocalizations.of(context)?.invalidPhone ?? 'Invalid Phone Number',
          AppLocalizations.of(context)?.phoneMustBe10Digits ?? 'Phone number must be exactly 10 digits',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      _normalizedPhone = normalizedPhone;
      if (kDebugMode) {
        print('📱 Phone normalized: $_normalizedPhone');
        print('📤 Sending OTP request to backend with phone: $_normalizedPhone');
      }
      
      // Call POST /auth/send-otp via Twilio Verify
      await apiService.sendOTP(_normalizedPhone, type: 'login');
      if (kDebugMode) {
        print('✅ OTP sent successfully via Twilio Verify to: $_normalizedPhone');
      }
      
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.otpSentToPhone ?? 'OTP sent to your phone. Please check your SMS.'),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending OTP: $e');
      }
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMsg = AppLocalizations.of(context)?.failedToSendOtp ?? 'Failed to send OTP. Please try again.';
        
        // Check for network connectivity errors first
        if (NetworkUtils.isNetworkError(e)) {
          errorMsg = NetworkUtils.getNetworkErrorMessage(e);
          _showError('No Internet Connection', errorMsg);
          return;
        }
        
        // Extract error message from backend response first
        if (e is DioException && e.response != null) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData.containsKey('message')) {
            final backendMessage = responseData['message'] as String;
            // Use backend message directly if available
            errorMsg = backendMessage;
          }
        }
        
        // Handle specific error patterns
        if (e.toString().contains('404') || e.toString().contains('not registered')) {
          errorMsg = 'Phone number not registered. Please contact administrator.';
        } else if (e.toString().contains('Invalid phone number format') || e.toString().contains('Invalid phone')) {
          errorMsg = 'Invalid phone number format. Please check and try again.';
        } else if (e.toString().contains('Unable to deliver SMS') || e.toString().contains('30008')) {
          errorMsg = 'Unable to deliver SMS to this number. Please check your phone number or contact support.';
        } else if (e.toString().contains('Unable to send SMS')) {
          errorMsg = 'Unable to send SMS. Please try again later.';
        } else if (e.toString().contains('No Internet Connection') || e.toString().contains('Connection Timeout')) {
          errorMsg = e.toString();
        }
        
        _showError('OTP Error', errorMsg);
      }
    }
  }

  String get _enteredOTP {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _handleOTPVerify() async {
    final otp = _enteredOTP;
    if (otp.length != 6) {
      _showError(
        AppLocalizations.of(context)?.invalidOtp ?? 'Invalid OTP',
        AppLocalizations.of(context)?.enter6DigitOtp ?? 'Please enter the 6-digit OTP',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure we're using the entered phone, not stored phone
      if (_normalizedPhone.isEmpty) {
        // Reconstruct from controller if somehow empty
        final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
        _normalizedPhone = '$_selectedCountryCode$phoneDigits';
        if (kDebugMode) {
          print('⚠️ _normalizedPhone was empty during verify, reconstructed: $_normalizedPhone');
        }
      }
      
      if (kDebugMode) {
        print('🔐 Verifying OTP via Twilio Verify');
        print('📱 Phone: $_normalizedPhone');
        // Note: OTP is hidden in logs for security
      }
      
      // Call POST /auth/verify-otp with phone + otp
      // Backend will verify OTP via Twilio Verify API
      
      final response = await apiService.verifyOTP(
        _normalizedPhone,
        otp,
        type: 'login',
      );
      
      if (kDebugMode) {
        print('📦 Full response from verifyOTP:');
        print('   success: ${response['success']}');
        print('   token: ${response['token'] != null ? 'present' : 'missing'}');
        print('   accessToken: ${response['accessToken'] != null ? 'present' : 'missing'}');
        print('   user: ${response['user'] != null ? 'present' : 'missing'}');
        print('   role: ${response['role']}');
      }
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Check if response has success and token
        final hasSuccess = response['success'] == true;
        final hasToken = response['token'] != null || response['accessToken'] != null;
        
        if (kDebugMode) {
          print('🔍 Response validation:');
          print('   success == true: $hasSuccess');
          print('   hasToken: $hasToken');
          print('   Will proceed: ${hasSuccess && hasToken}');
        }
        
        if (hasSuccess && hasToken) {
          // ✅ CONFIRMATION: OTP VERIFIED
          if (kDebugMode) {
            print('========================================');
            print('✅ OTP VERIFICATION: SUCCESS');
            print('✅ Response Success: YES');
            print('✅ Token Present: YES');
            print('========================================');
          }
          
          final user = response['user'];
          final role = (response['role'] ?? user?['role'] ?? 'company_products').toString().toLowerCase();
          
          if (kDebugMode) {
            print('✅ OTP verified successfully - Login successful');
            print('🧠 Role detected: $role');
            print('   User ID: ${user?['id'] ?? 'N/A'}');
            print('   User Name: ${user?['name'] ?? 'N/A'}');
            print('   User Email: ${user?['email'] ?? 'N/A'}');
          }
          
          // Note: verifyOTP already saves tokens and user data in api_service.dart
          // Verify token was saved
          final savedToken = await StorageService.getToken();
          if (savedToken == null) {
            if (kDebugMode) {
              print('⚠️ Warning: Token not found in storage');
            }
            // Save token if not already saved by verifyOTP
            final accessToken = response['accessToken'] ?? response['token'];
            if (accessToken != null) {
              await StorageService.saveToken(accessToken as String);
            }
          }
          
          // 🔧 FIX: Ensure user data is saved even if verifyOTP didn't save it
          final savedUserId = await StorageService.getUserId();
          final savedPhone = await StorageService.getUserPhone();
          
          if (savedUserId == null || savedPhone == null) {
            if (kDebugMode) {
              print('⚠️ Warning: User data not found in storage after OTP verification');
              print('   Attempting to save user data from response...');
            }
            
            if (user != null && user['id'] != null) {
              // Save user data from response
              await StorageService.saveUserData(
                userId: user['id'] as int,
                role: role,
                phone: _normalizedPhone,
                name: user['name'] as String?,
                email: user['email'] as String?,
              );
              if (kDebugMode) {
                print('✅ User data saved from response');
              }
            } else {
              // If user data is missing from response, try to fetch from profile
              if (kDebugMode) {
                print('⚠️ User data missing from response, fetching from profile endpoint...');
              }
              try {
                final profile = await apiService.getProfile();
                await StorageService.saveUserData(
                  userId: profile.id,
                  role: role,
                  phone: _normalizedPhone,
                  name: profile.name,
                  email: profile.email,
                );
                if (kDebugMode) {
                  print('✅ User data fetched and saved from profile endpoint');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Failed to fetch user profile: $e');
                }
                // Still save what we have (at least phone and role)
                await StorageService.saveUserData(
                  userId: 0, // Temporary - will be updated later
                  role: role,
                  phone: _normalizedPhone,
                  name: null,
                  email: null,
                );
              }
            }
          } else {
            if (kDebugMode) {
              print('✅ User data already saved in storage');
              print('   User ID: $savedUserId');
              print('   Phone: $savedPhone');
            }
          }

          // Show success message
          if (mounted) {
            final userName = user?['name'] as String?;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login successful! Welcome ${userName ?? 'to BidMaster'}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Wait a moment for UI to update
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) {
            if (kDebugMode) {
              print('⚠️ Widget not mounted, cannot navigate');
            }
            return;
          }

          // Always show role selection screen after login
          final userName = user?['name'] as String?;
          final userEmail = user?['email'] as String?;
          
          if (kDebugMode) {
            print('🧭 Navigation check:');
            print('   userName: ${userName ?? 'null'}');
            print('   userEmail: ${userEmail ?? 'null'}');
            print('   role: $role');
          }
          
          try {
            // Determine if user is new or existing based on name
            final name = user?['name'] as String?;
            final isNewUser = name == null || name.isEmpty;
            
            if (isNewUser) {
              if (kDebugMode) {
                print('🧭 New user detected (no name) - Navigating to RoleSelection in signup mode');
              }
              if (mounted) {
                context.go('/role-selection?mode=signup');
              }
            } else {
              // ✅ FIX: Existing user - navigate directly to dashboard based on their current role
              // DO NOT go to role-selection as it triggers updateProfile API which can fail
              // and loop the user back to /auth (Apple rejection bug 2.1a)
              final existingRole = role.toLowerCase();
              if (kDebugMode) {
                print('🧭 Existing user detected - Navigating directly to dashboard');
                print('   Role: $existingRole');
              }
              if (mounted) {
                if (existingRole == 'seller_products') {
                  context.go('/seller-dashboard');
                } else {
                  // Default: company_products, superadmin allowed to pick, etc.
                  context.go('/home');
                }
              }
            }
            
            if (kDebugMode) {
              print('✅ Navigation completed');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Navigation error: $e');
            }
            // ❌ CONFIRMATION: NAVIGATION FAILED
            if (kDebugMode) {
              print('========================================');
              print('❌ NAVIGATION: FAILED');
              print('❌ Error: $e');
              print('========================================');
            }
            // Fallback: try to navigate to home
            if (mounted) {
              try {
                context.go('/home');
                if (kDebugMode) {
                  print('✅ Fallback navigation attempted');
                }
              } catch (e2) {
                if (kDebugMode) {
                  print('❌ Fallback navigation also failed: $e2');
                }
              }
            }
          }
        } else {
          // ❌ CONFIRMATION: OTP VERIFICATION FAILED
          if (kDebugMode) {
            print('========================================');
            print('❌ OTP VERIFICATION: FAILED');
            print('❌ Response success: ${response['success']}');
            print('❌ Token present: ${response['token'] != null || response['accessToken'] != null}');
            print('❌ NAVIGATION: NOT ATTEMPTED (verification failed)');
            print('========================================');
            print('   Full response: $response');
          }
          
          final errorMessage = response['message'] ?? 
                               response['error'] ?? 
                               'Invalid OTP. Please try again.';
          
          if (kDebugMode) {
            print('   Error message: $errorMessage');
          }
          
          _showError('Verification failed', errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _otpAttempts++;
      });

      if (kDebugMode) {
        print('========================================');
        print('❌ OTP VERIFICATION: EXCEPTION');
        print('❌ Error: $e');
        if (e is DioException && e.response != null) {
          print('   Status Code: ${e.response?.statusCode}');
          print('   Response Data: ${e.response?.data}');
          print('   Error Message: ${e.response?.data?['message'] ?? e.response?.data?['error']}');
        }
        print('========================================');
      }

      if (_otpAttempts >= _maxOTPAttempts) {
        _showError('Too many failed attempts', 'Please request a new OTP');
      } else {
        String errorMsg = 'Invalid OTP. Please check and try again.';
        
        // Check for network connectivity errors first
        if (NetworkUtils.isNetworkError(e)) {
          errorMsg = NetworkUtils.getNetworkErrorMessage(e);
          _showError('No Internet Connection', errorMsg);
          return;
        }
        
        // Extract error message from backend response
        if (e is DioException && e.response != null) {
          final responseData = e.response?.data;
          if (responseData is Map) {
            errorMsg = responseData['message'] ?? 
                      responseData['error'] ?? 
                      'Server error. Please try again.';
            
            // If 500 error, show more details in debug mode
            if (e.response?.statusCode == 500) {
              if (kDebugMode) {
                errorMsg += '\n\nDebug: ${responseData['message'] ?? 'Internal server error'}';
              }
            }
          }
        }
        
        // Handle specific error codes
        if (e.toString().contains('500') || e.toString().contains('Internal Server Error')) {
          errorMsg = 'Server error occurred. Please try again or contact support.';
        } else if (e.toString().contains('404') || e.toString().contains('not registered')) {
          errorMsg = 'Phone number not registered. Please contact administrator.';
        } else if (e.toString().contains('Invalid OTP') || e.toString().contains('expired')) {
          errorMsg = 'Invalid or expired OTP. Please request a new OTP.';
        } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          errorMsg = 'Invalid OTP. Please check the code and try again.';
        } else if (e.toString().contains('Twilio') || e.toString().contains('SMS service')) {
          errorMsg = 'SMS service temporarily unavailable. Please try again later.';
        } else if (e.toString().contains('No Internet Connection') || e.toString().contains('Connection Timeout')) {
          errorMsg = e.toString();
        }
        
        _showError('Verification error', errorMsg);
      }
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() {
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpController.clear();
      _isLoading = true;
    });

    try {
      // Ensure _normalizedPhone is set from entered phone, not stored
      if (_normalizedPhone.isEmpty) {
        // Reconstruct from controller if somehow empty
        final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
        _normalizedPhone = '$_selectedCountryCode$phoneDigits';
        if (kDebugMode) {
          print('⚠️ _normalizedPhone was empty, reconstructed: $_normalizedPhone');
        }
      }
      
      if (kDebugMode) {
        print('📤 Resending OTP to: $_normalizedPhone');
      }
      
      // Call POST /auth/send-otp via Twilio Verify
      await apiService.sendOTP(_normalizedPhone, type: 'login');
      if (kDebugMode) {
        print('✅ OTP resent successfully via Twilio Verify to: $_normalizedPhone');
      }
      
      setState(() {
        _isLoading = false;
        // Clear OTP fields for new entry
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _otpController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent to your phone. Please check your SMS.'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMsg = 'Failed to resend OTP. Please try again.';
        
        // Check for network connectivity errors first
        if (NetworkUtils.isNetworkError(e)) {
          errorMsg = NetworkUtils.getNetworkErrorMessage(e);
          _showError('No Internet Connection', errorMsg);
          return;
        }
        
        // Handle specific Twilio Verify errors
        if (e.toString().contains('404') || e.toString().contains('not registered')) {
          errorMsg = 'Phone number not registered. Please contact administrator.';
        } else if (e.toString().contains('Twilio') || e.toString().contains('SMS service')) {
          errorMsg = 'SMS service temporarily unavailable. Please try again later.';
        } else if (e.toString().contains('Invalid phone')) {
          errorMsg = 'Invalid phone number format. Please check and try again.';
        } else if (e.toString().contains('No Internet Connection') || e.toString().contains('Connection Timeout')) {
          errorMsg = e.toString();
        }
        
        _showError('Resend OTP Error', errorMsg);
      }
    }
  }

  void _showError(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logo & Header
              Column(
                children: [
                  Image.asset(
                    'assets/images/iraq_bid_logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _currentStep == 0
                        ? (AppLocalizations.of(context)?.welcome ?? 'Welcome')
                        : (AppLocalizations.of(context)?.verifyPhone ?? 'Verify Your Phone'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 0
                        ? (AppLocalizations.of(context)?.enterPhone ?? 'Enter your phone number to get started')
                        : '${AppLocalizations.of(context)?.otpSentMessage ?? 'We sent a code to'} $_selectedCountryCode ${_phoneController.text}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentStep == 0) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)?.dontHaveAccount ?? "Don't have an account?"} ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/role-selection?mode=signup');
                          },
                          child: Text(
                            AppLocalizations.of(context)?.signUp ?? 'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 48),

              // Phone Input Step
              if (_currentStep == 0) _buildPhoneStep(isDark).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),

              // OTP Verification Step
              if (_currentStep == 1) _buildOTPStep(isDark).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Number Input
        Row(
          children: [
            // Country Code Selector
            Container(
              width: 120,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  icon: Icon(Icons.arrow_drop_down, size: 20, color: colorScheme.onSurface.withOpacity(0.7)),
                  style: TextStyle(color: colorScheme.onSurface),
                  items: _countryCodes.map((country) {
                    return DropdownMenuItem<String>(
                      value: country.code,
                      child: Text(
                        '${country.country} ${country.code}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: null, // Disabled - only Iraq (+964) supported
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Phone Number Input
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxPhoneLength),
                ],
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
                  labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.phone, size: 20, color: colorScheme.onSurface.withOpacity(0.7)),
                  hintText: '9876543210',
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                autofocus: true,
                onChanged: (_) => _validatePhoneNumber(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          "OTP will be sent to your phone via SMS",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
        ),

        const SizedBox(height: 16),

        // Terms and Conditions Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() {
                  _acceptedTerms = value ?? false;
                });
              },
              activeColor: colorScheme.primary,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _acceptedTerms = !_acceptedTerms;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12,
                          ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.push('/terms-and-conditions');
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.push('/privacy-policy');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Send OTP Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading || !_isPhoneValid || !_acceptedTerms
                ? null
                : _handlePhoneSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                    ),
                  )
                : Text(AppLocalizations.of(context)?.sendOtp ?? 'Send OTP'),
          ),
        ),

      ],
    );
  }

  Widget _buildOTPStep(bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back Button
        TextButton.icon(
          onPressed: () {
            setState(() {
              _currentStep = 0;
            });
          },
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Change phone number'),
        ),

        const SizedBox(height: 24),

        // OTP Input Label
        Center(
          child: Text(
            AppLocalizations.of(context)?.enter6DigitOtp ?? 'Enter 6-digit OTP',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        const SizedBox(height: 24),

        // OTP Input (6 digits for backend)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 48,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  }
                  // Update the main controller for verification check
                  _otpController.text = _enteredOTP;
                  // Trigger rebuild to enable/disable verify button
                  setState(() {});
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // Resend OTP
        Center(
          child: TextButton(
            onPressed: _handleResendOTP,
            child: RichText(
              text: TextSpan(
                text: "Didn't receive the code? ",
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: AppLocalizations.of(context)?.resendOtp ?? 'Resend OTP',
                    style: TextStyle(
                      color: AppColors.blue600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Verify Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading || _enteredOTP.length != 6
                ? null
                : _handleOTPVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                    ),
                  )
                : Text(AppLocalizations.of(context)?.verify ?? 'Verify & Continue'),
          ),
        ),

        const SizedBox(height: 12),

        // Security Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '🔒 Your phone number is secure and will never be shared with third parties',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class CountryCode {
  final String code;
  final String country;
  final int maxLength;

  CountryCode({
    required this.code,
    required this.country,
    required this.maxLength,
  });
}
