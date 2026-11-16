import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/language_service.dart';

class GamificationCardsWidget extends StatefulWidget {
  final bool isArabic;
  const GamificationCardsWidget({super.key, required this.isArabic});

  @override
  State<GamificationCardsWidget> createState() => _GamificationCardsWidgetState();
}

class _GamificationCardsWidgetState extends State<GamificationCardsWidget>
    with TickerProviderStateMixin {
  late AnimationController _wheelAnimController;
  late Animation<double> _wheelRockAnim;

  late AnimationController _floatAnimController;
  late Animation<double> _floatAnim;

  late AnimationController _pulseGlowController;
  late Animation<double> _pulseGlowAnim;

  // Tap scale bounce states
  double _wheelScale = 1.0;
  double _challengeScale = 1.0;

  @override
  void initState() {
    super.initState();

    // 1. Wheel gentle 3D rocking animation
    _wheelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _wheelRockAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _wheelAnimController, curve: Curves.easeInOutSine),
    );

    // 2. Phone floating in zero-gravity animation
    _floatAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatAnimController, curve: Curves.easeInOutQuad),
    );

    // 3. Ambient glow pulse animation
    _pulseGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseGlowAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _wheelAnimController.dispose();
    _floatAnimController.dispose();
    _pulseGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ==========================================
          // 1. LUCKY WHEEL CARD (100% Match Reference)
          // ==========================================
          Expanded(
            child: AnimatedScale(
              scale: _wheelScale,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutQuad,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _wheelScale = 0.96),
                onTapUp: (_) => setState(() => _wheelScale = 1.0),
                onTapCancel: () => setState(() => _wheelScale = 1.0),
                onTap: () {
                  HapticFeedback.lightImpact();
                  LuckyWheelInteractiveModal.show(context, isAr);
                },
                child: Container(
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Subtle warm ambient radial glow behind wheel
                      Positioned(
                        left: isAr ? null : 4,
                        right: isAr ? 4 : null,
                        top: 14,
                        child: AnimatedBuilder(
                          animation: _pulseGlowAnim,
                          builder: (context, _) => Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFDBA74).withOpacity(0.35 * _pulseGlowAnim.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            // 3D Lucky Wheel Graphic (with gentle rocking/floating animation)
                            AnimatedBuilder(
                              animation: _wheelRockAnim,
                              builder: (context, child) => Transform.rotate(
                                angle: _wheelRockAnim.value,
                                child: child,
                              ),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: Image.asset(
                                  'assets/images/lucky_wheel_3d.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _buildFallbackWheelVisual(),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Texts & Spin Now Button
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Crown Icon + Title
                                  Row(
                                    children: [
                                      Text(
                                        isAr ? 'عجلة الحظ' : 'Lucky Wheel',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF431407),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Text('👑', style: TextStyle(fontSize: 11)),
                                    ],
                                  ),

                                  const SizedBox(height: 2),

                                  // Subtitle
                                  Text(
                                    isAr ? 'دوّر يومياً واربح رصيد' : 'Spin Daily & Win\nBid Credit',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9A3412),
                                      height: 1.15,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  // "SPIN NOW >" Button
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEA580C).withOpacity(0.35),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isAr ? 'العب الآن' : 'SPIN NOW',
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                                          size: 11,
                                          color: Colors.white,
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ==========================================
          // 2. DAILY CHALLENGE CARD (100% Match Reference)
          // ==========================================
          Expanded(
            child: AnimatedScale(
              scale: _challengeScale,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutQuad,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _challengeScale = 0.96),
                onTapUp: (_) => setState(() => _challengeScale = 1.0),
                onTapCancel: () => setState(() => _challengeScale = 1.0),
                onTap: () {
                  HapticFeedback.lightImpact();
                  DailyChallengeInteractiveModal.show(context, isAr);
                },
                child: Container(
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE9D5FF), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Subtle lavender ambient radial glow behind phone
                      Positioned(
                        left: isAr ? null : 4,
                        right: isAr ? 4 : null,
                        top: 14,
                        child: AnimatedBuilder(
                          animation: _pulseGlowAnim,
                          builder: (context, _) => Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFD8B4FE).withOpacity(0.35 * _pulseGlowAnim.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            // 3D Lavender Phone with Golden Ribbon (Floating zero-gravity animation)
                            AnimatedBuilder(
                              animation: _floatAnim,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _floatAnim.value),
                                child: child,
                              ),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: Image.asset(
                                  'assets/images/daily_challenge_3d.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _buildFallbackPhoneVisual(),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Texts & Join Now Button
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Title
                                  Text(
                                    isAr ? 'التحدي اليومي' : 'Daily\nChallenge',
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2E1065),
                                      letterSpacing: -0.2,
                                      height: 1.05,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  // Subtitle
                                  Text(
                                    isAr ? 'ادعُ أصدقاءك واربح' : 'Invite Friends\n& Win Prizes',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6D28D9),
                                      height: 1.15,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  // "JOIN NOW >" Button
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED).withOpacity(0.35),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isAr ? 'انضم الآن' : 'JOIN NOW',
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                                          size: 11,
                                          color: Colors.white,
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

                      // Top-Right Floating "Daily Prize" Pill Badge (Matches Screenshot)
                      Positioned(
                        top: 6,
                        right: isAr ? null : 6,
                        left: isAr ? 6 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wallet_giftcard_rounded, size: 8, color: Colors.white),
                              const SizedBox(width: 2.5),
                              Text(
                                isAr ? 'جائزة يومية' : 'Daily Prize',
                                style: const TextStyle(
                                  fontSize: 7.0,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackWheelVisual() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFFEF4444),
            Color(0xFFFFFBEB),
            Color(0xFFEF4444),
            Color(0xFFFFFBEB),
            Color(0xFFEF4444),
            Color(0xFFFFFBEB),
            Color(0xFFEF4444),
          ],
        ),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
      ),
      child: const Center(
        child: Icon(Icons.casino_rounded, color: Color(0xFFD97706), size: 20),
      ),
    );
  }

  Widget _buildFallbackPhoneVisual() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFC084FC), Color(0xFF7C3AED)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

// ============================================================================
// INTERACTIVE LUCKY WHEEL MODAL (AUTHENTIC SPIN PHYSICS & PRIZES)
// ============================================================================
class LuckyWheelInteractiveModal extends StatefulWidget {
  final bool isArabic;
  const LuckyWheelInteractiveModal({super.key, required this.isArabic});

  static void show(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LuckyWheelInteractiveModal(isArabic: isArabic),
    );
  }

  @override
  State<LuckyWheelInteractiveModal> createState() => _LuckyWheelInteractiveModalState();
}

class _LuckyWheelInteractiveModalState extends State<LuckyWheelInteractiveModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  double _currentRotation = 0.0;
  bool _isSpinning = false;
  String? _wonPrize;

  final List<Map<String, dynamic>> _prizes = [
    {'title_en': '+5 Bid Credits', 'title_ar': '+5 رصيد مزايدة', 'color': Color(0xFFEA580C)},
    {'title_en': 'Free Shipping', 'title_ar': 'شحن مجاني', 'color': Color(0xFFF59E0B)},
    {'title_en': '+15 Bid Credits', 'title_ar': '+15 رصيد مزايدة', 'color': Color(0xFFEF4444)},
    {'title_en': '20% Discount', 'title_ar': 'خصم 20%', 'color': Color(0xFF8B5CF6)},
    {'title_en': '+50 Bid Credits', 'title_ar': '+50 رصيد مزايدة', 'color': Color(0xFF10B981)},
    {'title_en': 'Mystery Box', 'title_ar': 'صندوق المفاجآت', 'color': Color(0xFF3B82F6)},
    {'title_en': '+10 Bid Credits', 'title_ar': '+10 رصيد مزايدة', 'color': Color(0xFFD97706)},
    {'title_en': 'Mega Jackpot', 'title_ar': 'الجائزة الكبرى', 'color': Color(0xFFEC4899)},
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinTheWheel() {
    if (_isSpinning) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isSpinning = true;
      _wonPrize = null;
    });

    final random = math.Random();
    final winningIndex = random.nextInt(_prizes.length);
    final sliceAngle = (2 * math.pi) / _prizes.length;

    // Spin at least 5 full rotations + landing slice
    final extraRotations = 5 * 2 * math.pi;
    final targetAngle = extraRotations + (winningIndex * sliceAngle) + (sliceAngle / 2);

    _spinAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + targetAngle,
    ).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    _spinAnimation.addListener(() {
      setState(() {});
    });

    _spinAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentRotation = _spinAnimation.value % (2 * math.pi);
        _isSpinning = false;
        final prize = widget.isArabic
            ? _prizes[winningIndex]['title_ar']
            : _prizes[winningIndex]['title_en'];

        setState(() {
          _wonPrize = prize;
        });

        HapticFeedback.vibrate();
        _showCelebrationDialog(prize);
      }
    });

    _spinController.forward(from: 0.0);
  }

  void _showCelebrationDialog(String prize) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              widget.isArabic ? 'مبروك الفوز!' : 'Congratulations!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isArabic
                  ? 'لقد ربحت: $prize\nتمت إضافة الجائزة إلى محفظتك بنجاح!'
                  : 'You won: $prize\nYour reward has been credited to your balance!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.isArabic ? 'استلام الجائزة' : 'Claim Reward',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
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
    final isAr = widget.isArabic;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'عجلة الحظ اليومية' : 'Daily Lucky Wheel',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ],
          ),

          Text(
            isAr
                ? 'دوّر العجلة يومياً واحصل على رصيد مزايدة وجوائز حصرية مجاناً!'
                : 'Spin the wheel daily for free bid credits & exclusive rewards!',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 20),

          // The Interactive Wheel
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Golden Halo
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Rotating Wheel
              Transform.rotate(
                angle: _spinController.isAnimating ? _spinAnimation.value : _currentRotation,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: _WheelPainter(prizes: _prizes, isArabic: isAr),
                  ),
                ),
              ),

              // Center Golden Peg / Indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.star_rounded, color: Colors.white, size: 24),
                ),
              ),

              // Top Indicator Arrow pointing down
              Positioned(
                top: 0,
                child: CustomPaint(
                  size: const Size(20, 24),
                  painter: _ArrowPainter(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Spin Now Action Button
          GestureDetector(
            onTap: _isSpinning ? null : _spinTheWheel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSpinning
                      ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                      : [const Color(0xFFEA580C), const Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _isSpinning
                      ? (isAr ? 'العجلة تدور الآن...' : 'Spinning...')
                      : (isAr ? 'دوّر العجلة الآن (مجاناً)' : 'SPIN THE WHEEL (FREE)'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;
  final bool isArabic;

  _WheelPainter({required this.prizes, required this.isArabic});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * math.pi) / prizes.length;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < prizes.length; i++) {
      paint.color = i % 2 == 0 ? const Color(0xFFDC2626) : const Color(0xFFFEF3C7);
      final startAngle = i * sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Gold divider line
      final linePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 2.0;

      final endX = center.dx + radius * math.cos(startAngle);
      final endY = center.dy + radius * math.sin(startAngle);
      canvas.drawLine(center, Offset(endX, endY), linePaint);

      // Text label inside slice
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sweepAngle / 2);

      final label = isArabic ? prizes[i]['title_ar'] : prizes[i]['title_en'];
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: i % 2 == 0 ? Colors.white : const Color(0xFF78350F),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius * 0.45, -textPainter.height / 2));
      canvas.restore();
    }

    // Outer gold border ring
    final borderPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, radius - 3, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// INTERACTIVE DAILY CHALLENGE MODAL (QUEST BOARD & REWARDS)
// ============================================================================
class DailyChallengeInteractiveModal extends StatelessWidget {
  final bool isArabic;
  const DailyChallengeInteractiveModal({super.key, required this.isArabic});

  static void show(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DailyChallengeInteractiveModal(isArabic: isArabic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = isArabic;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.wallet_giftcard_rounded, color: Color(0xFF7C3AED), size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'التحدي اليومي والجوائز' : 'Daily Challenges & Prizes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ],
          ),

          // Grand Prize Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Image.asset(
                    'assets/images/daily_challenge_3d.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'جائزة اليوم: هاتف ذكي ورصيد مجاني!' : "Today's Prize: Smartphone & 500 Credits!",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr ? 'أكمل المهام اليومية لتدخل السحب الأسبوعي تلقائياً' : 'Complete today quests to enter the grand giveaway automatically',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quest 1: Daily Check-in
          _buildQuestItem(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            title: isAr ? 'تسجيل الدخول اليومي' : 'Daily Check-in',
            reward: '+2 Credits',
            buttonLabel: isAr ? 'تم الاستلام' : 'Claimed',
            isDone: true,
            onTap: () {},
          ),

          const SizedBox(height: 10),

          // Quest 2: Invite Friends
          _buildQuestItem(
            icon: Icons.person_add_rounded,
            color: const Color(0xFF7C3AED),
            title: isAr ? 'دعوة صديق جديد' : 'Invite a Friend',
            reward: '+15 Credits',
            buttonLabel: isAr ? 'مشاركة الرابط' : 'Share Link',
            isDone: false,
            onTap: () {
              Share.share(
                'Join Iraq Bid now and get 50 free credits for live auctions! https://iraqbid.net',
                subject: 'Iraq Bid Live Auctions',
              );
            },
          ),

          const SizedBox(height: 10),

          // Quest 3: Place a Bid
          _buildQuestItem(
            icon: Icons.gavel_rounded,
            color: const Color(0xFFEA580C),
            title: isAr ? 'المشاركة في مزاد حي' : 'Place 1 Auction Bid',
            reward: '+10 Credits',
            buttonLabel: isAr ? 'المزايدة الآن' : 'Bid Now',
            isDone: false,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildQuestItem({
    required IconData icon,
    required Color color,
    required String title,
    required String reward,
    required String buttonLabel,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  reward,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFE2E8F0) : color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDone ? const Color(0xFF64748B) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
