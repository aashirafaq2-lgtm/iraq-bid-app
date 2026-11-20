import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/app_localizations.dart';
import '../services/language_service.dart';
import '../utils/network_utils.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
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
  final String _selectedCountryCode = '+964';
  bool _isLoading = false;
  bool _isPhoneValid = false;
  String _normalizedPhone = '';
  bool _acceptedTerms = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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

  bool get _isPhoneNumberValid {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
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

  Future<void> _handlePhoneSubmit() async {
    if (!_isPhoneValid) {
      _showError(
        AppLocalizations.of(context)?.invalidPhone ?? 'Invalid Phone Number',
        AppLocalizations.of(context)?.enterValidPhone ?? 'Please enter a valid 10-digit phone number',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      String normalizedPhone = '';

      if (phoneDigits.startsWith('0')) {
        normalizedPhone = '+964${phoneDigits.substring(1)}';
      } else if (phoneDigits.startsWith('00964')) {
        normalizedPhone = '+964${phoneDigits.substring(5)}';
      } else if (phoneDigits.startsWith('964')) {
        normalizedPhone = '+$phoneDigits';
      } else {
        normalizedPhone = '$_selectedCountryCode$phoneDigits';
      }

      final digitsAfterPrefix = normalizedPhone.substring(4);
      if (digitsAfterPrefix.length != 10) {
        _showError(
          AppLocalizations.of(context)?.invalidPhone ?? 'Invalid Phone Number',
          AppLocalizations.of(context)?.phoneMustBe10Digits ?? 'Phone number must be exactly 10 digits',
        );
        setState(() => _isLoading = false);
        return;
      }

      _normalizedPhone = normalizedPhone;
      final res = await apiService.sendOTP(_normalizedPhone, type: 'login');

      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
      _animController.reset();
      _animController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService.isArabic
                  ? 'تم إرسال رمز التحقق إلى $_normalizedPhone عبر الواتساب والرسائل'
                  : 'Verification code sent to $_normalizedPhone via SMS & WhatsApp',
            ),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 404) {
          final resData = e.response?.data;
          final isUserNotFound = resData is Map && (resData['code'] == 'USER_NOT_FOUND' || (resData['message']?.toString().contains("account") ?? false));
          if (isUserNotFound) {
            _showNoAccountDialog();
            return;
          }
        }

        String errorMsg = AppLocalizations.of(context)?.failedToSendOtp ?? 'Failed to send OTP';
        if (NetworkUtils.isNetworkError(e)) {
          errorMsg = NetworkUtils.getNetworkErrorMessage(e);
        } else if (e is DioException && e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        }
        _showError('Authentication Error', errorMsg);
      }
    }
  }

  void _showNoAccountDialog() {
    final isAr = LanguageService.isArabic;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_off_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? 'لم يتم العثور على حساب!' : 'No Account Found!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isAr
                ? 'ليس لديك حساب حتى الآن. يرجى إنشاء حساب جديد للمتابعة.'
                : 'You don’t have an account yet. Please create an account to continue.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isAr ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                isAr ? 'إنشاء حساب جديد' : 'Create Account',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  String get _enteredOTP => _otpControllers.map((c) => c.text).join();

  Future<void> _handleOTPVerify() async {
    final otp = _enteredOTP;
    if (otp.length != 6) {
      _showError(
        AppLocalizations.of(context)?.invalidOtp ?? 'Invalid OTP',
        AppLocalizations.of(context)?.enter6DigitOtp ?? 'Please enter the complete 6-digit code',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_normalizedPhone.isEmpty) {
        final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
        _normalizedPhone = '$_selectedCountryCode$phoneDigits';
      }

      final response = await apiService.verifyOTP(
        _normalizedPhone,
        otp,
        type: 'login',
      );

      setState(() => _isLoading = false);

      final hasSuccess = response['success'] == true;
      final hasToken = response['token'] != null || response['accessToken'] != null;

      if (hasSuccess && hasToken) {
        final user = response['user'];
        final role = (response['role'] ?? user?['role'] ?? 'company_products').toString().toLowerCase();

        final savedToken = await StorageService.getToken();
        if (savedToken == null) {
          final accessToken = response['accessToken'] ?? response['token'];
          if (accessToken != null) {
            await StorageService.saveToken(accessToken as String);
          }
        }

        if (user != null && user['id'] != null) {
          await StorageService.saveUserData(
            userId: user['id'] as int,
            role: role,
            phone: _normalizedPhone,
            name: user['name'] as String?,
            email: user['email'] as String?,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LanguageService.isArabic
                    ? 'تم تسجيل الدخول بنجاح! أهلاً بك في منصة مزاد العراق'
                    : 'Login successful! Welcome to Iraq Bid Platform',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        final name = user?['name'] as String?;
        final isNewUser = name == null || name.isEmpty;

        if (isNewUser) {
          context.go('/signup');
        } else {
          if (role == 'seller_products') {
            context.go('/seller-dashboard');
          } else {
            context.go('/home');
          }
        }
      } else {
        _showError('Verification Failed', 'Invalid response from server');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMsg = 'Failed to verify OTP';
        if (e is DioException && e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        }
        _showError('Verification Error', errorMsg);
      }
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() => _isLoading = true);
    try {
      await apiService.sendOTP(_normalizedPhone, type: 'login');
      setState(() {
        _isLoading = false;
        for (var c in _otpControllers) {
          c.clear();
        }
        _otpController.clear();
      });
      _otpFocusNodes[0].requestFocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageService.isArabic
                  ? 'تم إعادة إرسال رمز التحقق إلى $_normalizedPhone'
                  : 'Verification code resent to $_normalizedPhone',
            ),
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('Resend Error', 'Failed to resend OTP. Please wait a moment.');
      }
    }
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageService.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
                onPressed: () {
                  setState(() => _currentStep = 0);
                  _animController.reset();
                  _animController.forward();
                },
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () {
                final newLang = isAr ? 'English' : 'Arabic';
                LanguageService.setLanguage(newLang);
                setState(() {});
              },
              icon: const Icon(Icons.language, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                isAr ? 'English' : 'العربية',
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Luxury Original Iraq Bid Logo
                  Container(
                    width: 180,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Image.asset(
                      'assets/images/iraq_bid_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title & Subtitle
                  Text(
                    _currentStep == 0
                        ? (isAr ? 'تسجيل الدخول إلى مزاد العراق' : 'Welcome to Iraq Bid')
                        : (isAr ? 'تأكيد الرمز السري (OTP)' : 'Verify Phone Number'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 0
                        ? (isAr
                            ? 'أدخل رقم هاتفك لتسجيل الدخول بأمان واستكشاف المزادات المباشرة'
                            : 'Enter your phone number to access live auctions and exclusive deals')
                        : (isAr
                            ? 'تم إرسال رمز التأكيد المكون من 6 أرقام إلى $_selectedCountryCode ${_phoneController.text}'
                            : 'We sent a 6-digit verification code to $_selectedCountryCode ${_phoneController.text}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Section
                  if (_currentStep == 0) _buildPhoneStep(isAr) else _buildOtpStep(isAr),

                  const SizedBox(height: 24),

                  // Security & Guarantee Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr
                              ? 'حماية مشفرة 100% ورقمك محمي بالكامل'
                              : '100% Encrypted & Bank-Grade Security',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Input Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPhoneValid ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
              width: _isPhoneValid ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              // Country Code Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.flag_circle, size: 18, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text(
                      '+964',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Phone Number Field
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: 1.2,
                      backgroundColor: Colors.transparent,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: isAr ? '770 123 4567' : '770 123 4567',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      counterText: '',
                    ),
                    onChanged: (_) => _validatePhoneNumber(),
                  ),
                ),
              ),

              if (_isPhoneValid)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Text(
          isAr
              ? 'يرجى إدخال 10 أرقام (مثال: 7701234567)'
              : 'Enter exactly 10 digits (e.g. 7701234567)',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 16),

        // Terms Agreement Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _acceptedTerms,
                activeColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) => setState(() => _acceptedTerms = val ?? true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  children: [
                    TextSpan(text: isAr ? 'أوافق على ' : 'I agree to the '),
                    TextSpan(
                      text: isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/terms-and-conditions'),
                    ),
                    TextSpan(text: isAr ? ' و ' : ' and '),
                    TextSpan(
                      text: isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/privacy-policy'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Send OTP Action Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_isLoading || !_isPhoneValid || !_acceptedTerms) ? null : _handlePhoneSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAr ? 'إرسال رمز التأكيد' : 'Send Verification Code',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Signup Navigation Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAr ? 'ليس لديك حساب بعد؟' : "Don't have an account?",
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => context.push('/signup'),
              child: Text(
                isAr ? 'إنشاء حساب جديد' : 'Register Now',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpStep(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 6-digit OTP Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _otpControllers[index].text.isNotEmpty
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE2E8F0),
                  width: _otpControllers[index].text.isNotEmpty ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    backgroundColor: Colors.transparent,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (val) {
                    if (val.length > 1) {
                      final digits = val.replaceAll(RegExp(r'\D'), '');
                      for (int i = 0; i < 6 && (index + i) < 6 && i < digits.length; i++) {
                        _otpControllers[index + i].text = digits[i];
                      }
                      final nextIndex = (index + digits.length).clamp(0, 5);
                      _otpFocusNodes[nextIndex].requestFocus();
                      setState(() {});
                      if (_enteredOTP.length == 6) {
                        _handleOTPVerify();
                      }
                      return;
                    }
                    if (val.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    setState(() {});
                    if (_enteredOTP.length == 6) {
                      _handleOTPVerify();
                    }
                  },
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // Resend Action
        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : _handleResendOTP,
            icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF0284C7)),
            label: Text(
              isAr ? 'لم تستلم الرمز؟ إعادة الإرسال' : "Didn't receive code? Resend SMS",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Verify and Continue Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_isLoading || _enteredOTP.length != 6) ? null : _handleOTPVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isAr ? 'تأكيد ودخول المنصة' : 'Verify & Enter Platform',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
