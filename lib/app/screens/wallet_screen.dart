import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  String? _errorMessage;

  static const int usdToIqdRate = 1520;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        context.go('/auth');
      }
      return;
    }

    try {
      final response = await apiService.getWallet();
      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _walletData = response['data'] as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] as String? ?? 'Failed to load wallet';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _showDepositModal(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.headset_mic_rounded,
                  size: 42,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isArabic ? 'التواصل مع قسم الحسابات' : 'Contact the Accounts Department',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isArabic
                    ? 'لشحن رصيدك أو إيداع الأموال في محفظتك، يرجى التواصل مباشرة مع قسم الحسابات عبر الواتساب.'
                    : 'To deposit funds or top up your wallet, please contact the Accounts Department via WhatsApp.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  Navigator.of(ctx).pop();
                  String number = '+9647700000000';
                  try {
                    final res = await apiService.getPublicSettings();
                    if (res['data']?['accounts_whatsapp_number'] != null) {
                      number = res['data']['accounts_whatsapp_number'].toString();
                    }
                  } catch (_) {}
                  final cleanNum = number.replaceAll(RegExp(r'[^\d]'), '');
                  final waUri = Uri.parse('https://wa.me/$cleanNum?text=${Uri.encodeComponent(isArabic ? "مرحباً قسم الحسابات، أريد شحن رصيد محفظتي في مزاد العراق" : "Hello Accounts Dept, I want to deposit funds into my Iraq Bid wallet.")}');
                  if (await canLaunchUrl(waUri)) {
                    await launchUrl(waUri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                label: Text(
                  isArabic ? 'تواصل عبر واتساب' : 'Contact via WhatsApp',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
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
                isArabic ? 'المحفظة الذكية' : 'Digital Wallet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF0F172A), size: 22),
                  onPressed: _loadWalletData,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(isArabic),
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isArabic) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0066FF),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 52, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWalletData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isArabic ? 'إعادة المحاولة' : 'Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final balance = _safeToDouble(_walletData?['balance'] ?? 0);
    final totalEarned = _safeToDouble(_walletData?['total_earned'] ?? 0);
    final totalSpent = _safeToDouble(_walletData?['total_spent'] ?? 0);
    final transactions = (_walletData?['transactions'] as List?) ?? [];

    final iqdBalance = (balance * usdToIqdRate).toInt();
    final formattedIqd = iqdBalance.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return RefreshIndicator(
      color: const Color(0xFF0066FF),
      onRefresh: _loadWalletData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Luxury Black-Card Balance Card
            Container(
              width: double.infinity,
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
                    color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'الرصيد الكلي المتوفر' : 'TOTAL AVAILABLE BALANCE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'IRAQ BID PAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF38BDF8),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFFFFF),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '≈ $formattedIqd IQD',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showDepositModal(context, isArabic);
                            },
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
                                const Icon(Icons.add_circle_outline_rounded,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic ? 'شحن الرصيد' : 'Deposit',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isArabic
                                      ? 'السحب متاح عبر المحافظ المحلية (زين كاش / قيد البرمجة)'
                                      : 'Withdrawal via ZainCash coming soon'),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF475569), width: 1.5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_outward_rounded,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic ? 'سحب الأرباح' : 'Withdraw',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // In & Out Statistics
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_downward_rounded,
                                  size: 14, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? 'إجمالي الأرباح' : 'Total Inflow',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${totalEarned.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward_rounded,
                                  size: 14, color: Color(0xFFEF4444)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? 'المصروف بالمزايدات' : 'Total Spent',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${totalSpent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'سجل العمليات المالية' : 'Transaction History',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${transactions.length} ${isArabic ? 'عملية' : 'items'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          size: 38, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 10),
                      Text(
                        isArabic
                            ? 'لا توجد عمليات سابقة مسجلة'
                            : 'No transaction history recorded yet',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  final amount = _safeToDouble(t['amount'] ?? 0);
                  final isPositive = (t['type'] == 'deposit' ||
                      t['type'] == 'referral' ||
                      amount > 0);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isPositive
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              child: Icon(
                                isPositive
                                    ? Icons.add_rounded
                                    : Icons.remove_rounded,
                                color: isPositive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['description'] ?? (isArabic ? 'عملية مالية' : 'Transaction'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t['created_at'] != null
                                      ? t['created_at'].toString().substring(0, 10)
                                      : 'Recent',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${isPositive ? '+' : '-'}\$${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isPositive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
