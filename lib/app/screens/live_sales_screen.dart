import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class LiveSalesScreen extends StatefulWidget {
  const LiveSalesScreen({super.key});

  @override
  State<LiveSalesScreen> createState() => _LiveSalesScreenState();
}

class _LiveSalesScreenState extends State<LiveSalesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  bool _isNotified = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageService.isArabic;

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
              context.go('/home');
            }
          },
        ),
        title: Text(
          isArabic ? 'التخفيضات الحية' : 'Live Flash Sales',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Glowing Animated Lightning Hero Card
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF416C),
                            Color(0xFFFF4B2B),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF416C).withOpacity(0.45),
                            blurRadius: _glowAnimation.value,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Coming Soon Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFFFE4E6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'قريباً جداً • ميزة حصرية' : 'COMING SOON • EXCLUSIVE FEATURE',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Title
              Text(
                isArabic
                    ? 'مزادات وتخفيضات البث المباشر'
                    : 'Real-Time Live Flash Auctions',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                isArabic
                    ? 'نعمل حالياً على إطلاق أقوى تجربة للمزادات التفاعلية السريعة بأسعار تبدأ من 1\$ وتخفيضات تصل إلى 70% مع جوائز وهدايا فورية!'
                    : 'We are preparing the ultimate interactive fast-bidding experience with crazy flash drops starting at \$1 and up to 70% discount!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 32),

              // Feature Highlights Grid / Cards
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: isArabic ? 'مزادات سريعة 60 ثانية' : '60-Second Flash Bids',
                      subtitle: isArabic
                          ? 'مزايدة فورية تنتهي خلال ثوانٍ معدودة'
                          : 'High adrenaline instant bidding rounds',
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                    _buildFeatureRow(
                      icon: Icons.local_fire_department_outlined,
                      iconColor: const Color(0xFFE11D48),
                      title: isArabic ? 'خصومات تصل إلى 70%' : 'Discounts up to 70%',
                      subtitle: isArabic
                          ? 'أجهزة ومنتجات أصلية بأقل من سعر السوق'
                          : 'Authentic brand items below wholesale rates',
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),
                    _buildFeatureRow(
                      icon: Icons.verified_user_outlined,
                      iconColor: const Color(0xFF10B981),
                      title: isArabic ? 'ضمان رسمي وتوصيل مباشر' : 'Official Warranty & Delivery',
                      subtitle: isArabic
                          ? 'فحص شامل وتوصيل لكافة محافظات العراق'
                          : 'Full verification and fast express shipping in Iraq',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Notify Me Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isNotified = !_isNotified);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isNotified
                              ? (isArabic
                                  ? 'تم تفعيل التنبيه! سنخبرك فور إطلاق الميزة'
                                  : 'Notification set! We will alert you upon launch')
                              : (isArabic
                                  ? 'تم إلغاء التنبيه'
                                  : 'Notification alert removed'),
                        ),
                        backgroundColor: const Color(0xFF0284C7),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(
                    _isNotified ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                    size: 20,
                  ),
                  label: Text(
                    _isNotified
                        ? (isArabic ? 'تم تفعيل التنبيه بنجاح' : 'Alert Activated')
                        : (isArabic ? 'أخبرني عند الإنطلاق' : 'Notify Me When Live'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNotified ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Back to Home Button
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Text(
                  isArabic ? 'العودة إلى الصفحة الرئيسية' : 'Return to Home Catalog',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
