import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../utils/role_guard.dart';
import '../services/language_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2900), () async {
      if (!mounted) return;
      try {
        final isLoggedIn = await StorageService.isLoggedIn();
        if (!mounted) return;
        if (isLoggedIn) {
          await RoleGuard.navigateByRole(context);
        } else {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          context.go('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageService.isArabic;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Soft Ambient Luxury Gradient Orbs
          Positioned(
            top: -size.width * 0.35,
            right: -size.width * 0.25,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x220284C7),
                    Color(0x0838BDF8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.35,
            left: -size.width * 0.25,
            child: Container(
              width: size.width * 0.85,
              height: size.width * 0.85,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x18F59E0B),
                    Color(0x06FEF08A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Central Ultra-Luxury Branding
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Pulsing Original Iraq Bid Logo
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 220,
                      height: 140,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Image.asset(
                        'assets/images/iraq_bid_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                      .animate()
                      .scaleXY(begin: 0.6, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 16),

                  const SizedBox(height: 8),

                  // Bilingual Subtitle
                  Text(
                    isArabic
                        ? 'الـمـنـصـة الـرسـمـيـة الأولـى لـلـمـزادات الـحـيـة فـي الـعـراق'
                        : 'Iraq\'s #1 Verified Live Auction Marketplace',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

                  const SizedBox(height: 36),

                  // Animated Smooth Loading Bar
                  SizedBox(
                    width: 140,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 750.ms, duration: 500.ms),
                ],
              ),
            ),
          ),

          // 3. Bottom Security Footnote
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 15,
                  color: Color(0xFF0284C7),
                ),
                const SizedBox(width: 6),
                Text(
                  isArabic
                      ? 'مـوثـق ومـحـمـي بـأعـلـى مـعـايـيـر الأمـان'
                      : '100% Encrypted & Officially Verified Platform',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 950.ms, duration: 600.ms),
        ],
      ),
    );
  }
}
