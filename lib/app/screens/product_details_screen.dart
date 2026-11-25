import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../services/language_service.dart';
import '../widgets/auction_reminder_modal.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
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

  // Winning status state & user's max bid
  bool _isWinning = false;
  double? _userMaxBid;

  // Real-time Bidders & Bids stats for client requirement
  List<BidModel> _productBids = [];
  int _uniqueBiddersCount = 0;
  bool _isLoadingBids = false;

  // Pulse & Confetti Glow Animation for Winning Card
  late AnimationController _winningAnimController;
  late Animation<double> _trophyScaleAnim;
  late Animation<double> _glowPulseAnim;

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

    // Pulse & Trophy animation for Winning State
    _winningAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _trophyScaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _winningAnimController,
        curve: Curves.easeInOut,
      ),
    );

    _glowPulseAnim = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(
        parent: _winningAnimController,
        curve: Curves.easeInOut,
      ),
    );

    _loadUserInfo();
    _loadProductData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _winningAnimController.dispose();
    _autoSlideTimer?.cancel();
    _countdownTimer?.cancel();
    socketService.leaveProductRoom(widget.productId);
    if (_userId != null) {
      socketService.leaveUserRoom(_userId);
    }
    socketService.offBidUpdate();
    socketService.offOutbid();
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
    if (userId != null) {
      socketService.joinUserRoom(userId);
    }

    // Direct instantaneous Outbid Listener for connected user
    socketService.onOutbid((data) {
      if (!mounted) return;
      final outbidProdId = data['productId']?.toString();
      if (outbidProdId == widget.productId) {
        final newHighest = data['newHighestBid'];
        final double newHighestVal = (newHighest is num)
            ? newHighest.toDouble()
            : double.tryParse(newHighest.toString()) ?? 0.0;

        setState(() {
          _isWinning = false; // IMMEDIATELY REMOVE WINNING STATUS!
          if (_product != null && newHighestVal > 0) {
            _product = _product!.copyWith(currentBid: newHighestVal);
            if (_bidAmount <= newHighestVal.toInt()) {
              _bidAmount = newHighestVal.toInt() + 1;
            }
          }
        });

        HapticFeedback.heavyImpact();
        final isAr = LanguageService.isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'لقد تمت المزايدة عليك بمبلغ \$${newHighestVal.toInt()}! زايد الآن لاستعادة الصدارة.'
                        : 'You’ve been outbid at \$${newHighestVal.toInt()}! Place a new bid now to win.',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    socketService.onBidUpdate((data) {
      if (mounted) {
        // Instant real-time socket update for anyone watching the item
        final rawProdId = data['productId'] ?? data['product_id'];
        if (rawProdId != null && rawProdId.toString() != widget.productId) {
          return; // Ignore if not for this product
        }

        final newPrice = data['currentPrice'] ?? data['current_bid'];
        final totalB = data['totalBids'] ?? data['total_bids'];
        final highestBidderId = data['highestBidderId'] ?? data['highest_bidder_id'];
        final highestBidderName = data['highest_bidder_name'] ?? data['lastBidderName'];

        if (newPrice != null && _product != null) {
          final priceVal = (newPrice is num) ? newPrice.toDouble() : double.tryParse(newPrice.toString()) ?? _product!.currentBid;
          final int newTotal = (totalB is int)
              ? totalB
              : int.tryParse(totalB?.toString() ?? '') ?? ((_product!.totalBids ?? 0) + 1);

          final int? newHighestId = (highestBidderId is int)
              ? highestBidderId
              : int.tryParse(highestBidderId?.toString() ?? '');

          // Instantly determine winning status without requiring network round-trip
          final bool amIWinning = (_userId != null && newHighestId != null && _userId == newHighestId);

          setState(() {
            _product = _product!.copyWith(
              currentBid: priceVal,
              totalBids: newTotal,
              highestBidderId: newHighestId,
              highestBidderName: highestBidderName?.toString(),
            );
            _isWinning = amIWinning;
            if (amIWinning && _userMaxBid == null) {
              _userMaxBid = priceVal;
            }

            if (_bidAmount <= (priceVal ?? 0).toInt()) {
              _bidAmount = (priceVal ?? 0).toInt() + 1;
            }

            // Also prepend to live bidding history if bid object supplied
            if (data['bid'] != null && data['bid'] is Map) {
              try {
                final bidMap = Map<String, dynamic>.from(data['bid'] as Map);
                final newBidObj = BidModel(
                  id: int.tryParse(bidMap['id']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
                  productId: int.tryParse(widget.productId) ?? 0,
                  userId: int.tryParse(bidMap['user_id']?.toString() ?? '') ?? (newHighestId ?? 0),
                  amount: priceVal ?? 0.0,
                  createdAt: DateTime.tryParse(bidMap['created_at']?.toString() ?? '') ?? DateTime.now(),
                  bidderName: highestBidderName?.toString(),
                  isHighestBidder: true,
                );
                _productBids.insert(0, newBidObj);
              } catch (_) {}
            }
          });
        }
        _loadProductData();
      }
    });
  }

  Future<void> _loadProductData() async {
    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) throw Exception('Invalid product ID');

      final results = await Future.wait<dynamic>([
        apiService.getProductById(productId),
        StorageService.isInWishlist(productId),
        apiService.getAllProducts(limit: 10),
        apiService.getBidsByProduct(productId).catchError((_) => <BidModel>[]),
      ]);

      if (mounted) {
        final prod = results[0] as ProductModel;
        final inWish = results[1] as bool;
        final prodsMap = results[2] as Map<String, dynamic>;
        final allProds = prodsMap['products'] as List<ProductModel>? ?? [];
        final fetchedBids = results[3] as List<BidModel>? ?? [];

        // Calculate unique bidders count
        final uniqueBidders = fetchedBids.map((b) => b.userId).toSet().length;

        final currentBidVal = (prod.currentBid ?? prod.startingPrice).toInt();
        // Default bid stepper is current bid + 1
        final nextBid = currentBidVal + 1;

        // Calculate Remaining 24 Hours Countdown
        _calculateCountdown(prod);

        // Check if current logged-in user is the winning (highest) bidder
        bool isUserWinning = false;
        double? userWinningMax = _userMaxBid;

        if (_userId != null && _isLoggedIn) {
          if (prod.highestBidderId == _userId) {
            isUserWinning = true;
            userWinningMax ??= (prod.currentBid ?? prod.startingPrice);
          }
        }

        setState(() {
          _product = prod;
          _isLiked = inWish;
          _bidAmount = nextBid;
          _similarProducts = allProds.where((p) => p.id != prod.id).toList();
          _productBids = fetchedBids;
          _uniqueBiddersCount = uniqueBidders;
          _isLoading = false;
          _isWinning = isUserWinning;
          _userMaxBid = userWinningMax;
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
    final barcodeStr = (_product!.originalBarcode != null && _product!.originalBarcode!.isNotEmpty)
        ? _product!.originalBarcode!
        : 'IQB-${_product!.id.toString().padLeft(6, '0')}';
    final shareMsg =
        "${_product!.title}\nPrice: \$$currentPrice\nBarcode: $barcodeStr\nIraq Bid Live Auction: https://iraqbid.net/product/${_product!.id}";
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
        final placedAmount = _bidAmount.toDouble();
        // Immediate local optimistic state update so price and stepper change instantly!
        setState(() {
          _isSubmittingBid = false;
          _isWinning = true;
          _userMaxBid = placedAmount;
          if (_product != null) {
            _product = _product!.copyWith(
              currentBid: placedAmount,
              totalBids: (_product!.totalBids ?? 0) + 1,
            );
          }
          _bidAmount = placedAmount.toInt() + 1; // Auto advance stepper to next bid
        });

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
    final realPrice = (p.originalRetailPrice != null && p.originalRetailPrice! > 0)
        ? p.originalRetailPrice!.toInt()
        : ((p.realPrice != null && p.realPrice! > 0)
            ? p.realPrice!.toInt()
            : (p.buyNowPrice ?? (currentBidVal * 1.6)).toInt());
    final buyNowPrice = (p.buyNowPrice ?? (currentBidVal * 1.5)).toInt();

    // Title translation
    final localizedTitle = isArabic
        ? (_arabicTitles[p.title] ?? p.title)
        : p.title;

    // Coming Soon check
    final bool isComingSoon = (p.status.toLowerCase() == 'coming_soon' || p.auctionStatus?.toLowerCase() == 'coming_soon');

    // Remaining time formatting
    final hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    final formattedTime = isComingSoon
        ? (isArabic ? 'قريباً' : 'Coming Soon')
        : '${hours}h ${minutes}m ${seconds}s';

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
                    // Notification / Reminder Bell Button (Opens exact Set Auction Reminder Modal)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AuctionReminderModal.show(
                          context,
                          productTitle: localizedTitle,
                          remainingTime: _remainingTime,
                        );
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
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: Color(0xFF0284C7),
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

          // 3. PRODUCT TITLE (Auto-translated to EN / AR / KU / TR)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<String>(
              future: LanguageService.translateDynamic(localizedTitle),
              initialData: localizedTitle,
              builder: (context, snapshot) => Text(
                snapshot.data ?? localizedTitle,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. STATUS BAR & CONTROLS (Switches between Normal Bid Stepper and Winning State)
          if (_isWinning) ...[
            // 4A. WINNING STATE: 2-PANEL TOP (Time Left | Your Max Bid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Time Left Pill Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 24, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
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
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
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

                  const SizedBox(width: 10),

                  // Your Max Bid Pill Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0F2FE)),
                      ),
                      child: Row(
                        children: [
                          Transform.rotate(
                            angle: -0.4,
                            child: const Icon(Icons.label_rounded, size: 24, color: Color(0xFF0369A1)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'أقصى مزايدة لك' : 'Your Max Bid',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${(_userMaxBid ?? currentBidVal.toDouble()).toInt()}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
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
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4B. ANIMATED CELEBRATION WINNING BANNER (Trophy + Confetti + Pulse)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: _winningAnimController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _glowPulseAnim.value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFDCFCE7),
                            Color(0xFFF0FDF4),
                            Color(0xFFDCFCE7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF86EFAC),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bouncing & Scaling Trophy Badge with Confetti Rays
                          ScaleTransition(
                            scale: _trophyScaleAnim,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Subtle celebration radiant glow
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF22C55E).withOpacity(0.12),
                                  ),
                                ),
                                // Confetti sparkle dots
                                Positioned(
                                  top: 2,
                                  left: 4,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEAB308),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 6,
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 3,
                                  child: Container(
                                    width: 3.5,
                                    height: 3.5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 28,
                                  color: Color(0xFF15803D),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Text Info: "Winning!" & "You are currently the highest bidder."
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'أنت الفائز حالياً!' : 'Winning!',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isArabic
                                      ? 'أنت حالياً صاحب أعلى مزايدة لهذا المنتج.'
                                      : 'You are currently the highest bidder.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
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

            const SizedBox(height: 12),

            // 4C. DISABLED / GREYED OUT "Place Bid" BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'أنت صاحب أعلى مزايدة بالفعل!'
                              : 'You are already the highest bidder!',
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gavel_rounded, size: 19, color: Colors.white70),
                  label: Text(
                    isArabic ? 'تقديم المزايدة' : 'Place Bid',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCBD5E1),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // 4. CLEAN 2-PANEL TOP ROW: (Time Left | Current Bid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 1. Time Left Pill Card (Horizontal clean card)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 22, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'الوقت المتبقي' : 'Time Left',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formattedTime,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
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

                  const SizedBox(width: 12),

                  // 2. Current Bid Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gavel_rounded, size: 22, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'أعلى مزايدة' : 'Current Bid',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$$currentBidVal',
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
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

            const SizedBox(height: 10),

            // FULL-WIDTH HORIZONTAL "Your Bid Amount" STEPPER ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Column(
                  children: [
                    Text(
                      isArabic ? 'مبلغ مزايدتك' : 'Your Bid Amount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus Button
                        GestureDetector(
                          onTap: _decrementBid,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: const Center(
                              child: Icon(Icons.remove, size: 18, color: Color(0xFFF97316)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),

                        // Stepper Value
                        Text(
                          '\$$_bidAmount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(width: 18),

                        // Plus Button
                        GestureDetector(
                          onTap: _incrementBid,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, size: 18, color: Color(0xFFF97316)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 5. PRIMARY ACTIVE ACTION BUTTON ("Place Bid")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (isComingSoon || _isSubmittingBid) ? null : _handlePlaceBid,
                  icon: Icon(isComingSoon ? Icons.schedule_rounded : Icons.gavel_rounded, size: 19, color: Colors.white),
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
          ],

          const SizedBox(height: 10),

          // 6. SECONDARY ACTION BUTTON ("Buy Now $25")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: isComingSoon ? null : () => _showBuyNowModal(buyNowPrice, isArabic),
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

          const SizedBox(height: 12),

          // 6.1 WINNER CARD & BIDDERS / BIDS METRICS (Client Feature matching Screenshots 1 & 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Winner Row Card (Light Mint Green with Trophy and Down Chevron)
                InkWell(
                  onTap: () => _showBiddersListModal(context, isArabic),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Light Mint Green
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFF1B5E20), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'الفائز: ' : 'Winner: ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            (p.highestBidderName != null && p.highestBidderName!.trim().isNotEmpty)
                                ? p.highestBidderName!
                                : (_productBids.isNotEmpty && _productBids.first.bidderName != null)
                                    ? _productBids.first.bidderName!
                                    : (isArabic ? 'لا يوجد مزايدين حتى الآن' : 'No bidders yet'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 2 Stat Badges: Bidders count & Bids count
                Row(
                  children: [
                    // Bidders Count
                    Expanded(
                      child: InkWell(
                        onTap: () => _showBiddersListModal(context, isArabic),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFF1E293B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    isArabic ? 'المزايدين' : 'Bidders',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_uniqueBiddersCount > 0 ? _uniqueBiddersCount : (p.highestBidderName != null ? 1 : 0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Total Bids Count
                    Expanded(
                      child: InkWell(
                        onTap: () => _showBiddersListModal(context, isArabic),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.gavel_outlined, size: 16, color: Color(0xFF1E293B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    isArabic ? 'المزايدات' : 'Bids',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_productBids.isNotEmpty ? _productBids.length : (p.totalBids ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                                  isArabic ? 'رقم المنتج / الباركود' : 'Item Barcode',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                                Text(
                                  (p.originalBarcode != null && p.originalBarcode!.isNotEmpty)
                                      ? p.originalBarcode!
                                      : 'IQB-${p.id.toString().padLeft(6, '0')}',
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
              (p.description != null && p.description!.trim().isNotEmpty)
                  ? p.description!.trim()
                  : (isArabic
                      ? 'لا يوجد وصف إضافي متوفر لهذا المنتج حالياً.'
                      : 'No additional description provided for this item.'),
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

          // Warning Section:
          // Always shown! If product has defects/notes from admin -> Red Warning icon with defect details.
          // If no defects/problems -> Black/neutral icon with "No defects found" message.
          Builder(
            builder: (context) {
              final hasDefect = p.defectAlert || (p.defectDetails != null && p.defectDetails!.trim().isNotEmpty);
              return _buildExpandableTile(
                icon: Icons.warning_amber_rounded,
                iconColor: hasDefect ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                title: isArabic ? 'تحذير' : 'Warning',
                isExpanded: _isWarningExpanded,
                onTap: () {
                  setState(() => _isWarningExpanded = !_isWarningExpanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDefect
                          ? ((p.defectDetails != null && p.defectDetails!.trim().isNotEmpty)
                              ? p.defectDetails!.trim()
                              : (isArabic
                                  ? 'تم الإبلاغ عن وجود ملاحظات أو عيوب في هذا المنتج من قبل الإدارة.'
                                  : 'This product has reported defects or inspection notes recorded by administration.'))
                          : (isArabic
                              ? 'لا توجد أي عيوب أو مشاكل في هذا المنتج. المنتج تم فحصه وبحالة ممتازة.'
                              : 'No defects, issues, or warnings for this product. Fully inspected and in great condition.'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasDefect ? FontWeight.w600 : FontWeight.w500,
                        color: hasDefect ? const Color(0xFFDC2626) : const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    if (hasDefect && p.defectImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: p.defectImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.defectImages[idx],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
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

  void _showBuyNowModal(int buyNowPrice, bool isArabic) {
    if (!_isLoggedIn) {
      context.push('/auth');
      return;
    }

    bool isSubmitting = false;
    final TextEditingController couponController = TextEditingController();
    String? appliedCouponCode;
    double discountAmount = 0.0;
    double finalPrice = buyNowPrice.toDouble();
    bool isValidatingCoupon = false;
    String? couponMessage;
    bool couponSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'تأكيد الشراء الفوري' : 'Confirm Buy Now',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    if (_product?.imageUrl != null && _product!.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: _product!.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _product?.title ?? 'Product',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                isArabic ? 'سعر الشراء الفوري: ' : 'Buy Now Price: ',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
                              ),
                              if (discountAmount > 0) ...[
                                Text(
                                  '\$$buyNowPrice',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '\$${finalPrice.toStringAsFixed(finalPrice.truncateToDouble() == finalPrice ? 0 : 2)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                                ),
                              ] else ...[
                                Text(
                                  '\$$buyNowPrice',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Coupon Code Input Field Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: couponSuccess ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? 'كوبون الخصم للمؤثرين' : 'Influencer Discount Coupon',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponController,
                            textCapitalization: TextCapitalization.characters,
                            enabled: appliedCouponCode == null,
                            decoration: InputDecoration(
                              hintText: isArabic ? 'أدخل كود الكوبون (مثال: AHMED10)' : 'Enter coupon code (e.g. AHMED10)',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (appliedCouponCode == null)
                          ElevatedButton(
                            onPressed: isValidatingCoupon
                                ? null
                                : () async {
                                    final code = couponController.text.trim();
                                    if (code.isEmpty) return;
                                    setModalState(() {
                                      isValidatingCoupon = true;
                                      couponMessage = null;
                                    });
                                    try {
                                      final vRes = await apiService.validateCoupon(
                                        couponCode: code,
                                        amount: buyNowPrice.toDouble(),
                                        productId: int.tryParse(widget.productId) ?? (_product?.id ?? 0),
                                      );
                                      if (vRes['success'] == true) {
                                        final data = vRes['data'] as Map<String, dynamic>;
                                        final disc = (data['discount_amount'] as num).toDouble();
                                        final fin = (data['final_amount'] as num).toDouble();
                                        setModalState(() {
                                          appliedCouponCode = code;
                                          discountAmount = disc;
                                          finalPrice = fin;
                                          couponSuccess = true;
                                          couponMessage = isArabic
                                              ? 'تم تطبيق خصم $disc\$ بنجاح!'
                                              : 'Coupon applied! Saved \$$disc';
                                          isValidatingCoupon = false;
                                        });
                                      } else {
                                        setModalState(() {
                                          couponSuccess = false;
                                          couponMessage = vRes['message'] ?? 'Invalid coupon code';
                                          isValidatingCoupon = false;
                                        });
                                      }
                                    } catch (e) {
                                      setModalState(() {
                                        couponSuccess = false;
                                        couponMessage = e.toString().replaceAll('Exception: ', '');
                                        isValidatingCoupon = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: isValidatingCoupon
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(isArabic ? 'تطبيق' : 'Apply', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          )
                        else
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                appliedCouponCode = null;
                                discountAmount = 0.0;
                                finalPrice = buyNowPrice.toDouble();
                                couponController.clear();
                                couponMessage = null;
                                couponSuccess = false;
                              });
                            },
                            child: Text(isArabic ? 'إزالة' : 'Remove', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    if (couponMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        couponMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: couponSuccess ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Confirmation Prompt Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, size: 22, color: Color(0xFF0284C7)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'هل أنت متأكد من رغبتك في شراء هذا المنتج فوراً بسعر \$${finalPrice.toStringAsFixed(finalPrice.truncateToDouble() == finalPrice ? 0 : 2)}؟ سيتم التواصل معك لتأكيد موعد التوصيل.'
                            : 'Are you sure you want to buy this item now for \$${finalPrice.toStringAsFixed(finalPrice.truncateToDouble() == finalPrice ? 0 : 2)}? Delivery will be confirmed with you shortly.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Confirm or Reject
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        isArabic ? 'إلغاء' : 'Reject / Cancel',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                final res = await apiService.buyNow(
                                  productId: int.tryParse(widget.productId) ?? (_product?.id ?? 0),
                                  couponCode: appliedCouponCode,
                                );
                                if (mounted) Navigator.pop(ctx);
                                HapticFeedback.heavyImpact();
                                _showBuyNowSuccessDialog(res['data']?['orderNumber'] ?? 'Confirmed', isArabic);
                                _loadProductData();
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isArabic ? 'تأكيد الشراء' : 'Confirm Purchase',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuyNowSuccessDialog(String orderNumber, bool isArabic) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(
              isArabic ? 'تم تأكيد طلبك بنجاح!' : 'Order Placed Successfully!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'رقم الطلب: $orderNumber\nتم إرسال تفاصيل الشراء إلى قسم التوصيل وسنتواصل معك قريباً.'
                  : 'Order #: $orderNumber\nYour purchase is confirmed. Our delivery team will contact you shortly.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dlgCtx).pop();
                  if (mounted) {
                    context.go('/wins');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isArabic ? 'عرض طلباتي وفوزي' : 'View My Orders & Wins',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BIDDERS LIST BOTTOM SHEET (Screenshot 2 Pixel-Perfect) ---
  void _showBiddersListModal(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row: Icon + "Bidders List" + Close (X)
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 22, color: Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'قائمة المزايدين' : 'Bidders List',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(bottomSheetCtx),
                    icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bidders items list
              if (_productBids.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      const Icon(Icons.gavel_rounded, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? 'لا توجد مزايدات سابقة حتى الآن' : 'No bids placed yet',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _productBids.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (c, index) {
                      final bid = _productBids[index];
                      final isFirst = index == 0; // Highest bidder
                      final formattedDate = '${bid.createdAt.year}-${bid.createdAt.month.toString().padLeft(2, '0')}-${bid.createdAt.day.toString().padLeft(2, '0')} ${bid.createdAt.hour.toString().padLeft(2, '0')}:${bid.createdAt.minute.toString().padLeft(2, '0')}';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isFirst ? const Color(0xFFE8F5E9) : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirst ? const Color(0xFFC8E6C9) : const Color(0xFFF1F5F9),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Bid Price (Bold Left)
                            SizedBox(
                              width: 60,
                              child: Text(
                                '\$${bid.amount.toInt()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),

                            // Middle: Bidder Name + Date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isFirst) ...[
                                        const Icon(Icons.emoji_events_rounded, color: Color(0xFF1B5E20), size: 16),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          bid.bidderName ?? (isArabic ? 'مزايد' : 'Bidder'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
                                            color: isFirst ? const Color(0xFF1B5E20) : const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isFirst ? const Color(0xFF388E3C) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right: Blue Circle Gavel Icon Badge
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0284C7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.gavel_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
