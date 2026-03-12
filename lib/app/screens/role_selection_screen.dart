import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../utils/jwt_utils.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  bool _isNavigating = false;
  bool _isSignupMode = false; // Check if this is signup flow

  // No hardcoded colors - using theme colors
  // Note: iconColor will be set dynamically in _RoleCard based on theme

  final List<RoleOption> _roles = [
    RoleOption(
      id: 'company_products',
      title: 'Company products',
      description: '',
      icon: Icons.inventory_2_outlined,
      iconColor: null, // Will be set from theme
    ),
    RoleOption(
      id: 'seller_products',
      title: 'Sellers products',
      description: '',
      icon: Icons.store_outlined,
      iconColor: null, // Will be set from theme
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Check if this is signup mode from route parameters
    final uri = GoRouterState.of(context).uri;
    _isSignupMode = uri.queryParameters['mode'] == 'signup';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Header
              Text(
                'Type of product',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Role Options
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _roles.map((role) {
                      final isSelected = _selectedRole == role.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RoleCard(
                          role: role,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedRole = role.id;
                            });
                          },
                          colorScheme: colorScheme,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedRole == null || _isNavigating
                      ? null
                      : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor:
                        colorScheme.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isNavigating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Continue'),
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
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedRole == null || _isNavigating) return;

    // Check if this is signup mode from route parameters
    final uri = GoRouterState.of(context).uri;
    final isSignupMode = uri.queryParameters['mode'] == 'signup';

    // If signup mode, navigate to signup form
    if (isSignupMode) {
      if (mounted) {
        context.push('/signup?role=$_selectedRole');
      }
      return;
    }

    // Check if user is logged in before proceeding
    final isLoggedIn = await StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();
    
    if (!isLoggedIn || accessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        // Redirect to login after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/auth');
          }
        });
      }
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    if (kDebugMode) {
      print('🔄 Role selection: $_selectedRole');
    }

    try {
      // 🔧 FIX: Check if user already has the selected role saved
      // If so, skip the updateProfile API call and navigate directly
      // This prevents the 401 loop that caused Apple's "login again" rejection
      final currentStoredRole = await StorageService.getUserRole();
      final accessToken = await StorageService.getAccessToken();
      
      if (currentStoredRole == _selectedRole && accessToken != null) {
        // User already has the correct role - navigate directly without API call
        if (kDebugMode) {
          print('✅ User already has role: $currentStoredRole - navigating directly (no API call needed)');
        }
        if (mounted) {
          if (_selectedRole == 'company_products') {
            context.go('/home');
          } else if (_selectedRole == 'seller_products') {
            context.go('/seller-dashboard');
          }
        }
        return;
      }

      if (kDebugMode) {
        print('   Updating role in database via updateProfile API...');
      }

      var userId = await StorageService.getUserId();
      var phone = await StorageService.getUserPhone();
      
      // 🔧 FIX: If user data is missing, try to fetch from profile endpoint
      if (userId == null || phone == null) {
        if (kDebugMode) {
          print('⚠️ Warning: userId or phone is null, attempting to fetch from profile...');
        }
        try {
          final profile = await apiService.getProfile();
          userId = profile.id;
          phone = profile.phone;
          
          // Save the fetched user data
          await StorageService.saveUserData(
            userId: profile.id,
            role: profile.role,
            phone: profile.phone,
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login first'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go('/auth');
              }
            });
          }
          setState(() {
            _isNavigating = false;
          });
          return;
        }
      }
      
      // Final check - if still null after fetch attempt, redirect to login
      if (userId == null || phone == null) {
        if (kDebugMode) {
          print('❌ Error: userId or phone is still null after fetch attempt');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/auth');
            }
          });
        }
        setState(() {
          _isNavigating = false;
        });
        return;
      }

      // Call updateProfile API to update role in database and get new tokens
      await apiService.updateProfile(role: _selectedRole!);
      if (kDebugMode) {
        print('✅ Role updated in database via API');
        print('✅ New tokens received and saved with role: $_selectedRole');
      }

      // Verify role was saved correctly
      final savedRole = await StorageService.getUserRole();
      final token = await StorageService.getAccessToken();
      final tokenRole = token != null ? JwtUtils.getRoleFromToken(token) : null;
      
      if (kDebugMode) {
        print('   Verified saved role: $savedRole');
        print('   Verified token role: $tokenRole');
      }
      
      if (savedRole != _selectedRole) {
        if (kDebugMode) {
          print('⚠️ Warning: Saved role mismatch - retrying...');
        }
        // Role should have been updated by updateProfile, but verify
        await StorageService.saveUserData(
          userId: userId,
          role: _selectedRole!,
          phone: phone,
          name: await StorageService.getUserName(),
          email: await StorageService.getUserEmail(),
        );
      }

      // Small delay for smooth visual feedback before navigation
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        if (kDebugMode) {
          print('   Navigating to dashboard with role: $_selectedRole');
        }
        try {
          // Skip profile-setup, go directly to dashboard based on role
          if (_selectedRole == 'company_products') {
            context.go('/home');
          } else if (_selectedRole == 'seller_products') {
            context.go('/seller-dashboard');
          }
          if (kDebugMode) {
            print('✅ Navigation successful');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Navigation error: $e');
          }
          setState(() {
            _isNavigating = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating role: $e');
      }
      if (mounted) {
        // Check if error is due to authentication failure
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('401') || 
            errorMessage.contains('unauthorized') || 
            errorMessage.contains('token') ||
            errorMessage.contains('login') ||
            errorMessage.contains('session expired')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/auth');
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update role: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }
}

class _RoleCard extends StatefulWidget {
  final RoleOption role;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_RoleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
              child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.colorScheme.primary
                      : widget.colorScheme.onSurface.withOpacity(0.2),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.role.icon,
                      size: 32,
                      color: widget.isSelected ? widget.colorScheme.primary : widget.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Text(
                      widget.role.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: widget.isSelected ? widget.colorScheme.primary : widget.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RoleOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor; // Now nullable since we use theme colors

  RoleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor, // Now optional
  });
}

