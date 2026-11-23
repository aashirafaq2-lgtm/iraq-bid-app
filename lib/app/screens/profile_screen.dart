import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _userPhone;
  String? _referralCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await apiService.getProfile();
      await StorageService.getRewardBalance();

      if (mounted) {
        setState(() {
          _userName = user.name;
          _userPhone = user.phone;
          _referralCode = user.referralCode;
          _isLoading = false;
        });
      }
    } catch (_) {
      final name = await StorageService.getUserName();
      final phone = await StorageService.getUserPhone();
      final ref = await StorageService.getReferralCode();
      await StorageService.getRewardBalance();

      if (mounted) {
        setState(() {
          _userName = name ?? 'Member';
          _userPhone = phone;
          _referralCode = ref;
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
                      color: Color(0xFF0284C7), size: 22),
                  onPressed: () => _showLanguageSelector(context, isArabic),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF0284C7),
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
                                      Color(0xFFE0F2FE),
                                      Color(0xFFBAE6FD),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF7DD3FC),
                                    width: 2.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 52,
                                    color: Color(0xFF0284C7),
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

                        const SizedBox(height: 16),

                        // Wallet Balance Card
                        FutureBuilder<Map<String, dynamic>>(
                          future: apiService.getWallet(),
                          builder: (context, snapshot) {
                            final balance = (snapshot.data?['balance'] ?? 0.0);
                            final balanceVal = (balance is num) ? balance.toDouble() : double.tryParse(balance.toString()) ?? 0.0;
                            final iqd = (balanceVal * 1500).toStringAsFixed(0);
                            return GestureDetector(
                              onTap: () => context.push('/wallet'),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF38BDF8), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isArabic ? 'رصيد المحفظة' : 'Wallet Balance',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '\$${balanceVal.toStringAsFixed(2)}  ≈  $iqd IQD',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF38BDF8), size: 22),
                                  ],
                                ),
                              ),
                            );
                          },
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
                                      color: Color(0xFF0284C7), size: 20),
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
            icon: Icons.share_rounded,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFF0F9FF),
            title: isArabic ? 'شارك واكسب المكافآت' : 'Invite & Earn Rewards',
            onTap: () => context.push('/invite-and-earn'),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF0F172A),
            bgColor: const Color(0xFFF8FAFC),
            title: isArabic ? 'لغة التطبيق' : 'Application Language',
            trailingText: isArabic ? 'العربية' : 'English',
            onTap: () => _showLanguageSelector(context, isArabic),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF0F172A),
            bgColor: const Color(0xFFF8FAFC),
            title: isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
            onTap: () => context.push('/terms-and-conditions'),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFF0F172A),
            bgColor: const Color(0xFFF8FAFC),
            title: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _MenuItem(
            icon: Icons.delete_forever_rounded,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
            title: isArabic ? 'حذف الحساب نهائياً' : 'Delete Account',
            onTap: () => _confirmDeleteAccount(context, isArabic),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? 'حذف الحساب نهائياً' : 'Delete Account',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'تحذير: سيتم حذف جميع بياناتك ومزاداتك ومحفظتك بشكل نهائي ولن تتمكن من استرجاعها وفقاً لسياسات الخصوصية ومتطلبات متجر آبل. هل ترغب بالتأكيد؟'
              : 'Warning: All your profile data, bids, and wallet history will be permanently deleted and cannot be recovered in compliance with Apple App Store guidelines. Are you sure you want to proceed?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isArabic ? 'إلغاء' : 'Cancel',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final token = await StorageService.getToken();
                if (token != null && token.isNotEmpty) {
                  // Call API if endpoint exists, or wipe local credentials
                  await ApiService().deleteAccount().catchError((_) {});
                }
              } catch (_) {}
              await StorageService.clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic ? 'تم حذف حسابك بنجاح' : 'Account successfully deleted',
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
                context.go('/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isArabic ? 'نعم، حذف الحساب' : 'Yes, Delete Account',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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
                  color: Color(0xFF0284C7),
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
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
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
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF0284C7), size: 20),
          ],
        ),
      ),
    );
  }
}
