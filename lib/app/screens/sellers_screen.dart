import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class SellersScreen extends StatefulWidget {
  const SellersScreen({super.key});

  @override
  State<SellersScreen> createState() => _SellersScreenState();
}

class _SellersScreenState extends State<SellersScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, _, __) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  _isArabic ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF0F172A),
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                _t('Sellers Marketplace', 'سوق البائعين المعتمدين'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Luxury Store Icon with glowing pulse
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withOpacity(_pulseAnimation.value),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                margin: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE11D48).withOpacity(0.3),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: 46,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // Coming Soon Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.rocket_launch_rounded, size: 15, color: Color(0xFFE11D48)),
                            const SizedBox(width: 6),
                            Text(
                              _t('Coming Soon', 'قريباً جداً'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE11D48),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Big Heading
                      Text(
                        _t('Verified Sellers Hub', 'منصة البائعين والمتاجر المعتمدة'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        _t(
                          'We are bringing verified third-party merchants, certified stores, and individual sellers directly into IRAQ BID live auction ecosystem.',
                          'نحن نعمل على إطلاق قسم متكامل يتيح للمتاجر والبائعين المعتمدين عرض منتجاتهم الفاخرة بالمزاد المباشر قريباً.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Highlights feature grid
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              icon: Icons.verified_user_rounded,
                              color: const Color(0xFF0284C7),
                              title: _t('100% Certified Merchants', 'تجار ومحلات موثقة رسمياً'),
                              desc: _t('Every seller is KYC verified with legal guarantee.', 'فحص أمني وتدقيق هوية لكل تاجر معتمد.'),
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _buildFeatureRow(
                              icon: Icons.shield_rounded,
                              color: const Color(0xFF10B981),
                              title: _t('Buyer Protection Guarantee', 'ضمان المشتري الشامل'),
                              desc: _t('Funds remain in escrow until you inspect and receive items.', 'تبقى أموالك في الأمان حتى تستلم وتفحص المنتج.'),
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _buildFeatureRow(
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFFF59E0B),
                              title: _t('Fast Nationwide Shipping', 'شحن سريع لجميع محافظات العراق'),
                              desc: _t('Doorstep delivery to all 18 governorates.', 'توصيل مباشر إلى باب بيتك في كل العراق.'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Return Home Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.pop();
                          },
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          label: Text(
                            _t('Back to Auctions', 'العودة إلى المزادات'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
