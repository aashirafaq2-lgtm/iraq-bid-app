import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class SellerEarningsScreen extends StatefulWidget {
  const SellerEarningsScreen({super.key});

  @override
  State<SellerEarningsScreen> createState() => _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends State<SellerEarningsScreen> {
  @override
  Widget build(BuildContext context) {
    final isAr = LanguageService.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/seller-dashboard');
            }
          },
        ),
        title: Text(
          isAr ? 'أرباح ومحفظة التاجر' : 'Seller Revenue & Earnings',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // VIP Seller Badge
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
                              isAr ? 'إجمالي الأرباح المحققة' : 'Net Disbursed Revenue',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '\$ 14,850.00',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '≈ 22,572,000 IQD',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            size: 32,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Escrow Protection Notice
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_outlined, color: Color(0xFFF59E0B), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'الأرباح المعلقة بالضمان (Escrow)' : 'Pending in Escrow Protection',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr
                                ? 'يتم تحرير المبالغ فور تأكيد استلام المشتري للمنتج بنجاح.'
                                : 'Funds release instantly upon verified delivery confirmation.',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '\$ 1,200',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF59E0B), fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                isAr ? 'آخر التحويلات المستلمة' : 'Recent Payout Transfers',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),

              _buildPayoutTile(
                title: isAr ? 'تحويل حساب بنكي - مصرف بغداد' : 'Bank Transfer - Bank of Baghdad',
                date: '14 Nov 2026',
                amount: '+\$ 3,450.00',
                isAr: isAr,
              ),
              const SizedBox(height: 10),
              _buildPayoutTile(
                title: isAr ? 'تحويل زين كاش - محفظة التاجر' : 'ZainCash Payout - Merchant ID',
                date: '10 Nov 2026',
                amount: '+\$ 1,800.00',
                isAr: isAr,
              ),
              const SizedBox(height: 10),
              _buildPayoutTile(
                title: isAr ? 'تسوية مزادات إلكترونيات مباشرة' : 'Electronics Live Batch Settlement',
                date: '02 Nov 2026',
                amount: '+\$ 5,200.00',
                isAr: isAr,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutTile({required String title, required String date, required String amount, required bool isAr}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                Text(
                  date,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
