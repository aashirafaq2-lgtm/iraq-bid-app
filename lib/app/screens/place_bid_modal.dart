import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';

class PlaceBidModal extends StatefulWidget {
  final int currentBid;
  final String productTitle;
  final int productId;

  const PlaceBidModal({
    super.key,
    required this.currentBid,
    required this.productTitle,
    required this.productId,
  });

  @override
  State<PlaceBidModal> createState() => _PlaceBidModalState();
}

class _PlaceBidModalState extends State<PlaceBidModal>
    with TickerProviderStateMixin {
  final TextEditingController _bidController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSuccess = false;
  late int _selectedBid;

  late AnimationController _modalController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _successController;
  late Animation<double> _successScale;

  static const int usdToIqdRate = 1520;

  int get _minBid => widget.currentBid + 1;
  List<int> get _quickIncrements => [5, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _selectedBid = _minBid;
    _bidController.text = '$_selectedBid';

    _modalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _modalController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(parent: _modalController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _modalController.forward();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _modalController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onQuickIncrement(int inc) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedBid = widget.currentBid + inc;
      _bidController.text = '$_selectedBid';
    });
  }

  void _adjustBid(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      final newVal = _selectedBid + delta;
      if (newVal >= _minBid) {
        _selectedBid = newVal;
        _bidController.text = '$_selectedBid';
      }
    });
  }

  Future<void> _handleSubmit(bool isArabic) async {
    final amount = int.tryParse(_bidController.text);
    if (amount == null || amount < _minBid) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يجب أن تكون المزايدة أعلى من \$${widget.currentBid}'
                : 'Bid must be greater than \$${widget.currentBid}',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final isLoggedIn = await StorageService.isLoggedIn();
    if (!isLoggedIn) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/auth');
      }
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    try {
      await apiService.placeBid(
        productId: widget.productId,
        amount: amount.toDouble(),
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
        _successController.forward();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, locale, _) {
        final isArabic = LanguageService.isArabic;

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  top: 16,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 36,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: _isSuccess
                    ? _buildSuccessView(isArabic)
                    : _buildBidView(isArabic),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessView(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'تم تأكيد مزايدتك بنجاح!' : 'Bid Placed Successfully!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'أنت الآن أعلى مزايد بمبلغ \$$_selectedBid'
                : 'You are now the highest bidder at \$$_selectedBid',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidView(bool isArabic) {
    final iqdAmount = _selectedBid * usdToIqdRate;
    final formattedIqd = iqdAmount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle Pill
        Center(
          child: Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Header with live pulsing dot
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'تقديم مزايدة حية' : 'Live Bid Stepper',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 250,
                  child: Text(
                    widget.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    isArabic ? 'الحالي' : 'Current',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '\$${widget.currentBid}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Stepper Interactive Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Minus Button
                  _StepButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _adjustBid(-1),
                    color: const Color(0xFF64748B),
                  ),

                  // Middle Bid Display
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            '\$ ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          Text(
                            '$_selectedBid',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '≈ $formattedIqd IQD',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Plus Button
                  _StepButton(
                    icon: Icons.add_rounded,
                    onTap: () => _adjustBid(1),
                    color: const Color(0xFF0284C7),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Quick Increment Chips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _quickIncrements.length,
            itemBuilder: (context, idx) {
              final inc = _quickIncrements[idx];
              final isMatch = _selectedBid == (widget.currentBid + inc);

              return GestureDetector(
                onTap: () => _onQuickIncrement(inc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isMatch ? const Color(0xFF0284C7) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMatch ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isMatch
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '+ \$$inc',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isMatch ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Confirm Bid Button
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _handleSubmit(isArabic),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gavel_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isArabic
                            ? 'تأكيد المزايدة بمبلغ \$$_selectedBid'
                            : 'Place Bid Now (\$$_selectedBid)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
