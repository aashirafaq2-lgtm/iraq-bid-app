import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class VipLiveArenaScreen extends StatefulWidget {
  final String containerCode;
  final bool watchOnly;

  const VipLiveArenaScreen({
    super.key,
    required this.containerCode,
    this.watchOnly = false,
  });

  @override
  State<VipLiveArenaScreen> createState() => _VipLiveArenaScreenState();
}

class _VipBidderItem {
  final int number; // 1 to 40
  final String code; // 001 to 040
  final String name;
  double currentBid;
  bool isBidding;
  DateTime lastBidTime;

  _VipBidderItem({
    required this.number,
    required this.code,
    required this.name,
    this.currentBid = 840,
    this.isBidding = false,
    required this.lastBidTime,
  });
}

class _VipLiveArenaScreenState extends State<VipLiveArenaScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  double _currentBid = 860.0;
  int _viewersCount = 1428;
  int _totalBidders = 40;
  String _productTitle = 'ASUS ROG Gaming Laptop';
  String _productSpecs = 'Core i7 • 16GB RAM • 1TB SSD • 15.6"';
  Duration _timeLeft = const Duration(hours: 2, minutes: 14, seconds: 36);

  Timer? _countdownTimer;
  Timer? _simulationTimer;
  late AnimationController _glowController;
  late AnimationController _gavelController;

  // 40 VIP Bidders matching the theater seating
  late List<_VipBidderItem> _bidders;
  _VipBidderItem? _activeBiddingBidder;

  // Live Bidding History matching Screenshot 4
  final List<Map<String, dynamic>> _bidsHistory = [
    {
      'bidder': 'BID 009 (You)',
      'isVip': true,
      'amount': 860,
      'time': 'Just now',
      'isYou': true,
      'code': '009',
    },
    {
      'bidder': 'BID 006',
      'isVip': true,
      'amount': 850,
      'time': '1 min ago',
      'isYou': false,
      'code': '006',
    },
    {
      'bidder': 'BID 021',
      'isVip': true,
      'amount': 840,
      'time': '3 min ago',
      'isYou': false,
      'code': '021',
    },
  ];

  // Normalized relative coordinate mapping for the 40 cartoon humans on the 3D stadium image (4 rows)
  // X: 0.0 to 1.0 (across width), Y: relative position in the seats section
  static final List<Offset> _avatarAnchorPoints = [
    // Row 1 (Top / furthest back, 10 humans 001 - 010)
    const Offset(0.08, 0.535),
    const Offset(0.17, 0.535),
    const Offset(0.26, 0.535),
    const Offset(0.36, 0.535),
    const Offset(0.45, 0.535),
    const Offset(0.54, 0.535),
    const Offset(0.63, 0.535),
    const Offset(0.73, 0.535),
    const Offset(0.82, 0.535),
    const Offset(0.91, 0.535),

    // Row 2 (10 humans 011 - 020)
    const Offset(0.08, 0.635),
    const Offset(0.17, 0.635),
    const Offset(0.26, 0.635),
    const Offset(0.36, 0.635),
    const Offset(0.45, 0.635),
    const Offset(0.54, 0.635),
    const Offset(0.64, 0.635),
    const Offset(0.73, 0.635),
    const Offset(0.82, 0.635),
    const Offset(0.92, 0.635),

    // Row 3 (10 humans 021 - 030)
    const Offset(0.08, 0.745),
    const Offset(0.17, 0.745),
    const Offset(0.26, 0.745),
    const Offset(0.36, 0.745),
    const Offset(0.45, 0.745),
    const Offset(0.55, 0.745),
    const Offset(0.64, 0.745),
    const Offset(0.73, 0.745),
    const Offset(0.83, 0.745),
    const Offset(0.92, 0.745),

    // Row 4 (Front row, 10 humans 031 - 040)
    const Offset(0.08, 0.865),
    const Offset(0.18, 0.865),
    const Offset(0.28, 0.865),
    const Offset(0.37, 0.865),
    const Offset(0.46, 0.865),
    const Offset(0.55, 0.865),
    const Offset(0.64, 0.865),
    const Offset(0.74, 0.865),
    const Offset(0.83, 0.865),
    const Offset(0.92, 0.865),
  ];

  @override
  void initState() {
    super.initState();
    _initBidders();
    _startCountdown();
    _startLiveSimulation();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _gavelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _initBidders() {
    _bidders = List.generate(40, (index) {
      final code = (index + 1).toString().padLeft(3, '0');
      final isYou = index == 8; // BID 009 is You
      return _VipBidderItem(
        number: index + 1,
        code: code,
        name: isYou ? 'BID 009 (You)' : 'BID $code',
        currentBid: 840.0 + (index * 2),
        lastBidTime: DateTime.now().subtract(Duration(minutes: 40 - index)),
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _simulationTimer?.cancel();
    _glowController.dispose();
    _gavelController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      }
    });
  }

  // Realistic dynamic bidding loop with sound & haptic feel
  void _startLiveSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final rng = math.Random();
      final bidderIndex = rng.nextInt(40);
      if (bidderIndex == 8) return; // User is 009

      final bidder = _bidders[bidderIndex];
      final inc = [10, 20, 30][rng.nextInt(3)];
      final newAmt = _currentBid + inc;

      _animateBidder(bidder, newAmt.toInt(), isYou: false);
    });
  }

  void _animateBidder(_VipBidderItem bidder, int newAmt, {required bool isYou}) {
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    _gavelController.forward(from: 0.0);

    setState(() {
      _currentBid = newAmt.toDouble();
      bidder.currentBid = newAmt.toDouble();
      bidder.isBidding = true;
      bidder.lastBidTime = DateTime.now();
      _activeBiddingBidder = bidder;

      _bidsHistory.insert(0, {
        'bidder': bidder.name,
        'isVip': true,
        'amount': newAmt,
        'time': 'Just now',
        'isYou': isYou,
        'code': bidder.code,
      });

      if (_bidsHistory.length > 25) {
        _bidsHistory.removeLast();
      }
    });

    // Reset speech popup after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          bidder.isBidding = false;
          if (_activeBiddingBidder == bidder) {
            _activeBiddingBidder = null;
          }
        });
      }
    });
  }

  void _placeUserBid(int increment) {
    if (widget.watchOnly) {
      _showToast('Watch Mode Active: Regular customers cannot bid in VIP auctions.', isError: true);
      return;
    }
    final you = _bidders[8]; // BID 009
    final newAmt = (_currentBid + increment).toInt();
    _animateBidder(you, newAmt, isYou: true);
    _showToast('BID PLACED: \$$newAmt! You are currently the top bidder! 👑');
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: isError ? Colors.white : const Color(0xFF1E0A3C), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: isError ? Colors.white : const Color(0xFF1E0A3C),
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  void _showCustomBidDialog() {
    final controller = TextEditingController(text: (_currentBid + 10).toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B073B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.8),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 24),
            SizedBox(width: 8),
            Text('Custom VIP Bid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter amount higher than \$${_currentBid.toInt()}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF2E1065),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > _currentBid) {
                Navigator.pop(ctx);
                _placeUserBid(val - _currentBid.toInt());
              } else {
                _showToast('Bid must exceed current \$${_currentBid.toInt()}', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Place Bid', style: TextStyle(color: Color(0xFF1E0A3C), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showProductDetailsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF160633),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1065),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: const Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF38BDF8), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_productTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      const Text('Original Sealed Factory Box • Official Warranty',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF3B1376)),
            const SizedBox(height: 10),
            _buildSpecItem('Processor', 'Intel Core i7-13700H (14 Cores, 5.0GHz Turbo)'),
            _buildSpecItem('Graphics', 'NVIDIA GeForce RTX 4070 8GB GDDR6 VRAM'),
            _buildSpecItem('Memory', '16GB DDR5 5200MHz RAM'),
            _buildSpecItem('Storage', '1TB PCIe 4.0 NVMe M.2 SSD'),
            _buildSpecItem('Display', '15.6" QHD 165Hz IPS 100% sRGB Display'),
            _buildSpecItem('VIP Container', 'Lot ${widget.containerCode.toUpperCase()} Exclusive Live Drop'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Live Arena', style: TextStyle(color: Color(0xFF1E0A3C), fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoursStr = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutesStr = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final secondsStr = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFF090117),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // =========================================================================
              // 1. FULL 3D GRAPHIC AUDITORIUM STAGE WITH 40 ANIMATED INTERACTIVE HUMANS
              // =========================================================================
              _buildAuditoriumStageWith40Humans(hoursStr, minutesStr, secondsStr),

              const SizedBox(height: 12),

              // =========================================================================
              // 2. PRODUCT DETAILS STRIP (Specs • Core i7 • 16GB RAM • 1TB SSD • 15.6")
              // =========================================================================
              _buildProductDetailsStrip(),

              const SizedBox(height: 12),

              // =========================================================================
              // 3. USER VIP HUB & MAIN GAVEL BUTTON (You BID 009 + Bid +$10 + Custom Bid)
              // =========================================================================
              _buildUserActionSection(),

              const SizedBox(height: 10),

              // =========================================================================
              // 4. QUICK INCREMENT CHIPS: [ +$10 ]  [ +$20 ]  [ +$50 ]  [ +$100 ]
              // =========================================================================
              _buildQuickIncrementChips(),

              const SizedBox(height: 14),

              // =========================================================================
              // 5. LIVE BIDDING HISTORY LEADERBOARD matching Screenshot 4
              // =========================================================================
              _buildLiveBiddingHistory(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. FULL 3D GRAPHIC AUDITORIUM STAGE WITH 40 ANIMATED INTERACTIVE HUMANS ---
  Widget _buildAuditoriumStageWith40Humans(String hours, String minutes, String seconds) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      // High resolution 3D image aspect ratio (427 x 474 = ~1.11 height/width)
      final height = width * 1.11;

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Stack(
            children: [
              // High-Definition 3D Amphitheater Render
              Image.asset(
                'assets/images/vip_arena_bg.jpg',
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),

              // Dynamic Live Glowing Spotlights Overlay
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.4),
                          radius: 0.75 + (_glowController.value * 0.1),
                          colors: [
                            const Color(0xFFFFD700).withValues(alpha: 0.08 + (_glowController.value * 0.06)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Top Nav Bar (Back Arrow Left, Notification Bell Right)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
                      ),
                    ),
                    InkWell(
                      onTap: _showProductDetailsModal,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: Color(0xFFFFD700), size: 21),
                      ),
                    ),
                  ],
                ),
              ),

              // Watching Pill (Top-Left under nav)
              Positioned(
                top: 50,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_red_eye_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        '$_viewersCount Watching',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Bidders Pill (Top-Right under nav)
              Positioned(
                top: 50,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFFFFD700)),
                      const SizedBox(width: 5),
                      Text(
                        '$_totalBidders Bidders',
                        style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Current Bid Glowing Box (Left of Laptop)
              Positioned(
                top: 96,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Current Bid', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9.5)),
                      Text(
                        '\$${_currentBid.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Time Left Box (Right of Laptop)
              Positioned(
                top: 96,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Time Left', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9.5)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFFFD700)),
                          const SizedBox(width: 3),
                          Text(
                            '$hours:$minutes:$seconds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Stage Center Interactive Tap Area (Opens Laptop Specs Modal)
              Positioned(
                top: 90,
                left: width * 0.3,
                right: width * 0.3,
                height: 80,
                child: GestureDetector(
                  onTap: _showProductDetailsModal,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // =========================================================================
              // 40 ACTIVE INTERACTIVE AVATAR ANCHORS + SPEECH BUBBLE POPUPS ON TOP OF EACH
              // =========================================================================
              for (int i = 0; i < 40; i++)
                _buildLiveBidderHotspot(
                  bidder: _bidders[i],
                  anchor: _avatarAnchorPoints[i],
                  stageWidth: width,
                  stageHeight: height,
                ),
            ],
          ),
        ),
      );
    });
  }

  // Individual Hotspot for each of the 40 humans in the audience
  Widget _buildLiveBidderHotspot({
    required _VipBidderItem bidder,
    required Offset anchor,
    required double stageWidth,
    required double stageHeight,
  }) {
    final centerX = anchor.dx * stageWidth;
    final centerY = anchor.dy * stageHeight;
    final isYou = bidder.number == 9; // BID 009
    final isBidding = bidder.isBidding;

    return Positioned(
      left: centerX - 18,
      top: centerY - 20,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showToast('${bidder.name} placed a bid of \$${bidder.currentBid.toInt()}');
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Touch & Glow Hotspot (Translucent over the cartoon human head & seat)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isBidding
                      ? const Color(0xFFFFD700)
                      : (isYou ? const Color(0xFFFFD700).withValues(alpha: 0.8) : Colors.transparent),
                  width: isBidding ? 2.5 : 1.5,
                ),
                boxShadow: isBidding
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ]
                    : (isYou
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null),
              ),
            ),

            // SPEECH BUBBLE POPUP WHEN THIS HUMAN PLACES A BID!
            if (isBidding)
              Positioned(
                top: -34,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel_rounded, size: 10, color: Color(0xFF1E0A3C)),
                      const SizedBox(width: 3),
                      Text(
                        '\$${bidder.currentBid.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFF1E0A3C),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scaleXY(begin: 0.3, end: 1.0, duration: 250.ms, curve: Curves.elasticOut)
                    .moveY(begin: 10, end: 0, duration: 250.ms),
              ),
          ],
        ),
      ),
    );
  }

  // --- 2. PRODUCT DETAILS STRIP ---
  Widget _buildProductDetailsStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: _showProductDetailsModal,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF160633),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1065),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF38BDF8), size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_productTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(_productSpecs,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                  ],
                ),
              ),
              const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 12),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. USER VIP HUB & MAIN GAVEL BUTTON ---
  Widget _buildUserActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // "You (BID 009)" Avatar with Crown Badge
          GestureDetector(
            onTap: () => _placeUserBid(10),
            child: Column(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF2E1065)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, size: 40, color: Color(0xFFFFD700)),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1065),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'You (BID 009)',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Controls Column
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Current Highest Bid
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E0A3C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Bid', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9.5)),
                            Text(
                              '\$${_currentBid.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Custom Bid Button
                    InkWell(
                      onTap: _showCustomBidDialog,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B1376),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF8B5CF6)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text('Custom Bid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Primary Golden Gavel Button matching Screenshot 4
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _placeUserBid(10),
                    icon: const Icon(Icons.gavel_rounded, color: Color(0xFF1E0A3C), size: 21),
                    label: const Text(
                      'BID +\$10  (Place Your Bid)',
                      style: TextStyle(
                        color: Color(0xFF1E0A3C),
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  // --- 4. QUICK INCREMENT CHIPS ---
  Widget _buildQuickIncrementChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _buildChip(10),
          const SizedBox(width: 8),
          _buildChip(20),
          const SizedBox(width: 8),
          _buildChip(50),
          const SizedBox(width: 8),
          _buildChip(100),
        ],
      ),
    );
  }

  Widget _buildChip(int inc) {
    return Expanded(
      child: InkWell(
        onTap: () => _placeUserBid(inc),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E1065),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Center(
            child: Text(
              '+\$$inc',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 5. LIVE BIDDING HISTORY LEADERBOARD ---
  Widget _buildLiveBiddingHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF160633),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF4C1D95)),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.format_list_bulleted_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Bidding History',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                Spacer(),
                Text(
                  'All Bids >',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ..._bidsHistory.take(5).map((b) {
              final isYou = b['isYou'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isYou ? const Color(0xFFF59E0B).withValues(alpha: 0.18) : const Color(0xFF1E0A3C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isYou ? const Color(0xFFFFD700) : const Color(0xFF3B1376),
                    width: isYou ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isYou ? const Color(0xFFFFD700).withValues(alpha: 0.2) : const Color(0xFF3B1376),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isYou ? Icons.star_rounded : Icons.person_rounded,
                        size: 16,
                        color: isYou ? const Color(0xFFFFD700) : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      b['bidder'],
                      style: TextStyle(
                        color: isYou ? const Color(0xFFFFD700) : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 10),
                          SizedBox(width: 2),
                          Text(
                            'VIP',
                            style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${b['amount']}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      b['time'],
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
