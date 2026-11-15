import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';

class InviteAndEarnScreen extends StatefulWidget {
  const InviteAndEarnScreen({super.key});

  @override
  State<InviteAndEarnScreen> createState() => _InviteAndEarnScreenState();
}

class _InviteAndEarnScreenState extends State<InviteAndEarnScreen> with SingleTickerProviderStateMixin {
  String? _referralCode;
  double _rewardBalance = 0.0;
  List<Map<String, dynamic>> _referralHistory = [];
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadReferralData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.getReferralCode();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _referralCode = data['referral_code'];
          _rewardBalance = (data['reward_balance'] is num)
              ? (data['reward_balance'] as num).toDouble()
              : double.tryParse(data['reward_balance'].toString()) ?? 0.0;
        });

        if (_referralCode != null) {
          await StorageService.saveReferralCode(_referralCode!);
        }
        await StorageService.saveRewardBalance(_rewardBalance);
      }
    } catch (_) {
      // Ignore
    } finally {
      setState(() => _isLoading = false);
      _animController.forward();
    }

    try {
      final historyRes = await apiService.getReferralHistory(page: 1, limit: 20);
      if (historyRes['success'] == true && historyRes['data'] != null) {
        final data = historyRes['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _referralHistory = data.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (_) {}
  }

  void _copyToClipboard(String text, bool isAr) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? 'تم نسخ رمز الإحالة بنجاح' : 'Referral code copied to clipboard'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareReferralCode(bool isAr) {
    if (_referralCode == null) return;
    final text = isAr
        ? 'انضم إلي في تطبيق مزاد العراق واحصل على مكافأة حصرية عند التسجيل! استخدم كود الإحالة الخاص بي: $_referralCode\nhttps://iraqbid.net'
        : 'Join me on Iraq Bid app and claim exclusive bidding bonuses! Use my referral code: $_referralCode\nhttps://iraqbid.net';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageService.isArabic;
    final iqdReward = (_rewardBalance * 1520).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAr ? 'ادعُ واربح مكافآت' : 'Invite & Earn Rewards',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Luxury Gold / Sky Gradient Earnings Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? 'رصيد المكافآت المكتسبة' : 'Total Referral Earnings',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '\$${_rewardBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '≈ $iqdReward IQD',
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 32,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFF334155), height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAr ? 'عدد الأصدقاء المدعوين' : 'Total Friends Invited',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_referralHistory.length} ${isAr ? "مستخدم" : "users"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Referral Code Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              isAr ? 'رمز الإحالة الخاص بك' : 'YOUR UNIQUE REFERRAL CODE',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _referralCode ?? '---',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0284C7),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF0284C7), size: 22),
                                    onPressed: () {
                                      if (_referralCode != null) {
                                        _copyToClipboard(_referralCode!, isAr);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _shareReferralCode(isAr),
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: Text(
                                  isAr ? 'مشاركة الكود مع الأصدقاء' : 'Share Referral Code',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // How It Works Steps
                      Text(
                        isAr ? 'كيف يعمل برنامج الإحالة؟' : 'How It Works',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildStepTile(
                        number: '1',
                        title: isAr ? 'شارك كود الدعوة' : 'Share your invite link',
                        desc: isAr
                            ? 'أرسل كود الإحالة لأصدقائك عبر واتساب أو وسائل التواصل'
                            : 'Send your link or code to friends and family across Iraq',
                      ),
                      const SizedBox(height: 10),
                      _buildStepTile(
                        number: '2',
                        title: isAr ? 'يسجل صديقك ويدخل المزاد' : 'Friend registers & bids',
                        desc: isAr
                            ? 'بمجرد تسجيل الصديق وإجراء أول مزايدة مؤكدة'
                            : 'When they complete phone OTP signup and participate in an auction',
                      ),
                      const SizedBox(height: 10),
                      _buildStepTile(
                        number: '3',
                        title: isAr ? 'تحصلان على رصيد فوري' : 'Both earn instant cash',
                        desc: isAr
                            ? 'يتم تحويل المكافأة مباشرة لمحفظتك ويمكن استخدامها في المزايدة'
                            : 'Bonus credits land directly into your app wallet for free bids',
                      ),

                      const SizedBox(height: 28),

                      // Referral History Section
                      Text(
                        isAr ? 'سجل الإحالات الأخيرة' : 'Recent Referrals',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_referralHistory.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              isAr
                                  ? 'لم تقم بدعوة أي مستخدم بعد. ابدأ الآن واكسب الرصيد!'
                                  : 'No referrals recorded yet. Share your code to get started!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _referralHistory.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _referralHistory[index];
                            final name = item['referred_user_name'] ?? item['phone'] ?? 'User';
                            final date = item['created_at']?.toString() ?? '';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                        if (date.isNotEmpty)
                                          Text(
                                            date.split('T').first,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '+ \$5.00',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStepTile({required String number, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
