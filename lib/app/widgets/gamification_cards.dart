import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

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
  int _spinsLeft = 3;
  String? _referralLink;
  String? _referralToken;

  // 6 Slices matching reference screenshot media_1795093784725_4e69f3e1.jpg
  final List<Map<String, dynamic>> _prizes = [
    {'title_en': '10% Coupon', 'title_ar': 'كوبون 10%', 'color': Color(0xFFDC2626)},
    {'title_en': '\$0.50', 'title_ar': '0.50 \$', 'color': Color(0xFFFEF3C7)},
    {'title_en': '\$0.75', 'title_ar': '0.75 \$', 'color': Color(0xFFDC2626)},
    {'title_en': '\$1.00', 'title_ar': '1.00 \$', 'color': Color(0xFFFEF3C7)},
    {'title_en': '\$1.50', 'title_ar': '1.50 \$', 'color': Color(0xFFDC2626)},
    {'title_en': '15% Coupon', 'title_ar': 'كوبون 15%', 'color': Color(0xFFFEF3C7)},
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _loadWheelStatus();
  }

  Future<void> _loadWheelStatus() async {
    try {
      final res = await apiService.getLuckyWheelStatus();
      if (res['success'] == true && res['data'] != null) {
        if (mounted) {
          setState(() {
            _spinsLeft = res['data']['spins_left'] ?? 3;
            _referralLink = res['data']['referral_link'];
            _referralToken = res['data']['referral_token'];
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _shareReferralLink() {
    final link = _referralLink ?? 'https://admin.iraqbid.net/join?ref=${_referralToken ?? "WHEEL"}&source=wheel';
    final msg = widget.isArabic
        ? 'دوّر عجلة الحظ اليومية واربح رصيد مزايدة وجوائز حصرية مجاناً!\nانضم عبر الرابط:\n$link'
        : 'Spin the Daily Lucky Wheel for free bid credits & exclusive rewards!\nJoin here: $link';
    Share.share(msg, subject: 'Iraq Bid - Daily Lucky Wheel');
  }

  void _showInviteMoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.isArabic ? 'انتهت المحاولات!' : 'No Spins Left!'),
        content: Text(
          widget.isArabic
              ? 'قم بدعوة أصدقائك للحصول على دورات إضافية مجانية في عجلة الحظ!'
              : 'Invite friends using your personal referral link to unlock more free spins!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _shareReferralLink();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(widget.isArabic ? 'دعوة الآن' : 'Invite Friends', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _spinTheWheel() async {
    if (_isSpinning) return;
    if (_spinsLeft <= 0) {
      _showInviteMoreDialog();
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _isSpinning = true;
    });

    try {
      final spinRes = await apiService.spinLuckyWheel();
      final winningLabel = spinRes['prize']?['label'] ?? '\$0.50';
      int winningIndex = _prizes.indexWhere((p) => p['title_en'] == winningLabel);
      if (winningIndex == -1) winningIndex = 1;

      final sliceAngle = (2 * math.pi) / _prizes.length;
      final extraRotations = 5 * 2 * math.pi;
      final targetAngle = extraRotations + (winningIndex * sliceAngle) + (sliceAngle / 2);

      _spinAnimation = Tween<double>(
        begin: _currentRotation,
        end: _currentRotation + targetAngle,
      ).animate(
        CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
      );

      _spinAnimation.addListener(() {
        if (mounted) setState(() {});
      });

      _spinAnimation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _currentRotation = _spinAnimation.value % (2 * math.pi);
          _isSpinning = false;
          _spinsLeft = math.max(0, _spinsLeft - 1);
          final prize = widget.isArabic
              ? _prizes[winningIndex]['title_ar']
              : _prizes[winningIndex]['title_en'];

          HapticFeedback.vibrate();
          _showCelebrationDialog(prize);
        }
      });

      _spinController.forward(from: 0.0);
    } catch (e) {
      if (mounted) {
        setState(() => _isSpinning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
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
                  ? 'لقد ربحت: $prize\nتمت إضافة الجائزة إلى رصيدك بنجاح!'
                  : 'You won: $prize\nYour reward has been credited to your account!',
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
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    isAr ? 'عجلة الحظ اليومية' : 'Daily Lucky Wheel',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ],
          ),

          // Subtitle banner
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Text(
              isAr
                  ? 'دوّر العجلة يومياً للحصول على رصيد مزايدة وجوائز حصرية مجاناً!'
                  : 'Spin the wheel daily for free bid credits & exclusive rewards!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFC2410C), fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 12),

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

              // Center Golden Peg / Gavel Indicator
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
                  child: Icon(Icons.gavel_rounded, color: Colors.white, size: 22),
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

          const SizedBox(height: 18),

          // Status Row: Your Spins + Get More Spins
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Left: Your Spins
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.casino_rounded, color: Color(0xFFEA580C), size: 22),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'دوراتك' : 'Your Spins',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '$_spinsLeft',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(width: 1, height: 32, color: const Color(0xFFCBD5E1)),

                // Right: Get More Spins (Clickable)
                Expanded(
                  child: InkWell(
                    onTap: _shareReferralLink,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFEA580C), size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'احصل على دورات' : 'Get More Spins',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                              ),
                              Text(
                                isAr ? 'دعوة أصدقاء' : 'Invite Friends',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isSpinning) const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    if (!_isSpinning) const SizedBox(width: 6),
                    Text(
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
                  ],
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
// DAILY CHALLENGE MODAL (100% REPLICATING REFERENCE SCREENSHOT)
// ============================================================================
class DailyChallengeInteractiveModal extends StatefulWidget {
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
  State<DailyChallengeInteractiveModal> createState() => _DailyChallengeInteractiveModalState();
}

class _DailyChallengeInteractiveModalState extends State<DailyChallengeInteractiveModal> {
  int _myInvitations = 0;
  int _timeLeftSeconds = 45380;
  String? _referralLink;
  String? _referralToken;
  List<Map<String, dynamic>> _topParticipants = [];
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadChallengeData();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        if (mounted) {
          setState(() {
            _timeLeftSeconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadChallengeData() async {
    try {
      final res = await apiService.getDailyChallenge();
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        if (mounted) {
          setState(() {
            _myInvitations = data['my_invitations'] ?? 0;
            _timeLeftSeconds = data['time_left_seconds'] ?? 45380;
            _referralLink = data['referral_link'];
            _referralToken = data['referral_token'];
            _topParticipants = ((data['top_participants'] as List?) ?? [])
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  String _formatHours() => (_timeLeftSeconds ~/ 3600).toString().padLeft(2, '0');
  String _formatMinutes() => ((_timeLeftSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  String _formatSeconds() => (_timeLeftSeconds % 60).toString().padLeft(2, '0');

  void _shareDailyChallengeLink() {
    final link = _referralLink ?? 'https://admin.iraqbid.net/join?ref=${_referralToken ?? "CHALLENGE"}&source=challenge';
    final msg = widget.isArabic
        ? 'شارك في التحدي اليومي على تطبيق IRAQ BID واربح هاتف ذكي ورصيد 500\$!\nانضم الآن عبر الرابط الخاص:\n$link'
        : 'Join the Daily Challenge on IRAQ BID to win a Smartphone + 500 Credits today!\nJoin via personal link:\n$link';
    Share.share(msg, subject: 'IRAQ BID - Daily Challenge');
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

          const SizedBox(height: 14),

          // Header: Laurel + Trophy + Title + Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    isAr ? 'التحدي اليومي' : 'Daily Challenge',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🌿', style: TextStyle(fontSize: 18)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ],
          ),

          // Orange Ribbon Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              isAr
                  ? 'المستخدم الأكثر دعوة للأصدقاء يفوز بجائزة اليوم!'
                  : 'The user with the highest number of invitations wins today\'s prize!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Hero Prize Card (Purple Banner with 3D Smartphone & Gift)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6B21A8), Color(0xFF7C3AED), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFDE047), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'جائزة اليوم' : "Today's Prize",
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr ? 'هاتف ذكي\n+ 500 رصيد' : 'Smartphone\n+ 500 Credits',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/images/daily_challenge_3d.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Time Left Countdown Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF7C3AED), size: 20),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'الوقت المتبقي' : 'Time Left',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 12),

                // HHh : MMm : SSs blocks
                _buildTimeBadge('${_formatHours()}h'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7C3AED))),
                ),
                _buildTimeBadge('${_formatMinutes()}m'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7C3AED))),
                ),
                _buildTimeBadge('${_formatSeconds()}s'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // My Invitations & Invite Friends Row
          Row(
            children: [
              // Left: My Invitations Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Color(0xFF7C3AED), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'دعواتي' : 'My Invitations',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '$_myInvitations',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Right: Invite Friends Button
              GestureDetector(
                onTap: _shareDailyChallengeLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFF97316)],
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
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'دعوة الأصدقاء' : 'Invite Friends',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Leaderboard Section: Top 5 Participants
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 6),
              Text(
                isAr ? 'أفضل 5 مشاركين' : 'Top 5 Participants',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Top 5 List
          ...(_topParticipants.isNotEmpty
              ? _topParticipants.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return _buildLeaderboardRow(
                    rank: idx + 1,
                    name: item['name']?.toString() ?? 'User',
                    invitations: item['invitations'] ?? 0,
                    isArabic: isAr,
                  );
                }).toList()
              : [
                  _buildLeaderboardRow(rank: 1, name: 'Ali Ahmed', invitations: 356, isArabic: isAr),
                  _buildLeaderboardRow(rank: 2, name: 'Mustafa Kareem', invitations: 289, isArabic: isAr),
                  _buildLeaderboardRow(rank: 3, name: 'Hassan Saleh', invitations: 241, isArabic: isAr),
                  _buildLeaderboardRow(rank: 4, name: 'Omar Abdulrahman', invitations: 198, isArabic: isAr),
                  _buildLeaderboardRow(rank: 5, name: 'Zaid Mohammed', invitations: 176, isArabic: isAr),
                ]),

          const SizedBox(height: 14),

          // Bottom Info Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412), height: 1.4),
                      children: [
                        TextSpan(
                          text: isAr ? 'ملاحظة: ' : 'Note: ',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: isAr
                              ? 'تُحتسب الدعوة فقط عندما يقوم الشخص المدعو بتحميل التطبيق وإنشاء حساب وتأكيد رقم الهاتف بالرمز.'
                              : 'An invitation is only accepted when the invited person downloads the app and creates an account.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required int rank,
    required String name,
    required int invitations,
    required bool isArabic,
  }) {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = const Color(0xFFF59E0B);
    } else if (rank == 2) {
      badgeColor = const Color(0xFF94A3B8);
    } else if (rank == 3) {
      badgeColor = const Color(0xFFD97706);
    } else {
      badgeColor = const Color(0xFFCBD5E1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // User Avatar Icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),

          // User Name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          // Invitations Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic ? '$invitations دعوة' : '$invitations Invitations',
              style: const TextStyle(
                color: Color(0xFF6D28D9),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
