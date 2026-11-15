import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _userPhone;
  String? _referralCode;
  double _rewardBalance = 0.0;
  bool _isLoading = true;

  static const int usdToIqdRate = 1520;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await apiService.getProfile();
      final balance = await StorageService.getRewardBalance();

      if (mounted) {
        setState(() {
          _userName = user.name;
          _userPhone = user.phone;
          _referralCode = user.referralCode;
          _rewardBalance = balance;
          _isLoading = false;
        });
      }
    } catch (_) {
      final name = await StorageService.getUserName();
      final phone = await StorageService.getUserPhone();
      final ref = await StorageService.getReferralCode();
      final balance = await StorageService.getRewardBalance();

      if (mounted) {
        setState(() {
          _userName = name ?? 'VIP User';
          _userPhone = phone;
          _referralCode = ref;
          _rewardBalance = balance;
          _isLoading = false;
        });
      }
    }
  }

  void _showLanguageSelector(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'اختر لغة التطبيق' : 'Select Language',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageTile(
                  title: 'English (US)',
                  isSelected: !isArabic,
                  onTap: () {
                    LanguageService.setLanguage('English');
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 8),
                _LanguageTile(
                  title: 'العربية (العراق)',
                  isSelected: isArabic,
                  onTap: () {
                    LanguageService.setLanguage('Arabic');
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar' ||
            LanguageService.getLanguageName() == 'Arabic';

        final iqdBalance = (_rewardBalance * usdToIqdRate).toInt();
        final formattedIqd = iqdBalance.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFFFFF),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Text(
                isArabic ? 'الملف الشخصي' : 'Account & Profile',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.language_rounded,
                      color: Color(0xFF0066FF), size: 22),
                  onPressed: () => _showLanguageSelector(context, isArabic),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF0066FF),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // Avatar with Verified Badge
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEFF6FF),
                                      Color(0xFFDBEAFE),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                    width: 2.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 52,
                                    color: Color(0xFF0066FF),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          _userName ?? (isArabic ? 'مستخدم معتمد' : 'Verified Member'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),

                        if (_userPhone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _userPhone!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Reward / Wallet Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isArabic
                                        ? 'رصيد المكافآت والمحفظة'
                                        : 'VIP REWARDS & WALLET',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 22,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '\$${_rewardBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFFFFFF),
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '≈ $formattedIqd IQD',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/wallet'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        isArabic
                                            ? 'إدارة وسحب الرصيد'
                                            : 'Manage & Withdraw',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Referral Code Pill
                        if (_referralCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isArabic
                                          ? 'رمز الإحالة الخاص بك'
                                          : 'Your Referral Code',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _referralCode!,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded,
                                      color: Color(0xFF0066FF), size: 20),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _referralCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isArabic
                                            ? 'تم نسخ رمز الإحالة!'
                                            : 'Referral code copied!'),
                                        duration:
                                            const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Action Menu List
                        _buildMenuSection(isArabic),

                        const SizedBox(height: 20),

                        // Logout Luxury Pill
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  title: Text(isArabic
                                      ? 'تسجيل الخروج'
                                      : 'Confirm Logout'),
                                  content: Text(isArabic
                                      ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟'
                                      : 'Are you sure you want to sign out from your account?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(isArabic
                                          ? 'تسجيل الخروج'
                                          : 'Logout'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && mounted) {
                                await StorageService.clearAll();
                                if (mounted) {
                                  context.go('/auth');
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFFCA5A5), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded,
                                    color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'تسجيل الخروج' : 'Log Out',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFF0066FF),
            bgColor: const Color(0xFFEFF6FF),
            title: isArabic ? 'مزاداتي النشطة' : 'My Active Bids',
            onTap: () => context.push('/buyer-bidding-history'),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.share_rounded,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            title: isArabic ? 'شارك واكسب المكافآت' : 'Invite & Earn Rewards',
            onTap: () => context.push('/invite-and-earn'),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            title: isArabic ? 'لغة التطبيق' : 'Application Language',
            trailingText: isArabic ? 'العربية' : 'English',
            onTap: () => _showLanguageSelector(context, isArabic),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
            title: isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
            onTap: () => context.push('/terms-and-conditions'),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFF64748B),
            bgColor: const Color(0xFFF8FAFC),
            title: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
            onTap: () => context.push('/privacy-policy'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0066FF),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF1E293B),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF0066FF), size: 20),
          ],
        ),
      ),
    );
  }
}
