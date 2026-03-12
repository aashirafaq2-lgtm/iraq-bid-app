import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/referral_service.dart';

class SignupScreen extends StatefulWidget {
  final String? selectedRole; // 'company_products' or 'seller_products'
  
  const SignupScreen({
    super.key,
    this.selectedRole,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  
  String _selectedCountryCode = '+964'; // Default to Iraq
  int _currentStep = 0; // 0: Phone, 1: OTP, 2: Profile
  String _normalizedPhone = '';
  bool _isLoading = false;
  bool _isPhoneValid = false;
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
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

  /// Step 0: Send OTP after validating all fields
  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.isEmpty) {
      _showError('Phone Required', 'Please enter your phone number');
      return;
    }

    if (!_isPhoneValid) {
      _showError('Invalid Phone Number', 'Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Normalize phone number
      if (phoneDigits.startsWith('0') && phoneDigits.length == 11) {
        _normalizedPhone = '+964${phoneDigits.substring(1)}';
      } else if (phoneDigits.startsWith('00964')) {
        _normalizedPhone = '+964${phoneDigits.substring(5)}';
      } else if (phoneDigits.startsWith('964')) {
        _normalizedPhone = '+$phoneDigits';
      } else {
        _normalizedPhone = '$_selectedCountryCode$phoneDigits';
      }

      await apiService.sendOTP(_normalizedPhone, type: 'register');
      
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error', 'Failed to send verification code. Please try again.');
    }
  }

  /// Step 1: Verify OTP and then Register
  Future<void> _handleVerifyOTP() async {
    final otp = _otpControllers.map((e) => e.text).join();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final response = await apiService.verifyOTP(_normalizedPhone, otp, type: 'register');
      
      // If user already exists, tokens will be in response
      final accessToken = response['accessToken'] ?? response['token'];
      if (accessToken != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome back! Logging you in...'), backgroundColor: Colors.green),
          );
          _showSuccessAndNavigate();
        }
        return;
      }

      // If user doesn't exist, proceed to register immediately with data from Step 0
      await _handleFinalSignup();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Verification Failed', 'The code you entered is incorrect or expired.');
    }
  }

  /// Registration logic (called after OTP verification)
  Future<void> _handleFinalSignup() async {
    if (widget.selectedRole == null) {
      _showError('Role Required', 'Please select a role first');
      return;
    }

    try {
      final response = await apiService.register(
        name: _fullNameController.text.trim(),
        phone: _normalizedPhone,
        email: null,
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        password: 'temp_password_${_normalizedPhone}',
        role: widget.selectedRole!,
        referralCode: _referralController.text.trim().isNotEmpty ? _referralController.text.trim() : null,
      );

      // Save tokens and user data
      final accessToken = response['accessToken'] ?? response['token'];
      final user = response['user'];
      
      if (accessToken != null) {
        await StorageService.saveAccessToken(accessToken as String);
      }
      
      if (user != null) {
        await StorageService.saveUserData(
          userId: user['id'] as int,
          role: widget.selectedRole!,
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
      const SnackBar(
        content: Text('Account ready!'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (widget.selectedRole == 'company_products') {
          context.go('/home');
        } else if (widget.selectedRole == 'seller_products') {
          context.go('/seller-dashboard');
        } else {
          context.go('/home');
        }
      }
    });
  }

  void _showError(String title, String message) {
    if (!mounted) return;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            if (_currentStep == 0) {
              context.pop();
            } else if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colorScheme),
              const SizedBox(height: 40),
              if (_currentStep == 0) _buildSignupFieldsStep(colorScheme),
              if (_currentStep == 1) _buildOTPStep(colorScheme),
              
              if (_currentStep == 0) ...[
                const SizedBox(height: 16),
                _buildLoginLink(colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    String title = 'Create Your Account';
    String subtitle = 'Fill in your details to get started';

    if (_currentStep == 1) {
      title = 'Verify Your Phone';
      subtitle = 'We sent a 6-digit code to $_normalizedPhone';
    }

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _currentStep == 1 ? Icons.phonelink_lock : Icons.person_add,
            size: 32,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignupFieldsStep(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full name',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          // Phone Number
          Row(
            children: [
              Container(
                width: 100,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.2)),
                ),
                alignment: Alignment.center,
                child: const Text('🇮🇶 +964', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => _validatePhoneNumber(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // City
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'City',
              prefixIcon: const Icon(Icons.location_city),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'City is required' : null,
          ),
          const SizedBox(height: 16),

          // Area
          TextFormField(
            controller: _areaController,
            decoration: InputDecoration(
              labelText: 'Area',
              prefixIcon: const Icon(Icons.map_outlined),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Area is required' : null,
          ),
          const SizedBox(height: 16),

          // Invited Code
          TextFormField(
            controller: _referralController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Invited code',
              prefixIcon: const Icon(Icons.card_giftcard),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading || !_isPhoneValid ? null : _handleSendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Verification Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPStep(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (_otpControllers.map((e) => e.text).join().length == 6) {
                    _handleVerifyOTP();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        if (_isLoading) const CircularProgressIndicator(),
        TextButton(
          onPressed: _isLoading ? null : () => setState(() => _currentStep = 0),
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }

  Widget _buildLoginLink(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? '),
        TextButton(
          onPressed: () => context.go('/auth'),
          child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
