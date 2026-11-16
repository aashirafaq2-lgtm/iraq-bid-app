import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
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
          isAr ? 'إحصائيات وتحليلات التاجر' : 'Seller Analytics & Insights',
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
              // Top KPI Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: isAr ? 'مزادات نشطة' : 'Active Auctions',
                      value: '18',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: isAr ? 'معدل النجاح' : 'Success Rate',
                      value: '94.2%',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: isAr ? 'إجمالي المزايدات' : 'Total Bids Placed',
                      value: '3,420',
                      icon: Icons.gavel_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: isAr ? 'العملاء المشترون' : 'Unique Buyers',
                      value: '840',
                      icon: Icons.people_outline_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Weekly Volume Breakdown Card
              Text(
                isAr ? 'حجم المزايدات الأسبوعي' : 'Weekly Bidding Activity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'ذروة التفاعل' : 'Peak Activity',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+28% vs last week',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Modern Bar Visualizer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(day: 'Sat', height: 45, isPeak: false),
                        _buildBar(day: 'Sun', height: 60, isPeak: false),
                        _buildBar(day: 'Mon', height: 85, isPeak: false),
                        _buildBar(day: 'Tue', height: 110, isPeak: false),
                        _buildBar(day: 'Wed', height: 95, isPeak: false),
                        _buildBar(day: 'Thu', height: 140, isPeak: true),
                        _buildBar(day: 'Fri', height: 130, isPeak: true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Quality and Logistics Status
              Text(
                isAr ? 'تقييم التاجر وموثوقية الشحن' : 'Seller Rating & Reliability',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '4.92 / 5.0 VIP Merchant',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr ? 'بناءً على 420 مراجعة تسليم موثقة عبر العراق' : 'Based on 420 verified buyer delivery handoffs',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({required String day, required double height, required bool isPeak}) {
    final color = isPeak ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
            color: isPeak ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
