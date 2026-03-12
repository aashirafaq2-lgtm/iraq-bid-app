import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../utils/rtl_helper.dart';
import '../services/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  final Function(BuildContext)? onCategoryTap;
  
  const BottomNavBar({
    super.key,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = GoRouterState.of(context).uri.path;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home,
                label: AppLocalizations.of(context)?.home ?? 'Home',
                isActive: currentRoute == '/home' || currentRoute == '/seller-dashboard',
                onTap: () {
                  if (currentRoute != '/home') {
                    context.go('/home');
                  }
                },
              ),
              _BottomNavItem(
                icon: Icons.gavel,
                label: AppLocalizations.of(context)?.myBids ?? 'Bids',
                isActive: currentRoute == '/buyer-bidding-history' || 
                         currentRoute == '/buyer/bidding-history',
                onTap: () {
                  context.go('/buyer-bidding-history');
                },
              ),
              _BottomNavItem(
                icon: Icons.favorite_border,
                label: AppLocalizations.of(context)?.wishlist ?? 'Wishlist',
                isActive: currentRoute == '/wishlist',
                onTap: () {
                  context.go('/wishlist');
                },
              ),
              _BottomNavItem(
                icon: Icons.check_circle_outline,
                label: AppLocalizations.of(context)?.wins ?? 'Wins',
                isActive: currentRoute == '/wins',
                onTap: () {
                  context.go('/wins');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive 
                  ? AppColors.primaryBlue 
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive 
                    ? AppColors.primaryBlue 
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
