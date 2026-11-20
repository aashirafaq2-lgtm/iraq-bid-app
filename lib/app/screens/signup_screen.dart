import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/referral_service.dart';
import '../services/language_service.dart';

// 18 Iraqi Governorates
const List<String> _iraqiGovernorates = [
  'Baghdad', 'Basra', 'Erbil', 'Najaf', 'Karbala',
  'Sulaymaniyah', 'Duhok', 'Kirkuk', 'Anbar', 'Babil',
  'Diyala', 'Wasit', 'Maysan', 'Dhi Qar', 'Muthanna',
  'Qadisiyyah', 'Saladin', 'Nineveh',
];

const Map<String, String> _iraqiGovernoratesAr = {
  'Baghdad': 'بغداد', 'Basra': 'البصرة', 'Erbil': 'أربيل',
  'Najaf': 'النجف', 'Karbala': 'كربلاء', 'Sulaymaniyah': 'السليمانية',
  'Duhok': 'دهوك', 'Kirkuk': 'كركوك', 'Anbar': 'الأنبار',
  'Babil': 'بابل', 'Diyala': 'ديالى', 'Wasit': 'واسط',
  'Maysan': 'ميسان', 'Dhi Qar': 'ذي قار', 'Muthanna': 'المثنى',
  'Qadisiyyah': 'القادسية', 'Saladin': 'صلاح الدين', 'Nineveh': 'نينوى',
};

class SignupScreen extends StatefulWidget {
  final String? selectedRole;
  
  const SignupScreen({
    super.key,
    this.selectedRole,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  
  final String _selectedCountryCode = '+964';
  int _currentStep = 0; // 0: Details & Phone, 1: OTP Verify
  String _normalizedPhone = '';
  bool _isLoading = false;
  bool _isPhoneValid = false;
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadPendingReferralCode();
  }

  Future<void> _loadPendingReferralCode() async {
    final code = await ReferralService.getPendingReferralCode();
    if (code != null && mounted) {
      setState(() {
        _referralController.text = code;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _referralController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _validatePhoneNumber() {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final isValid = phoneDigits.length >= 9 && phoneDigits.length <= 10;
    if (_isPhoneValid != isValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.isEmpty || !_isPhoneValid) {
      _showError(
        LanguageService.isArabic ? 'رقم الهاتف مطلوب' : 'Phone Required',
        LanguageService.isArabic ? 'يرجى إدخال رقم هاتف صحيح' : 'Please enter a valid phone number',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (phoneDigits.startsWith('0') && phoneDigits.length == 11) {
        _normalizedPhone = '+964${phoneDigits.substring(1)}';
      } else if (phoneDigits.startsWith('00964')) {
        _normalizedPhone = '+964${phoneDigits.substring(5)}';
      } else if (phoneDigits.startsWith('964')) {
        _normalizedPhone = '+$phoneDigits';
      } else {
        _normalizedPhone = '$_selectedCountryCode$phoneDigits';
      }

      try {
        await apiService.sendOTP(_normalizedPhone, type: 'register');
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 400) {
          final resData = e.response?.data;
          final isAlreadyExists = resData is Map && (resData['code'] == 'USER_ALREADY_EXISTS' || (resData['message']?.toString().contains("مسجل") ?? false) || (resData['message']?.toString().contains("already registered") ?? false));
          if (isAlreadyExists) {
            setState(() => _isLoading = false);
            _showAccountExistsDialog();
            return;
          }
        }
        if (e is DioException && e.response?.statusCode == 403) {
          setState(() => _isLoading = false);
          _showError(
            LanguageService.isArabic ? 'حساب محظور' : 'Account Banned',
            LanguageService.isArabic ? 'تم حظر هذا الحساب من قبل الإدارة.' : 'This account has been banned by admin.',
          );
          return;
        }
        setState(() => _isLoading = false);
        _showError(
          LanguageService.isArabic ? 'خطأ في الإرسال' : 'Delivery Error',
          LanguageService.isArabic ? 'تعذر إرسال رمز التحقق. يرجى المحاولة لاحقاً.' : 'Failed to send verification code. Please try again.',
        );
        return;
      }
      
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
          ),
        );
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showError(
        LanguageService.isArabic ? 'خطأ في الإرسال' : 'Delivery Error',
        LanguageService.isArabic ? 'تعذر إرسال رمز التحقق. يرجى المحاولة لاحقاً.' : 'Failed to send verification code. Please try again.',
      );
    }
  }

  Future<void> _handleVerifyOTP() async {
    final otp = _otpControllers.map((e) => e.text).join();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;
      try {
        response = await apiService.verifyOTP(
          _normalizedPhone,
          otp,
          type: 'register',
          name: _fullNameController.text.trim(),
        );
      } catch (err) {
        rethrow;
      }
      final accessToken = response['accessToken'] ?? response['token'];
      if (accessToken != null) {
        if (mounted) {
          _showSuccessAndNavigate();
        }
        return;
      }
      await _handleFinalSignup();
    } catch (_) {
      setState(() => _isLoading = false);
      _showError(
        LanguageService.isArabic ? 'رمز غير صحيح' : 'Invalid Code',
        LanguageService.isArabic ? 'الرمز الذي أدخلته غير صحيح أو منتهي الصلاحية' : 'The code you entered is incorrect or expired.',
      );
    }
  }

  Future<void> _handleFinalSignup() async {
    final role = widget.selectedRole ?? 'company_products';

    try {
      final response = await apiService.register(
        name: _fullNameController.text.trim(),
        phone: _normalizedPhone,
        email: null,
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        password: 'temp_password_$_normalizedPhone',
        role: role,
        referralCode: _referralController.text.trim().isNotEmpty ? _referralController.text.trim() : null,
      );

      final accessToken = response['accessToken'] ?? response['token'];
      final user = response['user'];
      
      if (accessToken != null) {
        await StorageService.saveAccessToken(accessToken as String);
      }
      
      if (user != null) {
        await StorageService.saveUserData(
          userId: user['id'] as int,
          role: role,
          phone: _normalizedPhone,
          name: _fullNameController.text.trim(),
          email: user['email'] as String?,
        );
      }

      if (mounted) {
        _showSuccessAndNavigate();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Registration Failed', e.toString());
    }
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService.isArabic
              ? 'تم إنشاء حسابك بنجاح! مرحباً بك'
              : 'Account created successfully! Welcome to Iraq Bid',
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final role = widget.selectedRole ?? 'company_products';
        if (role == 'seller_products') {
          context.go('/seller-dashboard');
        } else {
          context.go('/home');
        }
      }
    });
  }

