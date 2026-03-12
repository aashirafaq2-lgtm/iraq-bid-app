import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../theme/colors.dart';
import '../utils/rtl_helper.dart';

class HomeHeader extends StatefulWidget {
  final TextEditingController? searchController;
  final VoidCallback? onSearchSubmitted;
  final VoidCallback? onRoleChanged;
  final VoidCallback? onSellerStatsPressed;
  final bool showBackButton;

  const HomeHeader({
    super.key,
    this.searchController,
    this.onSearchSubmitted,
    this.onRoleChanged,
    this.onSellerStatsPressed,
    this.showBackButton = false,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? _currentRole;
  bool _isLoadingRole = true;
  bool _isSwitchingRole = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentRole();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadCurrentRole() async {
    final role = await StorageService.getUserRole();
    setState(() {
      _currentRole = role;
      _isLoadingRole = false;
    });
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final isLoggedIn = await StorageService.isLoggedIn();
      if (!isLoggedIn) return;
      
      final count = await apiService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Silently fail - notification count is not critical
      if (kDebugMode) {
        print('Failed to load unread notification count: $e');
      }
    }
  }

  Future<void> _switchRole(String newRole) async {
    if (_isSwitchingRole) return;

    // If role is the same, just ensure we are on the home screen (browse mode)
    if (_currentRole == newRole) {
      if (mounted) {
        final currentPath = GoRouterState.of(context).uri.path;
        if (currentPath != '/home') {
          context.go('/home');
        }
      }
      return;
    }

    setState(() {
      _isSwitchingRole = true;
    });

    try {
      // Check token before role switch
      final token = await StorageService.getAccessToken();
      if (kDebugMode) {
        print('🔄 Role switch: Checking token before update');
        print('   Has token: ${token != null}');
        print('   Current role: $_currentRole');
        print('   New role: $newRole');
      }
      
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.pleaseLoginFirst ?? 'Please login first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/auth');
            }
          });
        }
        setState(() {
          _isSwitchingRole = false;
        });
        return;
      }
      
      await apiService.updateProfile(role: newRole);
      
      // Reload role from storage after update (in case it was updated by API)
      final updatedRole = await StorageService.getUserRole();
      
      setState(() {
        _currentRole = updatedRole ?? newRole;
        _isSwitchingRole = false;
      });

      // Notify parent to refresh products
      widget.onRoleChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.roleSwitched ?? 'Role switched to'} ${newRole == 'seller_products' ? (AppLocalizations.of(context)?.sellerProducts ?? 'Seller Products') : (AppLocalizations.of(context)?.companyProducts ?? 'Company Products')}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate to home to show the products browse view for whichever role was selected
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        _isSwitchingRole = false;
      });

      if (mounted) {
        // Check if error is due to authentication failure
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('401') || 
            errorMessage.contains('unauthorized') || 
            errorMessage.contains('token') ||
            errorMessage.contains('login') ||
            errorMessage.contains('session expired') ||
            errorMessage.contains('no access token')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.pleaseLoginFirst ?? 'Please login first'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
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
              content: Text('${AppLocalizations.of(context)?.failedToSwitchRole ?? 'Failed to switch role'}: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Hamburger Menu + Logo + Profile Icon (Mobile App Style)
          Row(
            children: [
              // Back Button (if showBackButton is true) or Hamburger Menu
              if (widget.showBackButton)
                IconButton(
                  onPressed: () {
                    // Use context.pop() for go_router navigation
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                Builder(
                  builder: (context) =>                   IconButton(
                    onPressed: () {
                      // Open drawer from correct side based on RTL
                      if (RTLHelper.isRTL(context)) {
                        Scaffold.of(context).openEndDrawer();
                      } else {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                    icon: Icon(
                      Icons.menu,
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Logo (Iraq Bid text + icon)
              GestureDetector(
                onTap: () {
                  context.go('/home');
                },
                child: Row(
                  children: [
                      Image.asset(
                        'assets/images/iraq_bid_header_logo.png',
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Notification Bell
              Stack(
                children: [
                  IconButton(
                    onPressed: () async {
                      await context.push('/notifications');
                      // Reload count after returning from notifications screen
                      _loadUnreadNotificationCount();
                    },
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadNotificationCount > 9 ? '9+' : _unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              
              // Add Product button (only for sellers)
              if (_currentRole == 'seller_products') ...[
                // Stats/Management Icon
                IconButton(
                  onPressed: () {
                    if (widget.onSellerStatsPressed != null) {
                      widget.onSellerStatsPressed!();
                    } else {
                      // Fallback if callback not provided
                      if (kDebugMode) print('Stats pressed but no callback provided');
                    }
                  },
                  icon: Icon(
                    Icons.analytics_outlined,
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  tooltip: 'Dashboard Stats',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),

                IconButton(
                  onPressed: () {
                    context.push('/product-create');
                  },
                  icon: Icon(
                    Icons.add_rounded,
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  tooltip: 'Add Product',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
              

              
              // Profile icon
              IconButton(
                onPressed: () {
                  context.push('/profile');
                },
                icon: Icon(
                  Icons.person_outline,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          // Role Buttons Row (above Search Box)
          if (!_isLoadingRole) ...[
            const SizedBox(height: 12),
            _RoleButtons(
              currentRole: _currentRole,
              isSwitching: _isSwitchingRole,
              onRoleSelected: _switchRole,
            ),
          ],
          
          // Bottom Row: Search Box
          const SizedBox(height: 12),
          _SearchBox(
            controller: widget.searchController,
            onSearchSubmitted: widget.onSearchSubmitted,
          ),
        ],
      ),
    );
  }
}

// Role Buttons Widget
class _RoleButtons extends StatelessWidget {
  final String? currentRole;
  final bool isSwitching;
  final Function(String) onRoleSelected;

  const _RoleButtons({
    required this.currentRole,
    required this.isSwitching,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final isCompanyActive = currentRole == 'company_products';
    final isSellerActive = currentRole == 'seller_products';
    
    return Row(
      children: [
        // Company Product Button
        Expanded(
          child: _RoleButton(
            label: AppLocalizations.of(context)?.companyProducts ?? 'Company Product',
            isActive: isCompanyActive,
            isLoading: isSwitching && !isCompanyActive,
            onTap: () => onRoleSelected('company_products'),
          ),
        ),
        const SizedBox(width: 12),
        // Seller Product Button
        Expanded(
          child: _RoleButton(
            label: AppLocalizations.of(context)?.sellerProducts ?? 'Seller Product',
            isActive: isSellerActive,
            isLoading: isSwitching && !isSellerActive,
            onTap: () => onRoleSelected('seller_products'),
          ),
        ),
      ],
    );
  }
}

// Individual Role Button
class _RoleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : (isDark
                  ? colorScheme.surfaceVariant
                  : colorScheme.surface.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}

// Search Box Widget
class _SearchBox extends StatefulWidget {
  final TextEditingController? controller;
  final VoidCallback? onSearchSubmitted;

  const _SearchBox({
    this.controller,
    this.onSearchSubmitted,
  });

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FocusNode _focusNode = FocusNode();
  int _currentHintIndex = 0;
  bool _isDisposed = false;
  
  List<String> _getHints(BuildContext context) {
    return [
      AppLocalizations.of(context)?.searchHereProduct ?? 'Search here product',
      AppLocalizations.of(context)?.searchOutCategory ?? 'Search out category',
    ];
  }
  
  List<String> get _hints => _getHints(context);

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTextChanged);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Fade animation for smooth transition
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start with visible hint
    _animationController.forward();
    
    // Start hint rotation
    _startHintRotation();
  }

  void _startHintRotation() {
    if (_isDisposed) return;
    
    // Change hint every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      if (mounted && (widget.controller?.text.isEmpty ?? true) && !_focusNode.hasFocus) {
        // Fade out
        _animationController.reverse().then((_) {
          if (mounted && !_isDisposed) {
            setState(() {
              _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
            });
            // Fade in
            _animationController.forward();
          }
        });
        // Schedule next change
        _startHintRotation();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.controller?.removeListener(_onTextChanged);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isDisposed) return;
    setState(() {});
    // Stop animation when user types
    if (widget.controller?.text.isNotEmpty ?? false) {
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44, // Increased height for better tap area
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Hint overlay (Bottom of stack)
            if (!hasText)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: RTLHelper.only(context, left: 44, right: 44),
                    child: Align(
                      alignment: RTLHelper.isRTL(context) ? Alignment.centerRight : Alignment.centerLeft,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          _hints[_currentHintIndex],
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
            // 2. TextField (Top of stack to ensure hits)
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary.withOpacity(0.7),
                  size: 22,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          widget.controller?.clear();
                          widget.onSearchSubmitted?.call();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
              onSubmitted: (value) {
                widget.onSearchSubmitted?.call();
              },
              onTap: () {
                _animationController.stop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

