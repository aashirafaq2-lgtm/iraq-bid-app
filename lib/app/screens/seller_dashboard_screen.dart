import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;

  final TextEditingController _phoneEmailController = TextEditingController();
  bool _isSubmitting = false;
  bool _isWaitlistJoined = false;
  int _waitlistSpot = 247;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneEmailController.dispose();
    super.dispose();
  }

  void _handleJoinWaitlist(bool isArabic) {
    final text = _phoneEmailController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى إدخال رقم الهاتف أو البريد الإلكتروني'
                : 'Please enter your phone number or email',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isWaitlistJoined = true;
          _waitlistSpot = 248;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar' || LanguageService.getLanguageName() == 'Arabic';
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
                    size: 20, color: Color(0xFF1E293B)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Text(
                isArabic ? 'بوابة البائعين المعتمدين' : 'Seller Partnership',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // 3D Animated Floating Shield Emblem
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Transform.scale(
                          scale: _glowAnimation.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFFFBEB),
                                  Color(0xFFFEF3C7),
                                  Color(0xFFFDE68A),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: 54,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Luxury VIP Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_clock_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isArabic
                              ? 'عضوية البائعين الحصريين — قريباً'
                              : 'VIP SELLER CLUB — COMING SOON',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Headline Title
                  Text(
                    isArabic
                        ? 'بيع مقتنياتك وممتلكاتك\nبأعلى عائد في العراق'
                        : 'Sell Your Assets with\nMaximum Profit in Iraq',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle Paragraph
                  Text(
                    isArabic
                        ? 'نحن نقوم بتطوير أحدث نظام مزايدات ذكي للبائعين المعتمدين مع بوابات دفع بنكية موثوقة وضمان تسليم كامل لجميع المحافظات.'
                        : 'We are engineering the next-generation enterprise marketplace for verified merchants, featuring instant payouts, secured escrow, and nationwide logistics.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3 Key Perks Cards
                  _buildPerkCard(
                    icon: Icons.verified_user_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                    title: isArabic
                        ? 'ضمان حماية المبيعات 100%'
                        : '100% Escrow Protection',
                    desc: isArabic
                        ? 'أموالك مضمونة قبل تسليم أي منتج للمشتري.'
                        : 'Funds locked securely before releasing item.',
                  ),

                  const SizedBox(height: 12),

                  _buildPerkCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    title: isArabic
                        ? 'مزادات تنافسية حية'
                        : 'Live Competitive Bidding',
                    desc: isArabic
                        ? 'بيع منتجاتك بأعلى سعر ممكن بفضل آلاف المزايدين يومياً.'
                        : 'Reach thousands of active bidders competing for your item.',
                  ),

                  const SizedBox(height: 12),

                  _buildPerkCard(
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFFF5F3FF),
                    title: isArabic
                        ? 'شحن واستلام من باب منزلك'
                        : 'Doorstep Courier Pickup',
                    desc: isArabic
                        ? 'مناديب الشركة يستلمون الطرد ويوصلونه للعميل بأمان.'
                        : 'Our certified couriers handle pickup and safe delivery.',
                  ),

                  const SizedBox(height: 32),

                  // Waitlist Interactive Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isWaitlistJoined
                        ? Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isArabic
                                    ? 'تم تسجيلك بنجاح في قائمة الانتظار!'
                                    : 'You Are on the VIP Waitlist!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isArabic
                                    ? 'أنت رقم #$_waitlistSpot في الأولوية. سيتواصل فريقنا معك فور إطلاق المنصة.'
                                    : 'You are #$_waitlistSpot in line. Our VIP team will contact you directly.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.military_tech_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isArabic
                                        ? 'انضم لقائمة الانتظار الحصرية'
                                        : 'Join Priority Waitlist',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isArabic
                                    ? 'احصل على عمولة 0% لأول 3 أشهر وميزات ترويجية مجانية.'
                                    : 'Get 0% seller commission for first 3 months and free featured boost.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _phoneEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: isArabic
                                      ? 'رقم الهاتف أو البريد الإلكتروني'
                                      : 'Phone number or email address',
                                  hintStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFFFF),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF2563EB), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _handleJoinWaitlist(isArabic),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: const Color(0xFFFFFFFF),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isArabic
                                                  ? 'حجز مقعد الأولوية'
                                                  : 'Reserve VIP Spot',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerkCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
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