  void _showAccountExistsDialog() {
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_circle_rounded, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? 'الحساب مسجل بالفعل!' : 'Account Already Exists!',
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
                ? 'هذا الرقم مسجل لدينا بالفعل. يرجى تسجيل الدخول إلى حسابك.'
                : 'This phone number is already registered. Please log in to your account.',
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
                context.go('/auth');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                isAr ? 'تسجيل الدخول' : 'Go to Login',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCityPicker(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_city_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'اختر المحافظة' : 'Select Province',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Grid of cities
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _iraqiGovernorates.length,
                itemBuilder: (_, i) {
                  final city = _iraqiGovernorates[i];
                  final displayName = isAr ? (_iraqiGovernoratesAr[city] ?? city) : city;
                  final isSelected = _cityController.text == city;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _cityController.text = city);
                      Navigator.of(ctx).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageService.isArabic;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep == 1) {
          setState(() => _currentStep = 0);
          _animController.reset();
          _animController.forward();
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
            onPressed: () {
              if (_currentStep == 1) {
                setState(() => _currentStep = 0);
                _animController.reset();
                _animController.forward();
              } else {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              }
            },
          ),
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
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _currentStep == 0 ? _buildRegistrationForm(isAr) : _buildOtpVerification(isAr),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRegistrationForm(bool isAr) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Original Iraq Bid Logo
          Center(
            child: Container(
              width: 170,
              height: 80,
              margin: const EdgeInsets.only(bottom: 8),
              child: Image.asset(
                'assets/images/iraq_bid_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Header
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAr ? 'حساب جديد في مزاد العراق' : 'NEW BUYER ACCOUNT',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'أنشئ حسابك وابدأ المزايدة' : 'Create Account & Start Bidding',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'أدخل بياناتك الشخصية لتأكيد هويتك وتفعيل المحفظة والمزادات'
                : 'Enter your personal details to verify identity and enable bidding',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 28),

          // Full Name
          _buildInputLabel(isAr ? 'الاسم الكامل' : 'Full Name', Icons.person_outline),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _fullNameController,
            hint: isAr ? 'علي حسن الشمري' : 'e.g. Ali Hassan',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (isAr ? 'يرجى إدخال الاسم الكامل' : 'Please enter full name')
                : null,
          ),

          const SizedBox(height: 18),

          // Phone Number
          _buildInputLabel(isAr ? 'رقم الهاتف' : 'Phone Number', Icons.phone_outlined),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isPhoneValid ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+964',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1.1,
                        backgroundColor: Colors.transparent,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: isAr ? '770 123 4567' : '770 123 4567',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // City & Area
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel(isAr ? 'المحافظة' : 'Province / City', Icons.location_city_outlined),
                    const SizedBox(height: 8),
                    // City Dropdown (18 Iraqi Governorates)
                    GestureDetector(
                      onTap: () => _showCityPicker(context, isAr),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: _cityController,
                          hint: isAr ? 'اختر المحافظة' : 'Select Province',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isAr ? 'مطلوب' : 'Required')
                              : null,
                          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel(isAr ? 'المنطقة' : 'District / Area', Icons.pin_drop_outlined),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _areaController,
                      hint: isAr ? 'المنصور' : 'Mansour',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? (isAr ? 'مطلوب' : 'Required')
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Referral Code (Optional)
          _buildInputLabel(isAr ? 'رمز الإحالة (اختياري)' : 'Referral Code (Optional)', Icons.card_giftcard_outlined),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _referralController,
            hint: isAr ? 'أدخل كود الصديق للربح' : 'Enter referral code',
          ),

          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOTP,
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
                          isAr ? 'إرسال كود التأكيد (SMS)' : 'Send Verification OTP',
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

          const SizedBox(height: 18),

          // Back to Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isAr ? 'لديك حساب بالفعل؟' : 'Already have an account?',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.go('/auth'),
                child: Text(
                  isAr ? 'تسجيل الدخول' : 'Sign In',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOtpVerification(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.mark_email_read_outlined, size: 36, color: Color(0xFF0284C7)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isAr ? 'أدخل رمز التحقق' : 'Verify Your Phone',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAr
              ? 'أرسلنا رمزاً مكوناً من 6 أرقام إلى $_normalizedPhone'
              : 'We sent a 6-digit code to $_normalizedPhone',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 32),

        // OTP Row
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
                  width: 1.5,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // Verify & Complete Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_isLoading || _otpControllers.any((c) => c.text.isEmpty))
                ? null
                : _handleVerifyOTP,
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
                    isAr ? 'تأكيد وإنشاء الحساب' : 'Complete Registration',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0284C7)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      ),
    );
  }
}
