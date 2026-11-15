import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';

class RoleGuard {
  /// Check if user has required role
  static Future<bool> hasRole(String requiredRole) async {
    final userRole = await StorageService.getUserRole();
    return userRole == requiredRole;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await StorageService.isLoggedIn();
  }

  /// Navigate based on user role
  static Future<void> navigateByRole(BuildContext context) async {
    final isLoggedIn = await RoleGuard.isLoggedIn();
    if (!isLoggedIn) {
      context.go('/auth');
      return;
    }

    final role = await StorageService.getUserRole();
    switch (role) {
      case 'company_products':
        context.go('/home');
        break;
      case 'seller_products':
        context.go('/seller-dashboard');
        break;
      case 'admin':
        // Admin should not access mobile app
        context.go('/auth');
        break;
      default:
        context.go('/auth');
    }
  }

  /// Middleware for route protection
  static Future<bool> canAccess(String route) async {
    final isLoggedIn = await RoleGuard.isLoggedIn();
    if (!isLoggedIn) {
      return false;
    }

    final role = await StorageService.getUserRole();

    // Company Products routes
    if (route.startsWith('/home') || route.startsWith('/product-details')) {
      return role == 'company_products';
    }

    // Seller Products routes
    if (route.startsWith('/seller-dashboard')) {
      return role == 'seller_products';
    }

    // Public routes
    if (route == '/auth' || route == '/onboarding' || route == '/splash') {
      return true;
    }

    // Role selection - accessible after login
    if (route == '/role-selection') {
      return true;
    }

    return false;
  }
}

