import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import 'package:share_plus/share_plus.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoggedIn = false;
  String? _userName;
  String? _userRole;
  String? _userPhone;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadLanguage();
    LanguageService.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageService.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _selectedLanguage = LanguageService.getLanguageName();
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    final userName = await StorageService.getUserName();
    final userRole = await StorageService.getUserRole();
    final userPhone = await StorageService.getUserPhone();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _userName = userName;
        _userRole = userRole;
        _userPhone = userPhone;
      });
    }
  }

  void _loadLanguage() {
    setState(() {
      _selectedLanguage = LanguageService.getLanguageName();
    });
  }

  void _selectLanguage(String language) {
    if (_selectedLanguage != language) {
      LanguageService.setLanguage(language);
      setState(() {
        _selectedLanguage = language;
      });
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _shareApp() {
    Share.share(
      'Check out IRAQ BID - Iraq\'s #1 Premium Live Auction App! Download now at https://iraqbid.net',
      subject: 'IRAQ BID App',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageService.isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(isArabic ? 0 : 24),
            bottomRight: Radius.circular(isArabic ? 0 : 24),
            topLeft: Radius.circular(isArabic ? 24 : 0),
            bottomLeft: Radius.circular(isArabic ? 24 : 0),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Luxury Header
              _buildHeader(isArabic),

              // 2. Navigation items list
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      title: isArabic ? 'الرئيسية' : 'Home',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/home');
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.gavel_rounded,
                      title: isArabic ? 'مزاداتي المباشرة' : 'My Bids',
                      badge: 'Live',
                      badgeColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/bids');
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.favorite_rounded,
                      title: isArabic ? 'قائمة المفضلة' : 'Wishlist',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/wishlist');
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.emoji_events_rounded,
                      title: isArabic ? 'المزادات الفائزة' : 'Won Auctions',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/wins');
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: isArabic ? 'المحفظة الإلكترونية' : 'Digital Wallet',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/wallet');
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.person_rounded,
                      title: isArabic ? 'الملف الشخصي' : 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/profile');
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    ),

                    // Language Quick Switch Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        isArabic ? 'اللغة / Language' : 'Language / اللغة',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLangToggleBtn(
                            label: 'العربية',
                            selected: _selectedLanguage == 'Arabic',
                            onTap: () => _selectLanguage('Arabic'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLangToggleBtn(
                            label: 'English',
                            selected: _selectedLanguage == 'English',
                            onTap: () => _selectLanguage('English'),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    ),

                    // Support & App
                    _buildNavItem(
                      icon: Icons.headset_mic_rounded,
                      title: isArabic ? 'الدعم الفني وخدمة العملاء' : 'Customer Support',
                      onTap: () {
                        Navigator.pop(context);
                        _showSupportDialog(context, isArabic);
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.share_rounded,
                      title: isArabic ? 'مشاركة التطبيق' : 'Share App',
                      onTap: () {
                        Navigator.pop(context);
                        _shareApp();
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.info_outline_rounded,
                      title: isArabic ? 'عن مزاد العراق' : 'About IRAQ BID',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog(context, isArabic);
                      },
                    ),
                  ],
                ),
              ),

              // 3. Bottom Auth Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                  ),
                ),
                child: _isLoggedIn
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await StorageService.clearAll();
                          setState(() {
                            _isLoggedIn = false;
                          });
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                        label: Text(
                          isArabic ? 'تسجيل الخروج' : 'Log Out',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: Color(0xFFFEE2E2)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/auth');
                        },
                        icon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                        label: Text(
                          isArabic ? 'تسجيل الدخول / إنشاء حساب' : 'Sign In / Register',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFF0284C7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isArabic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoggedIn ? (_userName ?? 'Valued User') : (isArabic ? 'مزاد العراق' : 'IRAQ BID'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isLoggedIn
                          ? (_userPhone ?? '+964 770 000 0000')
                          : (isArabic ? 'المنصة الأولى للمزادات الحية' : 'Live Auctions Platform'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        visualDensity: VisualDensity.compact,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF0284C7)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? const Color(0xFF0284C7)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor ?? const Color(0xFF0284C7),
                  ),
                ),
              )
            : const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLangToggleBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0284C7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'الدعم الفني المباشر' : 'Customer Support',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'فريق الدعم الفني لمزاد العراق متواجد على مدار 24 ساعة لخدمتكم والإجابة عن جميع استفساراتكم.'
                  : 'IRAQ BID Customer Care is available 24/7 to assist you with all your bids, payments and inquiries.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.phone_rounded, size: 18, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Text('+964 770 123 4567', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.email_outlined, size: 18, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Text('support@iraqbid.net', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isArabic ? 'عن مزاد العراق' : 'About IRAQ BID',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          isArabic
              ? 'تطبيق مزاد العراق هو المنصة الرسمية الرائدة في العراق وكردستان للمزادات الحية والمباشرة على المنتجات الأصلية والإلكترونيات الفاخرة بأسعار حصرية وضمانات معتمدة.'
              : 'IRAQ BID is Iraq\'s premier real-time auction marketplace for verified luxury products, electronics and consumer items with live bidding technology.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }
}
