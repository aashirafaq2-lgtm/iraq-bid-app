import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';

class AuctionReminderModal extends StatefulWidget {
  final String productTitle;
  final Duration remainingTime;

  const AuctionReminderModal({
    super.key,
    required this.productTitle,
    required this.remainingTime,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String productTitle,
    required Duration remainingTime,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) => AuctionReminderModal(
        productTitle: productTitle,
        remainingTime: remainingTime,
      ),
    );
  }

  @override
  State<AuctionReminderModal> createState() => _AuctionReminderModalState();
}

class _AuctionReminderModalState extends State<AuctionReminderModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bellShakeAnimation;

  // Selected interval in minutes (default is 5 minutes)
  int _selectedMinutes = 5;

  final List<Map<String, dynamic>> _intervals = [
    {'minutes': 1, 'label_en': '1\nminute', 'label_ar': '1\nدقيقة'},
    {'minutes': 5, 'label_en': '5\nminutes', 'label_ar': '5\nدقائق'},
    {'minutes': 10, 'label_en': '10\nminutes', 'label_ar': '10\nدقائق'},
    {'minutes': 15, 'label_en': '15\nminutes', 'label_ar': '15\nدقيقة'},
    {'minutes': 30, 'label_en': '30\nminutes', 'label_ar': '30\nدقيقة'},
    {'minutes': 60, 'label_en': '1\nhour', 'label_ar': '1\nساعة'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _bellShakeAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleSetReminder() {
    HapticFeedback.mediumImpact();
    final isAr = LanguageService.isArabic;

    Navigator.of(context).pop(true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr
                    ? 'تم ضبط التنبيه! سنذكرك قبل نهاية المزاد بـ $_selectedMinutes دقيقة'
                    : 'Auction reminder set for $_selectedMinutes minutes before ending!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF97316),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageService.isArabic;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Close 'X' Button in Top Corner
                Positioned(
                  top: 0,
                  right: isAr ? null : 0,
                  left: isAr ? 0 : null,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),

                // Main Modal Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // Glowing Animated Bell Badge
                    AnimatedBuilder(
                      animation: _bellShakeAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _bellShakeAnimation.value,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFEF3C7),
                                  const Color(0xFFFFFBEB),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: 38,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Title
                    Text(
                      isAr ? 'ضبط تذكير المزاد' : 'Set Auction Reminder',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      isAr
                          ? 'تلقى إشعاراً فورياً قبل انتهاء هذا المزاد.'
                          : 'Get notified before this auction ends.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2x3 Grid of Intervals (1 min, 5 min, 10 min, 15 min, 30 min, 1 hour)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _intervals.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.25,
                      ),
                      itemBuilder: (context, idx) {
                        final item = _intervals[idx];
                        final minutes = item['minutes'] as int;
                        final isSelected = _selectedMinutes == minutes;
                        final label = isAr ? item['label_ar'] : item['label_en'];

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedMinutes = minutes);
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.6 : 1.0,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFFF97316).withOpacity(0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFF1E293B),
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              // Checkmark badge for selected item
                              if (isSelected)
                                Positioned(
                                  top: -4,
                                  right: isAr ? null : -4,
                                  left: isAr ? -4 : null,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF97316),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.check, size: 11, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Set Reminder Primary Orange Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _handleSetReminder,
                        icon: const Icon(Icons.notifications_active_rounded, size: 18, color: Colors.white),
                        label: Text(
                          isAr ? 'ضبط التذكير' : 'Set Reminder',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
