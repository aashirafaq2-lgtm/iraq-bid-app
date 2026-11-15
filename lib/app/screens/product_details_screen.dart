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
  List<BidModel> _bids = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _userId;
  bool _isLoggedIn = false;
  final PageController _pageController = PageController();

  // Exchange rate: 1 USD = 1,520 IQD
  static const int usdToIqdRate = 1520;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProductData();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  bool _isSellerOfProduct() {
    if (_product == null || _userId == null) return false;
    return _product!.sellerId == _userId;
  }

  Future<void> _loadProductData() async {
    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) throw Exception('Invalid product ID');

      final results = await Future.wait([
        apiService.getProductById(productId),
        apiService.getBidsByProduct(productId),
        StorageService.isInWishlist(productId),
      ]);

      if (mounted) {
        setState(() {
          _product = results[0] as ProductModel;
          _bids = results[1] as List<BidModel>;
          _isLiked = results[2] as bool;
          _isLoading = false;
        });
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
    final shareMsg = "${_product!.title}\nPrice: \$$currentPrice\nIraq Bid Live Auction: https://iraqbid.net/product/${_product!.id}";
    await Share.share(shareMsg);
  }

  void _openBidSheet(BuildContext ctx, bool isArabic) async {
    if (!_isLoggedIn) {
      ctx.push('/auth');
      return;
    }
    if (_product?.status == 'pending') {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'هذا المنتج قيد المراجعة، ستبدأ المزايدة فور اعتماده.'
                : 'This product is pending review. Bidding opens once approved.',
          ),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }
    if (_isSellerOfProduct()) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'لا يمكنك المزايدة على منتجك الخاص.'
                : 'You cannot bid on your own listing.',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final currentBidVal = (_product!.currentBid ?? _product!.startingPrice).toInt();
    final pId = int.tryParse(widget.productId) ?? _product!.id;

    final result = await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => PlaceBidModal(
        currentBid: currentBidVal,
        productTitle: _product!.title,
        productId: pId,
      ),
    );

    if (result == true && mounted) {
      _loadProductData();
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
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFFFFF),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Text(
                isArabic ? 'تفاصيل المزاد' : 'Auction Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      size: 22, color: Color(0xFF0F172A)),
                  onPressed: _handleShare,
                ),
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 24,
                    color: _isLiked ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                  ),
                  onPressed: _toggleWishlist,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(isArabic),
            bottomNavigationBar: _product != null ? _buildBottomBar(isArabic) : null,
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isArabic) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0066FF),
        ),
      );
    }

    if (_errorMessage != null || _product == null) {
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

    final p = _product!;
    final images = p.imageUrls.isNotEmpty
        ? p.imageUrls
        : (p.imageUrl != null ? [p.imageUrl!] : <String>[]);
    final currentBidVal = (p.currentBid ?? p.startingPrice).toInt();
    final iqdVal = currentBidVal * usdToIqdRate;
    final formattedIqd = iqdVal.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. High-End Image Carousel
          _buildGallery(images),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Category Pill & Live Badge Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p.categoryName ?? (isArabic ? 'عام' : 'General'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isArabic ? 'مزاد نشط الآن' : 'LIVE AUCTION',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3. Product Title
                Text(
                  p.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Live Pricing & Countdown Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'أعلى مزايدة حالية' : 'CURRENT HIGHEST BID',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '\$$currentBidVal',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '≈ $formattedIqd IQD',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              _getTimeRemainingFormatted(p.auctionEndTime),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Product Key Spec Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.verified_rounded,
                        title: isArabic ? 'الحالة' : 'Condition',
                        value: p.condition ?? 'Like New',
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.gavel_rounded,
                        title: isArabic ? 'المزايدات' : 'Total Bids',
                        value: '${_bids.length}',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.security_rounded,
                        title: isArabic ? 'الضمان' : 'Warranty',
                        value: isArabic ? 'أصلي 100%' : '100% Legit',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 6. About This Item
                Text(
                  isArabic ? 'تفاصيل ومواصفات المنتج' : 'About This Item',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.description?.isNotEmpty == true
                      ? p.description!
                      : (isArabic
                          ? 'لا يوجد وصف مفصل لهذا المنتج حالياً. جميع البضائع تخضع للفحص الميكانيكي والفيزيائي قبل التسليم.'
                          : 'No detailed description provided. All items are authenticated and quality checked prior to dispatch.'),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 28),

                // 7. Recent Bidders Timeline Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'سجل المزايدات الأخيرة' : 'Recent Bid Activity',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_bids.length} ${isArabic ? 'مزايدة' : 'bids'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Recent Bids List
                if (_bids.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Text(
                        isArabic
                            ? 'كن أول من يفتتح المزاد على هذه السلعة!'
                            : 'Be the first to place a bid on this item!',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _bids.take(4).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final bid = _bids[index];
                      final isFirst = index == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isFirst ? const Color(0xFFEFF6FF) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirst ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isFirst
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  child: Icon(
                                    isFirst ? Icons.workspace_premium_rounded : Icons.person_rounded,
                                    size: 16,
                                    color: isFirst ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isFirst
                                          ? (isArabic ? 'أعلى مزايد حالياً' : 'Leading Bidder')
                                          : (isArabic ? 'مزايد معتمد' : 'Verified Bidder'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isFirst
                                            ? const Color(0xFF1E3A8A)
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                    Text(
                                      '${bid.createdAt.hour}:${bid.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '\$${bid.amount.toInt()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isFirst
                                    ? const Color(0xFF0066FF)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 120), // Spacing for bottom bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 320,
        color: const Color(0xFFF8FAFC),
        child: const Center(
          child: Icon(Icons.image_not_supported_rounded, size: 48, color: Color(0xFFCBD5E1)),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, err) => const Center(
                        child: Icon(Icons.image_not_supported_rounded, size: 40, color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: idx == _currentImageIndex ? 24 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: idx == _currentImageIndex
                      ? const Color(0xFF0066FF)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
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
    );
  }

  Widget _buildBottomBar(bool isArabic) {
    final currentBidVal = (_product!.currentBid ?? _product!.startingPrice).toInt();
    final nextBidVal = currentBidVal + 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Next Min Bid Info
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'الحد الأدنى القادم' : 'Next Minimum',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '\$$nextBidVal',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 18),

            // High-Impact CTA Button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _openBidSheet(context, isArabic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF0066FF).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gavel_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'زايد الآن' : 'Place Bid Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeRemainingFormatted(DateTime? endTime) {
    if (endTime == null) return '23h 59m';
    final now = DateTime.now();
    final diff = endTime.difference(now);
    if (diff.isNegative) return '00h 00m 00s';

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m ${seconds}s';
  }
}
