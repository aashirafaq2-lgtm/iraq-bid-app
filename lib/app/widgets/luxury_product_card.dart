import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';

class LuxuryProductCard extends StatefulWidget {
  final String id;
  final String title;
  final String imageUrl;
  final int currentBid;
  final int totalBids;
  final DateTime endTime;
  final String? category;
  final String? tag;
  final String? specialDescription;
  final bool isSingleColumn;
  final VoidCallback onTap;

  const LuxuryProductCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.currentBid,
    required this.totalBids,
    required this.endTime,
    this.category,
    this.tag,
    this.specialDescription,
    this.isSingleColumn = false,
    required this.onTap,
  });

  @override
  State<LuxuryProductCard> createState() => _LuxuryProductCardState();
}

class _LuxuryProductCardState extends State<LuxuryProductCard> {
  bool _isFavorite = false;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  // Real-time title translation map for seamless English -> Arabic UI
  static final Map<String, String> _arabicTitles = {
    "Kids Camera Instant Print (BLUE-2)": "كاميرا طباعة فورية للأطفال (أزرق-2)",
    "Mini Electric Shaver, Portable Powerful Storm": "ماكينة حلاقة كهربائية صغيرة محمولة وقوية",
    "200W Cordless Hair Dryer with LED Display": "مجفف شعر لاسلكي 200 واط مع شاشة رقمية",
    "Emporio Armani Men's Sea Explorer Watch": "ساعة إمبوريو أرماني للرجال سي إكسبلورر",
    "Lenovo Wireless Earbuds Bluetooth 5.3": "سماعات لينوفو لاسلكية بلوتوث 5.3",
    "Air Fryer 6L, 1500W Healthy Cooking": "قلاية هوائية 6 لتر 1500 واط للطبخ الصحي",
    "Wireless Game Controller with Dual Vibration": "يد تحكم ألعاب لاسلكية مع اهتزاز مزدوج",
    "JBL Wireless Headphones Noise Cancelling": "سماعات رأس جي بي إل لاسلكية عازلة للضوضاء",
    "Smart Robot Vacuum Cleaner with Auto Charge": "مكنسة روبوت ذكية مع شحن ذاتي تلقائي",
    "Men's Sports Shoes Lightweight & Comfortable": "حذاء رياضي رجالي خفيف ومريح للغاية",
    "Power Bank 20000mAh Fast Charging 22.5W": "شاحن متنقل 20000 مللي أمبير شحن سريع",
    "WiFi Security Camera 360 HD Night Vision": "كاميرا مراقبة واي فاي 360 رؤية ليلية عالية الدقة",
    "Apple iPhone 15 Pro 128GB Blue Titanium": "آبل آيفون 15 برو 128 جيجابايت تيتانيوم أزرق",
    "Sony PlayStation 5 Slim Digital Console": "بلاي ستيشن 5 سليم إصدار رقمي",
    "Rolex Submariner Date Ceramic Bezel 41mm": "ساعة رولكس سابمارينر إطار سيراميك 41 ملم",
    "Samsung Galaxy S24 Ultra 512GB Titanium Gray": "سامسونج جالاكسي إس 24 ألترا 512 جيجا رمادي",
    "MacBook Air M2 13.6-inch Midnight": "ماك بوك إير إم 2 شاشة 13.6 إنش لون سماء الليل",
    "Dyson V15 Detect Cordless Vacuum Cleaner": "مكنسة دايسون في 15 ديتيكت اللاسلكية الذكية",
    "Nike Air Jordan 1 Retro High OG Chicago": "حذاء نايكي إير جوردان 1 ريترو هاي شيكاغو",
    "Sony WH-1000XM5 Wireless Noise Canceling Headphones": "سماعات سوني إم 5 اللاسلكية العازلة للصوت",
    "DeLonghi Magnifica S Automatic Coffee Maker": "ماكينة قهوة ديلونجي ماجنيفيكا إس أوتوماتيكية",
    "TAG Heuer Carrera Chronograph Automatic": "ساعة تاغ هوير كاريرا كرونوغراف أوتوماتيك",
    "iPad Pro 11-inch M4 Ultra Retina XDR": "آيباد برو 11 إنش معالج إم 4 الترا ريتينا",
    "DJI Mini 4 Pro Drone with RC 2 Controller": "طائرة درون دي جي آي ميني 4 برو مع ريموت آر سي",
    "Bose SoundLink Revolve+ II Bluetooth Speaker": "مكبر صوت بوز ساوند لينك ريفولف بلس الجيل 2",
    "Ray-Ban Meta Smart Glasses Wayfarer Polarized": "نظارة ريبان ميتا الذكية وايفارير مستقطبة",
    "KitchenAid Artisan Stand Mixer 4.8L Empire Red": "عجانة كيتشن إيد أرتيزان 4.8 لتر أحمر ملكي",
    "Dell XPS 15 9530 Intel Core i9 RTX 4070": "لابتوب ديل إكس بي إس 15 معالج آي 9 كرت 4070",
    "Sony Alpha A7 IV Full-Frame Mirrorless Camera": "كاميرا سوني ألفا إيه 7 الجيل الرابع فل فريم",
    "Casio G-Shock Mudmaster Carbon Core Guard": "ساعة كاسيو جي شوك مادماستر كربون كور غارد",
    "Test Admin Product Creation": "منتج فحص المزادات الحية",
  };

