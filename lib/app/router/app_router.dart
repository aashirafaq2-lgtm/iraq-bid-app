import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/buyer_dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_details_screen.dart';
import '../screens/seller_dashboard_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/product_creation_screen.dart';
import '../screens/invite_and_earn_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/buyer_bidding_history_screen.dart';
import '../screens/seller_earnings_screen.dart';
import '../screens/seller_winner_details_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/wins_screen.dart';
import '../screens/terms_and_conditions_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/seller_analytics_screen.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_nav_bar.dart';

/// Application router configuration
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isLoggedIn = await StorageService.isLoggedIn();
      final location = state.uri.path;

      // Public routes - no auth required (users can browse)
      if (location == '/splash' || location == '/auth') {
        return null;
      }

      // Public browsing routes - home and product details (no login required)
      if (location == '/home' || location.startsWith('/product-details')) {
        return null; // Allow public access to browse
      }

      // Signup route - Allows public access to fill the form (OTP will be required during submission)
      if (location == '/signup') {
        return null;
      }

      // Terms and Conditions and Privacy Policy - public access (no login required)
      if (location == '/terms-and-conditions' || location == '/privacy-policy') {
        return null; // Allow public access to view terms and privacy policy
      }

      // Role selection - allows public access for signup flow
      if (location == '/role-selection') {
        // Allow if it's signup mode (mode=signup query parameter)
        final uri = state.uri;
        if (uri.queryParameters['mode'] == 'signup') {
          return null; // Allow signup flow
        }
        // Check if user is logged in for existing user role switching
        if (!isLoggedIn) {
          return '/auth';
        }
        return null;
      }

      // Protected routes - require authentication
      final savedPhone = await StorageService.getUserPhone();
      final savedRole = await StorageService.getUserRole();
      if (!isLoggedIn && savedPhone == null && savedRole == null) {
        return '/auth';
      }

      // Get user role
      final role = await StorageService.getUserRole();

      // Admin blocked from mobile app (only 'admin', not 'superadmin'/'moderator'/'viewer')
      if (role == 'admin') {
        await StorageService.clearAll();
        return '/auth';
      }
      
      // Allow admin roles (superadmin, moderator, viewer) to access role-selection
      if (role == 'superadmin' || role == 'moderator' || role == 'viewer') {
        if (location == '/role-selection') {
          return null;
        }
        // For admin roles trying to access company_products/seller_products routes, redirect to role-selection
        if (location.startsWith('/home') || location.startsWith('/seller-dashboard')) {
          return '/role-selection';
        }
      }

      // Seller Products routes
      if (location.startsWith('/seller-dashboard') || location == '/product-create') {
        if (role != 'seller_products') {
          // Redirect to appropriate dashboard
          return role == 'company_products' ? '/home' : '/role-selection';
        }
      }

      // Notifications - accessible to both company_products and seller_products
      if (location == '/notifications') {
        if (role != 'company_products' && role != 'seller_products') {
          return '/auth';
        }
      }

      // Wallet - accessible to both company_products and seller_products
      if (location == '/wallet') {
        // Check if user is logged in
        if (!isLoggedIn) {
          return '/auth';
        }
        // Allow access - wallet screen will handle role validation and show appropriate error
        // Don't block navigation based on role in router
        return null;
      }

      // Profile - accessible to both company_products and seller_products
      if (location == '/profile') {
        if (role != 'company_products' && role != 'seller_products') {
          return '/auth';
        }
      }

      // My Bids - accessible to both company_products and seller_products (sellers can bid on other products too)
      if (location == '/buyer/bidding-history' || location == '/buyer-bidding-history') {
        // Allow both company_products and seller_products to see their bids
        if (role != 'company_products' && role != 'seller_products') {
          return '/role-selection';
        }
        // Both roles can access - no redirect needed
        return null;
      }

      // Wishlist and Wins - accessible to both company_products and seller_products
      if (location == '/wishlist' || location == '/wins') {
        if (role != 'company_products' && role != 'seller_products') {
          return '/role-selection';
        }
      }

      // Seller Products routes
      if (location == '/seller/earnings' || location.startsWith('/seller/winner/')) {
        if (role != 'seller_products') {
          return role == 'company_products' ? '/home' : '/role-selection';
        }
      }

      return null; // Allow navigation
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return SignupScreen(selectedRole: role);
        },
      ),
      // ShellRoute for persistent bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: const BottomNavBar(),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => HomeScreen(),
          ),
          GoRoute(
            path: '/seller-dashboard',
            name: 'seller-dashboard',
            builder: (context, state) => const SellerDashboardScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/invite-and-earn',
            name: 'invite-and-earn',
            builder: (context, state) => const InviteAndEarnScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/buyer/bidding-history',
            name: 'buyer-bidding-history',
            builder: (context, state) => const BuyerBiddingHistoryScreen(),
          ),
          // Alias route for /buyer-bidding-history (hyphen format)
          GoRoute(
            path: '/buyer-bidding-history',
            name: 'buyer-bidding-history-alias',
            redirect: (context, state) => '/buyer/bidding-history',
          ),
          GoRoute(
            path: '/seller/earnings',
            name: 'seller-earnings',
            builder: (context, state) => const SellerEarningsScreen(),
          ),
          GoRoute(
            path: '/wishlist',
            name: 'wishlist',
            builder: (context, state) => const WishlistScreen(),
          ),
          GoRoute(
            path: '/wins',
            name: 'wins',
            builder: (context, state) => const WinsScreen(),
          ),
          GoRoute(
            path: '/seller/analytics',
            name: 'seller-analytics',
            builder: (context, state) => const SellerAnalyticsScreen(),
          ),
        ],
      ),
      // Fullscreen routes (no bottom nav)
      GoRoute(
        path: '/product-details/:id',
        name: 'product-details',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '1';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ProductDetailsScreen(productId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutQuart;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/product-create',
        name: 'product-create',
        builder: (context, state) {
          final product = state.extra as ProductModel?;
          return ProductCreationScreen(productToEdit: product);
        },
      ),
      GoRoute(
        path: '/seller/winner/:productId',
        name: 'seller-winner-details',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '1';
          return SellerWinnerDetailsScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/terms-and-conditions',
        name: 'terms-and-conditions',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
}

