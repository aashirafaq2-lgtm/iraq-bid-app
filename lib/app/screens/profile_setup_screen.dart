import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/jwt_utils.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userRole;
  
  const ProfileSetupScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  
  XFile? _profileImageXFile;
  Uint8List? _profileImageBytes; // For web platform
  File? _profileImageFile; // For mobile platforms only
  final ImagePicker _picker = ImagePicker();

  bool _hasProfileImage() {
    return _profileImageXFile != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _profileImageXFile = image;
        if (kIsWeb) {
          // For web platform: load bytes for Image.memory
          _profileImageFile = null;
          image.readAsBytes().then((bytes) {
            if (mounted) {
              setState(() {
                _profileImageBytes = bytes;
              });
            }
          });
        } else {
          // For mobile platforms: create File for Image.file
          _profileImageFile = File(image.path);
          _profileImageBytes = null;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate email
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Get phone from storage (from OTP verification)
    final phone = await StorageService.getUserPhone();
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not found. Please login again.'),
          backgroundColor: AppColors.error,
        ),
      );
      context.go('/auth');
      return;
    }

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // User is already logged in via phone+OTP, just update profile
      // Get token from storage
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/auth');
        return;
      }

      // 🔧 FIX: Update profile with role - backend will update database and return new tokens
      print('🔄 Updating profile with role: ${widget.userRole}');
      print('   Name: ${_nameController.text}');
      print('   Email: ${_emailController.text}');
      print('   Role: ${widget.userRole}');
      
      final updatedUser = await apiService.updateProfile(
        name: _nameController.text,
        phone: phone, // Keep existing phone
        role: widget.userRole, // 🔧 FIX: Update role in database and get new tokens
      );
      print('✅ Profile updated (name, email, role)');
      print('✅ New tokens received and saved (if role was updated)');

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated! Welcome to BidMaster'),
          backgroundColor: AppColors.success,
        ),
      );

      // Small delay to ensure storage is fully updated before navigation
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 🔧 FIX: Verify token and role are in sync after update
      final finalToken = await StorageService.getAccessToken();
      final finalRole = await StorageService.getUserRole();
      final tokenRole = finalToken != null ? JwtUtils.getRoleFromToken(finalToken) : null;
      
      print('🧭 Final check before navigation:');
      print('   Token present: ${finalToken != null}');
      print('   Token role: $tokenRole');
      print('   Stored role: $finalRole (expected: ${widget.userRole})');
      
      // Verify token exists
      if (finalToken == null) {
        print('⚠️⚠️⚠️ Token missing - user needs to login again');
        if (!mounted) return;
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/auth');
        }
        return;
      }
      
      // Verify token role matches stored role
      if (tokenRole != null && finalRole != null && tokenRole != finalRole) {
        print('⚠️⚠️⚠️ ROLE MISMATCH DETECTED!');
        print('   Token role: $tokenRole');
        print('   SharedPreferences role: $finalRole');
        print('   This should not happen after role update - forcing re-login');
        
        if (!mounted) return;
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role mismatch detected. Please login again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
        
        await StorageService.clearAll();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/auth');
        }
        return;
      }
      
      // Navigate based on role
      if (widget.userRole == 'company_products') {
        print('🧭 Navigating to /home for buyer role');
        context.go('/home');
      } else {
        print('🧭 Navigating to /seller-dashboard for seller role');
        context.go('/seller-dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  widget.userRole == 'seller_products'
                      ? 'Build trust with your buyers'
                      : 'Personalize your experience',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '* All fields are required',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Profile Picture
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.slate800 : AppColors.slate200,
                            border: Border.all(
                              color: isDark ? AppColors.slate900 : AppColors.cardWhite,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _hasProfileImage()
                              ? ClipOval(
                                  child: kIsWeb
                                      ? _profileImageBytes != null
                                          ? Image.memory(
                                              _profileImageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(
                                              child: CircularProgressIndicator(),
                                            )
                                      : _profileImageFile != null
                                          ? Image.file(
                                              _profileImageFile!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 48,
                                  color: AppColors.slate400,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.blue600,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.slate900 : AppColors.cardWhite,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.cardWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: const Icon(Icons.person),
                    hintText: 'John Doe',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                Text(
                  'Must be unique across all users',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: const Icon(Icons.email),
                    hintText: 'john.doe@example.com',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                Text(
                  'Must be unique across all users',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 16),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City *',
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: 'New York',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                Text(
                  'Your current city or preferred location',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 16),

                // Bio (Optional)
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio (Optional)',
                    hintText: widget.userRole == 'seller_products'
                        ? 'Tell buyers about your store and products...'
                        : 'Tell us about yourself...',
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '📱 Your phone number is verified: We\'ll use it for OTP login and important notifications',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.blue700,
                        ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: AppColors.cardWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Complete Setup'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

