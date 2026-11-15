import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class BottomNavBar extends StatelessWidget {
  final Function(BuildContext)? onCategoryTap;

  const BottomNavBar({
    super.key,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, locale, _) {
        final isArabic = LanguageService.isArabic;

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 1. Home
                    _BouncingBottomNavItem(
                      icon: Icons.home_rounded,
                      label: isArabic ? 'الرئيسية' : 'Home',
                      isActive: currentRoute == '/home' || currentRoute == '/seller-dashboard',
                      onTap: () {
                        if (currentRoute != '/home') {
                          context.go('/home');
                        }
                      },
                    ),

                    // 2. Bids
                    _BouncingBottomNavItem(
                      icon: Icons.gavel_rounded,
                      label: isArabic ? 'المزادات' : 'Bids',
                      isActive: currentRoute == '/bids' ||
                          currentRoute == '/buyer-bidding-history' ||
                          currentRoute == '/buyer/bidding-history',
                      onTap: () {
                        context.go('/bids');
                      },
                    ),

                    // 3. Wishlist
                    _BouncingBottomNavItem(
                      icon: Icons.favorite_border_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: isArabic ? 'المفضلة' : 'Wishlist',
                      isActive: currentRoute == '/wishlist',
                      onTap: () {
                        context.go('/wishlist');
                      },
                    ),

                    // 4. Wins
                    _BouncingBottomNavItem(
                      icon: Icons.check_circle_outline_rounded,
                      activeIcon: Icons.check_circle_rounded,
                      label: isArabic ? 'الرابحة' : 'Wins',
                      isActive: currentRoute == '/wins',
                      onTap: () {
                        context.go('/wins');
                      },
                    ),

                    // 5. Profile
                    _BouncingBottomNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: isArabic ? 'حسابي' : 'Profile',
                      isActive: currentRoute == '/profile',
                      onTap: () {
                        context.go('/profile');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BouncingBottomNavItem extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BouncingBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_BouncingBottomNavItem> createState() => _BouncingBottomNavItemState();
}

class _BouncingBottomNavItemState extends State<_BouncingBottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0284C7);
    const inactiveColor = Color(0xFF94A3B8);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? const Color(0xFFE0F2FE)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isActive ? (widget.activeIcon ?? widget.icon) : widget.icon,
                  color: widget.isActive ? activeColor : inactiveColor,
                  size: 23,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: widget.isActive ? activeColor : inactiveColor,
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