  static final Map<String, String> _arabicCategories = {
    "All": "الكل",
    "Luxury": "فاخر",
    "Shoes": "أحذية",
    "Electronics": "إلكترونيات",
    "Fashion": "أزياء",
    "Home": "المنزل",
    "Watches": "ساعات",
    "Mobiles": "موبايل",
    "Gaming": "ألعاب",
    "Home Appliances": "أجهزة منزلية",
    "Mobile Accessories": "إكسسوارات موبايل",
    "Audio": "صوتيات",
  };

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _calculateRemainingTime();
    });
  }

  void _checkFavoriteStatus() async {
    final pId = int.tryParse(widget.id);
    if (pId != null) {
      final isFav = await StorageService.isInWishlist(pId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  Future<void> _handleFavoriteToggle() async {
    final pId = int.tryParse(widget.id);
    if (pId == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isFavorite = !_isFavorite);
    await StorageService.toggleWishlist(pId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    if (widget.endTime.isAfter(now)) {
      setState(() {
        _remaining = widget.endTime.difference(now);
      });
    } else {
      setState(() {
        _remaining = Duration.zero;
      });
    }
  }

  String _formatTimer() {
    if (_remaining == Duration.zero) return '00h 00m 00s';
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m ${seconds}s';
  }

  Color _getTagColor(String? label) {
    if (label == null || label.isEmpty) return const Color(0xFFEFF6FF);
    final hash = label.hashCode.abs();
    final colors = [
      const Color(0xFFEFF6FF), // Soft Blue
      const Color(0xFFECFDF5), // Mint
      const Color(0xFFFFF7ED), // Peach
      const Color(0xFFFAF5FF), // Purple
      const Color(0xFFFDF2F8), // Rose
    ];
    return colors[hash % colors.length];
  }

  Color _getTagTextColor(String? label) {
    if (label == null || label.isEmpty) return const Color(0xFF0284C7);
    final hash = label.hashCode.abs();
    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFF059669),
      const Color(0xFFEA580C),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageService.isArabic;
    
    // Resolve display title and custom special description tag (if provided)
    final customTag = widget.specialDescription ?? widget.tag;
    final displayTag = (customTag != null && customTag.trim().isNotEmpty) ? customTag.trim() : null;
    final displayTitle = isArabic ? (_arabicTitles[widget.title] ?? widget.title) : widget.title;

    // --- 1-BY-1 FULL HORIZONTAL/VERTICAL CARD MATCHING SCREENSHOT 2 ---
    if (widget.isSingleColumn) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Width Product Image with Wishlist Heart
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 1.45,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        placeholder: (context, url) => Container(color: const Color(0xFFF8FAFC)),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF8FAFC),
                          child: const Icon(Icons.image_not_supported_outlined, size: 36, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                  ),

                  // Wishlist Button
                  Positioned(
                    top: 10,
                    right: isArabic ? null : 10,
                    left: isArabic ? 10 : null,
                    child: GestureDetector(
                      onTap: _handleFavoriteToggle,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: _isFavorite ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Details exactly matching Screenshot 2
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Current Bid & Countdown Timer Row
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded, size: 16, color: Color(0xFFE11D48)),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? 'المزايدة الحالية' : 'Current Bid',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\$${widget.currentBid}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimer(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Full Width Orange "Buy Now $220" Button matching Screenshot 2
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isArabic ? 'اشترِ الآن \$${widget.currentBid * 2}' : 'Buy Now  \$${widget.currentBid * 2}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Canvas with floating category tag and wishlist heart
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 320,
                      memCacheHeight: 320,
                      maxWidthDiskCache: 600,
                      maxHeightDiskCache: 600,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Icon(Icons.image_not_supported_outlined, size: 28, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),

                // Special Description / Custom Badge Tag (Only shown if special description is manually written)
                if (displayTag != null)
                  Positioned(
                    top: 6,
                    left: isArabic ? null : 6,
                    right: isArabic ? 6 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getTagColor(displayTag),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        displayTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: _getTagTextColor(displayTag),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                // Wishlist Button
                Positioned(
                  top: 5,
                  right: isArabic ? null : 5,
                  left: isArabic ? 5 : null,
                  child: GestureDetector(
                    onTap: _handleFavoriteToggle,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: _isFavorite ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Info Details (Title, 24h Countdown Timer, Live Price)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),

                    // 24H Live Countdown Timer Pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.7),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 10, color: Color(0xFF059669)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _formatTimer(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price Pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFED7AA), width: 0.7),
                      ),
                      child: Text(
                        '${widget.currentBid} \$',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .scaleXY(begin: 0.96, end: 1.0, duration: 250.ms, curve: Curves.easeOutCubic);
  }
}
