import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  String? _selectedRole = 'company_products';
  bool _isNavigating = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue(bool isSignupMode) async {
    if (_selectedRole == null || _isNavigating) return;

    if (isSignupMode) {
      if (mounted) {
        context.push('/signup?role=$_selectedRole');
      }
      return;
    }

    final isLoggedIn = await StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();

    if (!isLoggedIn || accessToken == null) {
      if (mounted) {
        context.go('/auth');
      }
      return;
    }

    setState(() => _isNavigating = true);

    try {
      final currentStoredRole = await StorageService.getUserRole();
      if (currentStoredRole == _selectedRole) {
        if (mounted) {
          if (_selectedRole == 'company_products') {
            context.go('/home');
          } else {
            context.go('/seller-dashboard');
          }
        }
        return;
      }

      var userId = await StorageService.getUserId();
      var phone = await StorageService.getUserPhone();

      if (userId == null || phone == null) {
        try {
          final profile = await apiService.getProfile();
          userId = profile.id;
          phone = profile.phone;
          await StorageService.saveUserData(
            userId: profile.id,
            role: profile.role,
            phone: profile.phone,
            name: profile.name,
            email: profile.email,
          );
        } catch (_) {}
      }

      if (phone != null) {
        await apiService.updateProfile(
          role: _selectedRole!,
          phone: phone,
        );
        if (userId != null) {
          await StorageService.saveUserData(
            userId: userId,
            role: _selectedRole!,
            phone: phone,
          );
        }
      }

      if (mounted) {
        if (_selectedRole == 'company_products') {
          context.go('/home');
        } else {
          context.go('/seller-dashboard');
        }
      }
    } catch (_) {
      if (mounted) {
        if (_selectedRole == 'company_products') {
          context.go('/home');
        } else {
          context.go('/seller-dashboard');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final isSignupMode = uri.queryParameters['mode'] == 'signup';
    final isAr = LanguageService.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () {
                final newLang = isAr ? 'English' : 'Arabic';
                LanguageService.setLanguage(newLang);
                setState(() {});
              },
              icon: const Icon(Icons.language, size: 16, color: Color(0xFF0284C7)),
              label: Text(
                isAr ? 'English' : 'العربية',
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Top Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAr ? 'اختر نوع الحساب وتجربة التسوق' : 'SELECT YOUR EXPERIENCE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  isAr ? 'كيف ترغب في استخدام المنصة؟' : 'How would you like to explore?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'اختر بين التسوق في مزادات الشركة المباشرة أو الانضمام إلى نادي البائعين'
                      : 'Choose between exclusive Company Auctions or our upcoming VIP Seller Club',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 36),

                // Option 1: Company Products (Buyer)
                _buildRoleCard(
                  id: 'company_products',
                  icon: Icons.storefront_rounded,
                  accentColor: const Color(0xFF0284C7),
                  title: isAr ? 'مزادات الشركة الرسمية (مشتري)' : 'Company Products (Buyer)',
                  description: isAr
                      ? 'مزايدة مباشرة، منتجات أصلية 100% مع ضمان رسمي وتوصيل فوري لجميع محافظات العراق.'
                      : 'Live auctions, 100% genuine guaranteed products with official warranty and rapid Iraq delivery.',
                  badge: isAr ? 'موصى به' : 'ACTIVE',
                  badgeColor: const Color(0xFF10B981),
                  isSelected: _selectedRole == 'company_products',
                  onTap: () => setState(() => _selectedRole = 'company_products'),
                ),

                const SizedBox(height: 16),

                // Option 2: Seller Products (VIP Seller Club)
                _buildRoleCard(
                  id: 'seller_products',
                  icon: Icons.shield_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  title: isAr ? 'نادي البائعين VIP (قريباً)' : 'VIP Seller Club (Coming Soon)',
                  description: isAr
                      ? 'منظومة تجار معتمدة، بيع آمن عبر الضمان البنكي وتسهيلات شحن حصرية في العراق.'
                      : 'Verified merchant ecosystem, escrow protection and exclusive logistics across Iraq.',
                  badge: isAr ? 'قريباً' : 'COMING SOON',
                  badgeColor: const Color(0xFFF59E0B),
                  isSelected: _selectedRole == 'seller_products',
                  onTap: () => setState(() => _selectedRole = 'seller_products'),
                ),

                const Spacer(),

                // Action Continue Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isNavigating ? null : () => _handleContinue(isSignupMode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isNavigating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isAr ? 'متابعة' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String id,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String description,
    required String badge,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
