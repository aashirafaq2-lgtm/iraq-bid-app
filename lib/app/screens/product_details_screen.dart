import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../services/language_service.dart';
import 'place_bid_modal.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isLiked = false;
  ProductModel? _product;
  List<ProductModel> _similarProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _userId;
  bool _isLoggedIn = false;

  late PageController _pageController;
  Timer? _autoSlideTimer;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(hours: 23, minutes: 59, seconds: 45);

  // Stepper Bid State
  int _bidAmount = 17;
  bool _isSubmittingBid = false;

  // Expandable sections state
  bool _isDescriptionExpanded = false;
  bool _isConditionExpanded = false;
  bool _isWarningExpanded = false;

  // Real-time title translation map for 100% Arabic support
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
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserInfo();
    _loadProductData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoSlideTimer?.cancel();
    _countdownTimer?.cancel();
    socketService.leaveProductRoom(widget.productId);
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final userId = await StorageService.getUserId();
    final isLoggedIn = await StorageService.isLoggedIn();
    if (mounted) {
      setState(() {
        _userId = userId;
        _isLoggedIn = isLoggedIn;
      });
    }

    socketService.init();
    socketService.joinProductRoom(widget.productId);
    socketService.onBidUpdate((data) {
      if (mounted) {
        _loadProductData();
      }
    });
  }

  Future<void> _loadProductData() async {
    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) throw Exception('Invalid product ID');

      final results = await Future.wait([
        apiService.getProductById(productId),
        StorageService.isInWishlist(productId),
        apiService.getProducts(limit: 10),
      ]);

      if (mounted) {
        final prod = results[0] as ProductModel;
        final inWish = results[1] as bool;
        final allProds = results[2] as List<ProductModel>;

        final currentBidVal = (prod.currentBid ?? prod.startingPrice).toInt();
        // Default bid stepper is current bid + 1
        final nextBid = currentBidVal + 1;

        // Calculate Remaining 24 Hours Countdown
        _calculateCountdown(prod);

        setState(() {
          _product = prod;
          _isLiked = inWish;
          _bidAmount = nextBid;
          _similarProducts = allProds.where((p) => p.id != prod.id).toList();
          _isLoading = false;
        });

        _startAutoSlide();
        _startCountdownTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _calculateCountdown(ProductModel prod) {
    final now = DateTime.now();
    DateTime endTime;

    if (prod.auctionEndTime != null) {
      endTime = prod.auctionEndTime!;
    } else if (prod.createdAt != null) {
      endTime = prod.createdAt!.add(const Duration(hours: 24));
    } else {
      endTime = now.add(const Duration(hours: 23, minutes: 21, seconds: 11));
    }

    final diff = endTime.difference(now);
    if (diff.isNegative) {
      _remainingTime = Duration.zero;
    } else {
      _remainingTime = diff;
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    final images = _getProductImages();
    if (images.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!mounted || !_pageController.hasClients) return;
        final nextIdx = (_currentImageIndex + 1) % images.length;
        _pageController.animateToPage(
          nextIdx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  List<String> _getProductImages() {
    if (_product == null) return [];
    if (_product!.imageUrls.isNotEmpty) return _product!.imageUrls;
    if (_product!.imageUrl != null && _product!.imageUrl!.isNotEmpty) {
      return [_product!.imageUrl!];
    }
    return ['https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?auto=format&fit=crop&w=800&q=80'];
  }

  Future<void> _toggleWishlist() async {
    if (!_isLoggedIn) {
      context.push('/auth');
      return;
    }
    if (_product == null) return;

    HapticFeedback.lightImpact();
    setState(() => _isLiked = !_isLiked);

    try {
      await StorageService.toggleWishlist(_product!.id);
    } catch (e) {
      if (mounted) {
        setState(() => _isLiked = !_isLiked);
      }
    }
  }

  Future<void> _handleShare() async {
    if (_product == null) return;
    final currentPrice = (_product!.currentBid ?? _product!.startingPrice).toInt();
    final shareMsg =
        "${_product!.title}\nPrice: \$$currentPrice\nProduct ID: #${_product!.id}\nIraq Bid Live Auction: https://iraqbid.net/product/${_product!.id}";
    await Share.share(shareMsg, subject: _product!.title);
  }

  void _incrementBid() {
    HapticFeedback.selectionClick();
    setState(() => _bidAmount += 1);
  }

  void _decrementBid() {
    final currentBidVal = (_product?.currentBid ?? _product?.startingPrice ?? 1).toInt();
    // Cannot bid less than or equal to current bid
    if (_bidAmount > currentBidVal + 1) {
      HapticFeedback.selectionClick();
      setState(() => _bidAmount -= 1);
    } else {
      HapticFeedback.vibrate();
      final isAr = LanguageService.isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'لا يمكن المزايدة بمبلغ أقل من أو يساوي أعلى مزايدة حالية (\$$currentBidVal)'
                : 'Bid must be strictly higher than current bid (\$$currentBidVal)',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePlaceBid() async {
    final isAr = LanguageService.isArabic;
    if (!_isLoggedIn) {
      context.push('/auth');
      return;
    }

    final currentBidVal = (_product?.currentBid ?? _product?.startingPrice ?? 1).toInt();
    if (_bidAmount <= currentBidVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يجب أن تكون مزايدتك أعلى من \$$currentBidVal'
                : 'Your bid must be greater than \$$currentBidVal',
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmittingBid = true);
    HapticFeedback.mediumImpact();

    try {
      final pId = int.tryParse(widget.productId) ?? _product!.id;
      final response = await apiService.placeBid(
        productId: pId,
        amount: _bidAmount.toDouble(),
      );

      if (mounted) {
        setState(() => _isSubmittingBid = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'تم تقديم مزايدتك بنجاح بقيمة \$$_bidAmount!'
                        : 'Bid placed successfully for \$$_bidAmount!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadProductData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingBid = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'فشل تقديم المزايدة: $e' : 'Failed to place bid: $e',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
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
        final isArabic = locale.languageCode == 'ar' ||
            LanguageService.getLanguageName() == 'Arabic';

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            body: SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF0066FF),
                      ),
                    )
                  : (_errorMessage != null || _product == null)
                      ? _buildErrorView(isArabic)
                      : _buildMainContent(isArabic),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? (isArabic ? 'المنتج غير موجود' : 'Product Not Found'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isArabic) {
    final p = _product!;
    final images = _getProductImages();
    final currentBidVal = (p.currentBid ?? p.startingPrice).toInt();
    final realPrice = (p.buyNowPrice ?? (currentBidVal * 1.6)).toInt();
    final buyNowPrice = (p.buyNowPrice ?? (currentBidVal * 1.5)).toInt();

    // Title translation
    final localizedTitle = isArabic
        ? (_arabicTitles[p.title] ?? p.title)
        : p.title;

    // Remaining time formatting
    final hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    final formattedTime = '${hours}h ${minutes}m ${seconds}s';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP HERO IMAGE SLIDER WITH FLOATING BUTTONS
          Stack(
            children: [
              // Image Carousel Container
              Container(
                height: 330,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (idx) {
                    setState(() => _currentImageIndex = idx);
                  },
                  itemBuilder: (context, idx) {
                    return CachedNetworkImage(
                      imageUrl: images[idx],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 60, color: Color(0xFF94A3B8)),
                      ),
                    );
                  },
                ),
              ),

              // Back Button (Top Left)
              Positioned(
                top: 12,
                left: isArabic ? null : 16,
                right: isArabic ? 16 : null,
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 26,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              // Top Right Action Buttons (Notification Bell + Wishlist Heart)
              Positioned(
                top: 12,
                right: isArabic ? null : 16,
                left: isArabic ? 16 : null,
                child: Row(
                  children: [
                    // Notification Button
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 20,
                              color: Color(0xFF0284C7),
                            ),
                            Positioned(
                              top: 9,
                              right: 9,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Heart Wishlist Button
                    GestureDetector(
                      onTap: _toggleWishlist,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 22,
                          color: _isLiked ? const Color(0xFFEF4444) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Previous Image Arrow (Floating Left)
              if (images.length > 1)
                Positioned(
                  left: 12,
                  top: 140,
                  child: GestureDetector(
                    onTap: () {
                      if (_currentImageIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),

              // Next Image Arrow (Floating Right)
              if (images.length > 1)
                Positioned(
                  right: 12,
                  top: 140,
                  child: GestureDetector(
                    onTap: () {
                      if (_currentImageIndex < images.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),

              // Page Counter Indicator Badge (Bottom Right "1/8")
              Positioned(
                bottom: 14,
                right: isArabic ? null : 16,
                left: isArabic ? 16 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. HORIZONTAL THUMBNAIL PREVIEW STRIP
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (context, idx) {
                final isSelected = idx == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.2 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: images[idx],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 3. PRODUCT TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              localizedTitle,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
                height: 1.25,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. 3-PANEL STATUS BAR (Time Left | Stepper Bid | Current Bid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 1. Time Left Pill Card
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 22, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'الوقت المتبقي' : 'Time Left',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Interactive Bid Stepper (- $17 +)
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Minus Button
                            GestureDetector(
                              onTap: _decrementBid,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFEDD5)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.remove, size: 16, color: Color(0xFFF97316)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Stepper Value
                            Text(
                              '\$$_bidAmount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEA580C),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Plus Button
                            GestureDetector(
                              onTap: _incrementBid,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFEDD5)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add, size: 16, color: Color(0xFFF97316)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic ? 'مبلغ مزايدتك' : 'Your Bid Amount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Current Bid Badge Card
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gavel_rounded, size: 20, color: Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'أعلى مزايدة' : 'Current Bid',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$currentBidVal \$',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 5. PRIMARY ACTION BUTTON ("Place Bid")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmittingBid ? null : _handlePlaceBid,
                icon: const Icon(Icons.gavel_rounded, size: 19, color: Colors.white),
                label: _isSubmittingBid
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isArabic ? 'تقديم المزايدة' : 'Place Bid',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 6. SECONDARY ACTION BUTTON ("Buy Now $25")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'الشراء الفوري بقيمة \$$buyNowPrice غير متاح حالياً'
                            : 'Instant Buy Now at \$$buyNowPrice is not enabled for this lot',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined, size: 19, color: Color(0xFFF97316)),
                label: Text(
                  isArabic ? 'شراء فوري \$$buyNowPrice' : 'Buy Now \$$buyNowPrice',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEA580C),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFDBA74), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 7. 3-COLUMN METRICS (Real Price | Product ID | Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  // Real Price
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFF0F172A)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'السعر الأصلي' : 'Real Price',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            Text(
                              '$realPrice \$',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),

                  // Product ID
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF0F172A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'رقم المنتج' : 'Product ID',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                                Text(
                                  '#${p.id}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(height: 28, width: 1, color: const Color(0xFFE2E8F0)),

                  // Share Button
                  Expanded(
                    child: GestureDetector(
                      onTap: _handleShare,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_outlined, size: 18, color: Color(0xFF0F172A)),
                          const SizedBox(width: 6),
                          Text(
                            isArabic ? 'مشاركة' : 'Share',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
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

          const SizedBox(height: 14),

          // 8. EXPANDABLE DROPDOWNS (Description | Condition | Warning)
          _buildExpandableTile(
            icon: Icons.description_outlined,
            title: isArabic ? 'الوصف' : 'Description',
            isExpanded: _isDescriptionExpanded,
            onTap: () {
              setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
            },
            child: Text(
              p.description?.isNotEmpty == true
                  ? p.description!
                  : (isArabic
                      ? 'كاميرا طباعة فورية بدقة عالية تدعم الورق الحراري وذاكرة 32 جيجابايت مع ملحقات تصوير وشحن سريع ومؤثرات صور متعددة مناسبة للأطفال.'
                      : 'Kids Instant Print Camera with 32GB memory card, thermal paper rolls, multiple cartoon frames, and rechargeable battery.'),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),

          _buildExpandableTile(
            icon: Icons.settings_outlined,
            title: isArabic ? 'الحالة' : 'Condition',
            isExpanded: _isConditionExpanded,
            onTap: () {
              setState(() => _isConditionExpanded = !_isConditionExpanded);
            },
            child: Text(
              isArabic
                  ? 'المنتج جديد تماماً 100% داخل العلبة الأصلية مع ضمان الفحص المباشر.'
                  : (p.condition ?? 'Brand New (In Original Retail Box with Inspection Warranty)'),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),

          _buildExpandableTile(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFEF4444),
            title: isArabic ? 'تحذير وإرشادات' : 'Warning',
            isExpanded: _isWarningExpanded,
            onTap: () {
              setState(() => _isWarningExpanded = !_isWarningExpanded);
            },
            child: Text(
              isArabic
                  ? 'المزايدة ملزمة قانونياً داخل المنصة. يرجى التأكد من رغبتك بالشراء قبل تقديم أي عرض مزايدة لتجنب حظر الحساب.'
                  : 'Bidding is legally binding. Please verify item details before placing a bid. Defaulting may result in account restriction.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFDC2626),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 9. SHIPPING COST NOTICE CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 22, color: Color(0xFF0284C7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'إشعار رسوم التوصيل' : 'Shipping Cost Notice',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic
                            ? 'في حال فوزك بهذا المزاد، ستتم إضافة 2.5\$ رسوم شحن إلى المبلغ الإجمالي.'
                            : 'If you win this bid, a \$2.5 shipping cost will be added to the final amount.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0C4A6E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 10. SIMILAR PRODUCTS SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'منتجات مشابهة' : 'Similar Products',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to category page
                    context.go('/home');
                  },
                  child: Row(
                    children: [
                      Text(
                        isArabic ? 'عرض الكل' : 'See All',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                        size: 16,
                        color: const Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Similar Products Horizontal List
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _similarProducts.length,
              itemBuilder: (context, idx) {
                final item = _similarProducts[idx];
                final simTitle = isArabic
                    ? (_arabicTitles[item.title] ?? item.title)
                    : item.title;

                return GestureDetector(
                  onTap: () {
                    context.push('/product-details/${item.id}');
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                          child: Container(
                            height: 90,
                            width: double.infinity,
                            color: const Color(0xFFF1F5F9),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl ?? (item.imageUrls.isNotEmpty ? item.imageUrls.first : ''),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.image_outlined, size: 28, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                simTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(item.currentBid ?? item.startingPrice).toInt()} \$',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildExpandableTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 19, color: iconColor ?? const Color(0xFF0F172A)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right_rounded,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
