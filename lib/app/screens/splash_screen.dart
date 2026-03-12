import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/storage_service.dart';
import '../utils/role_guard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo scale and rotate animation
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -180.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Text opacity animation
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    // Progress bar width animation
    _widthAnimation = Tween<double>(begin: 0.0, end: 120.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) async {
      // Check for auto-login after animation completes
      // Ensure SharedPreferences is initialized before navigation
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        try {
          // Ensure storage is ready before checking login status
          final isLoggedIn = await StorageService.isLoggedIn();
          if (isLoggedIn) {
            // User is logged in - router will handle role-based redirect
            await RoleGuard.navigateByRole(context);
          } else {
            // No session - go to home (public browsing)
            context.go('/home');
          }
        } catch (e) {
          // If there's an error, go to auth as fallback
          if (mounted) {
            context.go('/auth');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // BestBid Color Palette
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _primary = Color(0xFF0A3069);
  static const Color _secondary = Color(0xFF2BA8E0);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textLight = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * 3.14159 / 180,
                      child: Container(
                        width: 150, // Increased size for the new logo
                        height: 150,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/iraq_bid_logo.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Animated Text
            AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    children: [
                        // Text removed as logo contains it
                        /* Text(
                        'IRAQ BID',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                      ), */
                      const SizedBox(height: 4),
                      Text(
                        'Win. Sell. Succeed.',
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Animated Progress Bar
            AnimatedBuilder(
              animation: _widthAnimation,
              builder: (context, child) {
                return Container(
                  height: 4,
                  width: _widthAnimation.value,
                  decoration: BoxDecoration(
                    color: _secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
