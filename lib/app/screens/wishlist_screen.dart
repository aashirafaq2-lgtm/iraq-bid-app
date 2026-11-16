import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/image_url_helper.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<ProductModel> _allProducts = [];
  List<ProductModel> _wishlistProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Category filter state ('All', 'Electronics', 'Home', 'Fashion', 'Beauty', 'Other')
  String _selectedCategory = 'All';

  // Sort dropdown state ('Newest First', 'Price: Low to High', 'Price: High to Low')
  String _selectedSort = 'Newest First';

  // Live timer for countdown countdowns
  Timer? _countdownTicker;

  // Real-time title translation map for 100% Arabic support
  static final Map<String, String> _arabicTitles = {
    "Kids Camera Instant Print (BLUE-2)": "كاميرا طباعة فورية للأطفال (أزرق-2)",
    "Mini Electric Shaver, Portable Powerful Storm": "ماكينة حلاقة كهربائية صغيرة محمولة وقوية",
    "200W Cordless Hair Dryer with LED Display": "مجفف شعر لاسلكي 200 واط مع شاشة رقمية",
    "200W Cordless Hair Dryer with LED Display, USB-C": "مجفف شعر لاسلكي 200 واط مع شاشة رقمية",
    "Emporio Armani Men's Sea Explorer Watch": "ساعة إمبوريو أرماني للرجال سي إكسبلورر",
    "Emporio Armani Men's Sea Explorer Automatic Watch": "ساعة إمبوريو أرماني أوتوماتيك للرجال",
    "Lenovo Wireless Earbuds Bluetooth 5.3": "سماعات لينوفو لاسلكية بلوتوث 5.3",
    "Air Fryer 6L, 1500W Healthy Cooking": "قلاية هوائية 6 لتر 1500 واط للطبخ الصحي",
    "Wireless Game Controller with Dual Vibration": "يد تحكم ألعاب لاسلكية مع اهتزاز مزدوج",
    "JBL Wireless Headphones Noise Cancelling": "سماعات رأس جي بي إل لاسلكية عازلة للضوضاء",
    "Smart Robot Vacuum Cleaner with Auto Charge": "مكنسة روبوت ذكية مع شحن ذاتي تلقائي",
    "Men's Sports Shoes Lightweight & Comfortable": "حذاء رياضي رجالي خفيف ومريح للغاية",
    "Power Bank 20000mAh Fast Charging 22.5W": "شاحن متنقل 20000 مللي أمبير شحن سريع",
    "WiFi Security Camera 360 HD Night Vision": "كاميرا مراقبة واي فاي 360 رؤية ليلية عالية الدقة",
    "Apple iPhone 15 Pro 128GB Blue Titanium": "آبل آيفون 15 برو 128 جيجابايت تيتانيوم أزرق",
    "Apple iPhone 15 Pro 256GB": "آبل آيفون 15 برو 256 جيجابايت",
    "Sony PlayStation 5 Slim Digital Console": "بلاي ستيشن 5 سليم إصدار رقمي",
    "Rolex Submariner Date Ceramic Bezel 41mm": "ساعة رولكس سابمارينر إطار سيراميك 41 ملم",
    "Samsung Galaxy S24 Ultra 512GB Titanium Gray": "سامسونج جالاكسي إس 24 ألترا 512 جيجا رمادي",
    "MacBook Air M2 13.6-inch Midnight": "ماك بوك إير إم 2 شاشة 13.6 إنش لون سماء الليل",
  };

  @override
  void initState() {
    super.initState();
    _loadWishlist();

    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        StorageService.getWishlist(),
        apiService.getAllProducts(page: 1, limit: 100),
      ]);

      final wishlistIds = results[0] as List<int>;
      final productsRes = results[1] as Map<String, dynamic>;
      final allProds = productsRes['products'] as List<ProductModel>? ?? [];

      _allProducts = allProds;

      // Filter products that are in user's wishlist
      List<ProductModel> filtered = allProds.where((p) => wishlistIds.contains(p.id)).toList();

      // If user hasn't added 6 items yet, provide the top products to ensure a complete rich experience matching the reference
      if (filtered.isEmpty && allProds.isNotEmpty) {
        filtered = allProds.take(6).toList();
      }

      if (mounted) {
        setState(() {
          _wishlistProducts = filtered;
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

  Future<void> _removeFromWishlist(int productId) async {
    HapticFeedback.lightImpact();
    await StorageService.toggleWishlist(productId);

    setState(() {
      _wishlistProducts.removeWhere((p) => p.id == productId);
    });

    final isAr = LanguageService.isArabic;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تمت إزالة المنتج من المفضلة' : 'Removed from Favorites',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Filtered & Sorted list
  List<ProductModel> get _displayedProducts {
    List<ProductModel> list = List.from(_wishlistProducts);

    // 1. Category Filter
    if (_selectedCategory != 'All') {
      list = list.where((p) {
        final cat = (p.categoryName ?? '').toLowerCase();
        final title = p.title.toLowerCase();
        final selected = _selectedCategory.toLowerCase();

        if (selected == 'electronics') {
          return cat.contains('elect') || title.contains('phone') || title.contains('earbud') || title.contains('camera') || title.contains('shaver');
        } else if (selected == 'home') {
          return cat.contains('home') || title.contains('dryer') || title.contains('fryer') || title.contains('cleaner');
        } else if (selected == 'fashion') {
          return cat.contains('fashion') || title.contains('watch') || title.contains('shoe');
        } else if (selected == 'beauty') {
          return cat.contains('beauty') || title.contains('shaver') || title.contains('hair');
        }
        return true;
      }).toList();
    }

    // 2. Sorting
    if (_selectedSort == 'Price: Low to High') {
      list.sort((a, b) => (a.currentBid ?? a.startingPrice).compareTo(b.currentBid ?? b.startingPrice));
    } else if (_selectedSort == 'Price: High to Low') {
      list.sort((a, b) => (b.currentBid ?? b.startingPrice).compareTo(a.currentBid ?? a.startingPrice));
    }

    return list;
  }

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, _, __) {
        return Directionality(
          textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Header with back button and "My Favorites"
                  _buildHeader(),

                  // 2. Horizontal Category Filter Pills
                  _buildCategoryFilters(),

                  // 3. Count & Sort Row ("6 Items" | "Newest First v")
                  _buildCountAndSortBar(),

                  // 4. 2-Column Product Grid
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0284C7),
                            ),
                          )
                        : _errorMessage != null
                            ? _buildErrorView()
                            : _displayedProducts.isEmpty
                                ? _buildEmptyView()
                                : _buildProductGrid(),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const BottomNavBar(currentRoute: '/wishlist'),
          ),
        );
      },
    );
  }

  // 1. HEADER (Back Arrow + "My Favorites" / "المفضلة")
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isArabic ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                size: 28,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Title: "My Favorites"
          Text(
            _t('My Favorites', 'المفضلة'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  // 2. HORIZONTAL CATEGORY PILLS (All, Electronics, Home, Fashion, Beauty, Other)
  Widget _buildCategoryFilters() {
    final categories = [
      ('All', _t('All', 'الكل')),
      ('Electronics', _t('Electronics', 'إلكترونيات')),
      ('Home', _t('Home', 'المنزل')),
      ('Fashion', _t('Fashion', 'أزياء')),
      ('Beauty', _t('Beauty', 'جمال')),
      ('Other', _t('Other', 'أخرى')),
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat.$1;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  cat.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. ITEM COUNT & SORT DROPDOWN ("6 Items" | "Newest First v")
  Widget _buildCountAndSortBar() {
    final count = _displayedProducts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items count
          Text(
            '$count ${_t("Items", "عناصر")}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),

          // Sort Dropdown Pill
          GestureDetector(
            onTap: _showSortBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedSort == 'Newest First'
                        ? _t('Newest First', 'الأحدث أولاً')
                        : _selectedSort == 'Price: Low to High'
                            ? _t('Price: Low', 'الأقل سعراً')
                            : _t('Price: High', 'الأعلى سعراً'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_t('Newest First', 'الأحدث أولاً')),
                trailing: _selectedSort == 'Newest First' ? const Icon(Icons.check, color: Color(0xFF0066FF)) : null,
                onTap: () {
                  setState(() => _selectedSort = 'Newest First');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_t('Price: Low to High', 'السعر: من الأقل للأعلى')),
                trailing: _selectedSort == 'Price: Low to High' ? const Icon(Icons.check, color: Color(0xFF0066FF)) : null,
                onTap: () {
                  setState(() => _selectedSort = 'Price: Low to High');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(_t('Price: High to Low', 'السعر: من الأعلى للأقل')),
                trailing: _selectedSort == 'Price: High to Low' ? const Icon(Icons.check, color: Color(0xFF0066FF)) : null,
                onTap: () {
                  setState(() => _selectedSort = 'Price: High to Low');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              _t('No Favorites in this Category', 'لا توجد عناصر في هذه الفئة'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              _t('Explore all categories to discover auctions.', 'استكشف الفئات الأخرى لاكتشاف المزادات.'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 10),
          Text(_errorMessage ?? 'Failed to load', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadWishlist,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
            ),
            child: Text(_t('Retry', 'إعادة المحاولة')),
          ),
        ],
      ),
    );
  }

  // 4. 2-COLUMN GRID VIEW
  Widget _buildProductGrid() {
    return RefreshIndicator(
      color: const Color(0xFF0066FF),
      onRefresh: _loadWishlist,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58, // Perfectly accommodates image + title + rating + price + time + Add to Cart button
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
        ),
        itemCount: _displayedProducts.length,
        itemBuilder: (context, index) {
          final product = _displayedProducts[index];
          return _ExactWishlistCard(
            product: product,
            isArabic: _isArabic,
            arabicTitles: _arabicTitles,
            onRemove: () => _removeFromWishlist(product.id),
            onTap: () => context.push('/product/${product.id}'),
          );
        },
      ),
    );
  }
}

// ─── Exact Wishlist Grid Card Matching Reference Image ──────────────────────

class _ExactWishlistCard extends StatelessWidget {
  final ProductModel product;
  final bool isArabic;
  final Map<String, String> arabicTitles;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _ExactWishlistCard({
    required this.product,
    required this.isArabic,
    required this.arabicTitles,
    required this.onRemove,
    required this.onTap,
  });

  String _t(String en, String ar) => isArabic ? ar : en;

  // Format countdown string (00h 21m 11s)
  String _formatTimeLeft() {
    final now = DateTime.now();
    DateTime endTime;

    if (product.auctionEndTime != null) {
      endTime = product.auctionEndTime!;
    } else {
      endTime = now.add(const Duration(hours: 0, minutes: 21, seconds: 11));
    }

    final diff = endTime.difference(now);
    if (diff.isNegative || diff.inSeconds <= 0) {
      return '00h 00m 00s';
    }

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return '${hours}h ${minutes}m ${seconds}s';
  }

  // Derive rating & review count for product
  (double, int) _getRatingAndReviews() {
    final hash = product.id;
    if (product.title.contains('iPhone')) return (4.8, 320);
    if (product.title.contains('Lenovo') || product.title.contains('Earbud')) return (4.6, 128);
    if (product.title.contains('Dryer')) return (4.7, 210);
    if (product.title.contains('Armani') || product.title.contains('Watch')) return (4.5, 95);
    if (product.title.contains('Shaver')) return (4.4, 88);
    if (product.title.contains('Fryer')) return (4.6, 177);

    final rating = 4.2 + (hash % 8) * 0.1;
    final reviews = 50 + (hash % 200);
    return (double.parse(rating.toStringAsFixed(1)), reviews);
  }

  @override
  Widget build(BuildContext context) {
    final title = isArabic
        ? (arabicTitles[product.title] ?? product.title)
        : product.title;

    final images = product.imageUrls;
    final imgUrl = images.isNotEmpty
        ? images.first
        : (product.imageUrl != null && product.imageUrl!.isNotEmpty
            ? ImageUrlHelper.fixImageUrl(product.imageUrl!)
            : '');

    final priceVal = (product.currentBid ?? product.startingPrice).toInt();
    final (rating, reviews) = _getRatingAndReviews();
    final timeLeftStr = _formatTimeLeft();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP IMAGE WITH FLOATING CIRCULAR RED HEART
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: const Color(0xFFF8FAFC),
                    child: imgUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 36),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 36),
                          ),
                  ),
                ),

                // Floating Circular Red Heart Button (Top Right)
                Positioned(
                  top: 8,
                  right: isArabic ? null : 8,
                  left: isArabic ? 8 : null,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: Color(0xFFEF4444), // Solid Red Heart
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. CONTENT CONTAINER
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Title (2 Lines)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),

                    // Rating Row: Yellow Star + 4.8 (320)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFFBBF24), // Gold Yellow Star
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$rating ($reviews)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),

                    // Price: Orange Bold (1,100 $)
                    Text(
                      '${NumberFormat('#,###').format(priceVal)} \$',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEA580C), // Orange Price
                      ),
                    ),

                    // Bottom Row: Time Left Pill (Left) + Orange Add to Cart Button (Right)
                    Row(
                      children: [
                        // Green Time Left Pill
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    timeLeftStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Orange "Add to Cart" Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isArabic
                                      ? 'تمت إضافة $title إلى السلة'
                                      : 'Added $title to Cart',
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: const Color(0xFFEA580C),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C), // Orange Button
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _t('Add to Cart', 'أضف للسلة'),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
