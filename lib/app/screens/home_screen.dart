import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/fcm_notification_service.dart';
import '../models/product_model.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/luxury_banner_carousel.dart';
import '../widgets/luxury_product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin<HomeScreen> {
  @override
  bool get wantKeepAlive => true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  Timer? _searchDebounce;
  int _gridColumns = 3; // 3 = 3-in-line (default), 2 = 2-in-line, 1 = 1-in-line

  // In-memory cache for ultra-fast instant UI rendering
  static final Map<String, List<ProductModel>> _categoryCache = {};

  // Ultra-crisp category tabs matching the reference UI exactly
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'name_ar': 'الكل', 'name_ku': 'هەموو', 'name_tr': 'Tümü', 'icon': Icons.grid_view_rounded},
    {'name': 'Luxury', 'name_ar': 'فاخر', 'name_ku': 'شاهانە', 'name_tr': 'Lüks', 'icon': Icons.workspace_premium_outlined},
    {'name': 'Shoes', 'name_ar': 'أحذية', 'name_ku': 'پێڵاو', 'name_tr': 'Ayakkabı', 'icon': Icons.directions_run_rounded},
    {'name': 'Electronics', 'name_ar': 'إلكترونيات', 'name_ku': 'ئەلیکترۆنیات', 'name_tr': 'Elektronik', 'icon': Icons.devices_other_rounded},
    {'name': 'Fashion', 'name_ar': 'أزياء', 'name_ku': 'فاشن', 'name_tr': 'Moda', 'icon': Icons.checkroom_outlined},
    {'name': 'Home', 'name_ar': 'المنزل', 'name_ku': 'ماڵەوە', 'name_tr': 'Ev', 'icon': Icons.chair_outlined},
    {'name': 'Watches', 'name_ar': 'ساعات', 'name_ku': 'کاتژمێر', 'name_tr': 'Saatler', 'icon': Icons.watch_outlined},
    {'name': 'Mobiles', 'name_ar': 'موبايل', 'name_ku': 'مۆبایل', 'name_tr': 'Telefonlar', 'icon': Icons.smartphone_rounded},
    {'name': 'Gaming', 'name_ar': 'ألعاب', 'name_ku': 'یاری', 'name_tr': 'Oyun', 'icon': Icons.sports_esports_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmNotificationService().requestPermissionAndSyncToken();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadProducts(reset: true);
    });
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (!mounted) return;
    final cacheKey = '${_selectedCategory}_${_searchController.text.trim()}';

    // Instant show from cache if available so screen loads immediately
    if (_categoryCache.containsKey(cacheKey) && _categoryCache[cacheKey]!.isNotEmpty) {
      setState(() {
        _products = _categoryCache[cacheKey]!;
        _isLoading = false;
      });
    } else if (_products.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final responseMap = await apiService.getAllProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        limit: 50,
      );

      final List<ProductModel> items = responseMap['products'] as List<ProductModel>? ?? [];

      if (mounted) {
        _categoryCache[cacheKey] = items;
        setState(() {
          _products = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(String categoryName) {
    if (_selectedCategory != categoryName) {
      setState(() {
        _selectedCategory = categoryName;
      });
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isArabic = LanguageService.isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const AppDrawer(),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Floating Clean Top Header (Search Bar, Bell, Headphone Support)
              _buildTopHeader(isArabic),

              // 2. Main Scrollable Discovery Canvas
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0284C7),
                  onRefresh: () async => _loadProducts(reset: true),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // 3. Dual Hero Action Cards ("Company Product" & "Live Sales")
                        _buildDualActionCards(isArabic),

                        const SizedBox(height: 14),

                        // 4. Horizontal Scrolling Category Pills
                        _buildCategoryPills(isArabic),

                        const SizedBox(height: 14),

                        // 5. 5-Slide 3D Luxury Deals Banner Carousel
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: RepaintBoundary(child: LuxuryBannerCarousel()),
                        ),

                        const SizedBox(height: 18),

                        // 6. Section Header with View Layout Switcher (3-grid, 2-grid, 1-grid)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 3.5,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                LanguageService.tr(
                                  'Live Auction Catalog',
                                  'المزادات الحية الحالية',
                                  'لیستی مەزادی زیندوو',
                                  'Canlı Açık Artırma Kataloğu',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const Spacer(),
                              // Layout Selector [ 3 | 2 | 1 ]
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLayoutButton(columns: 3, icon: Icons.grid_on_rounded),
                                    _buildLayoutButton(columns: 2, icon: Icons.grid_view_rounded),
                                    _buildLayoutButton(columns: 1, icon: Icons.crop_square_rounded),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 7. Grid of Live Auction Cards
                        _buildProductGrid(isArabic),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TOP HEADER WIDGET ---
  Widget _buildTopHeader(bool isArabic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Notification Bell
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 22,
                    color: Color(0xFF0F172A),
                  ),
                  Positioned(
                    top: 10,
                    right: isArabic ? null : 11,
                    left: isArabic ? 11 : null,
                    child: Container(
                      width: 7,
                      height: 7,
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

          // Menu / Left Drawer Hamburger Icon
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  size: 22,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Central Search Input
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _loadProducts(reset: true),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: LanguageService.tr(
                          'Search for products...',
                          'ابحث عن منتجات...',
                          'بۆ بەرهەمەکان بگەڕێ...',
                          'Ürün ara...',
                        ),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _loadProducts(reset: true);
                                  setState(() {});
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 4-Language Quick Selector (English, Arabic, Kurdish, Turkish)
          PopupMenuButton<String>(
            onSelected: (lang) {
              LanguageService.setLanguage(lang);
              setState(() {});
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'English', child: Text('English')),
              PopupMenuItem(value: 'Arabic', child: Text('العربية (Arabic)')),
              PopupMenuItem(value: 'Kurdish', child: Text('کوردی (Kurdish)')),
              PopupMenuItem(value: 'Turkish', child: Text('Türkçe (Turkish)')),
            ],
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    LanguageService.tr('EN', 'عربي', 'کوردی', 'TR'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3 HERO ACTION CARDS ("Our Product", "Sellers", & "VIP Bidders") ---
  Widget _buildDualActionCards(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Our Product Card (Warm Cream Gradient)
          Expanded(
            child: GestureDetector(
              onTap: () {
                _searchController.clear();
                _onCategorySelected('All');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic ? 'عرض منتجاتنا المعتمدة' : 'Filtering Our Products',
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF1E3A8A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFEA580C),
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        LanguageService.tr('Our Product', 'منتجاتنا', 'بەرهەمەکانمان', 'Ürünlerimiz'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 16,
                      color: const Color(0xFF1E293B),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 2. Sellers Card (Soft Rose/Ruby Gradient)
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.push('/sellers');
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFFE11D48),
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isArabic ? 'البائعين' : 'Sellers',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE11D48),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 16,
                      color: const Color(0xFFE11D48),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 3. VIP Bidders Card (With "Coming Soon" badge)
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showVipComingSoonDialog(isArabic);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4C1D95), Color(0xFF2E1065)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'مزايدي VIP' : 'VIP Bidders',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isArabic ? 'قريباً' : 'Coming Soon',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                          size: 16,
                          color: const Color(0xFFFFD700),
                        ),
                      ],
                    ),
                  ),

                  // Floating "Coming Soon" Pill
                  Positioned(
                    top: -6,
                    right: isArabic ? null : 6,
                    left: isArabic ? 6 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        isArabic ? 'قريباً' : 'COMING SOON',
                        style: const TextStyle(
                          color: Color(0xFF1E0A3C),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showVipComingSoonDialog(bool isArabic) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0A3C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2E1065),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isArabic ? 'مزايدات VIP الحصرية' : 'VIP Bidders Arena',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isArabic ? 'قريباً في التحديث القادم' : 'COMING SOON IN NEXT UPDATE',
                style: const TextStyle(
                  color: Color(0xFF1E0A3C),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isArabic
                  ? 'يتم حالياً تطوير وتجهيز مزادات VIP الحصرية والحاويات الفاخرة بأحدث التقنيات التفاعلية ثلاثية الأبعاد. ستتوفر في التحديث القادم مباشرة!'
                  : 'Exclusive VIP Bidders Arena & Luxury Container Auctions are currently undergoing final upgrades and will be launched in the upcoming update. Stay tuned!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: Text(
                isArabic ? 'حسناً' : 'Got it',
                style: const TextStyle(color: Color(0xFF1E0A3C), fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HORIZONTAL CATEGORY PILLS ---
  Widget _buildCategoryPills(bool isArabic) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          final label = LanguageService.tr(
            cat['name'] as String,
            cat['name_ar'] as String,
            cat['name_ku'] as String,
            cat['name_tr'] as String,
          );

          return GestureDetector(
            onTap: () => _onCategorySelected(cat['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayoutButton({required int columns, required IconData icon}) {
    final isSelected = _gridColumns == columns;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _gridColumns = columns;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }

  // --- PRODUCT GRID WIDGET ---
  Widget _buildProductGrid(bool isArabic) {
    if (_isLoading) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Color(0xFF0284C7)),
      );
    }

    if (_products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              LanguageService.tr(
                'No active live auctions in this category',
                'لا توجد مزادات نشطة في هذا القسم حالياً',
                'هیچ مەزادێکی چالاک لەم بەشەدا نییە',
                'Bu kategoride aktif canlı açık artırma yok',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Dynamic aspect ratio & layout according to selected columns (3, 2, or 1)
    final double childAspectRatio;
    if (_gridColumns == 3) {
      childAspectRatio = 0.54;
    } else if (_gridColumns == 2) {
      childAspectRatio = 0.68;
    } else {
      childAspectRatio = 0.88; // 1-in-line card with Buy Now button
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        key: ValueKey('grid_layout_$_gridColumns'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridColumns,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: _gridColumns == 1 ? 0 : 8,
          mainAxisSpacing: 14,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final p = _products[index];
          final imgUrl = (p.imageUrl != null && p.imageUrl!.isNotEmpty)
              ? p.imageUrl!
              : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&q=80';

          return LuxuryProductCard(
            id: p.id.toString(),
            title: p.title,
            imageUrl: imgUrl,
            currentBid: (p.currentBid ?? p.startingPrice).toInt(),
            totalBids: p.totalBids ?? 0,
            endTime: p.auctionEndTime ?? DateTime.now().add(const Duration(hours: 24)),
            category: p.categoryName,
            specialDescription: p.specialDescription,
            isSingleColumn: _gridColumns == 1,
            status: p.status,
            onTap: () => context.push('/product-details/${p.id}'),
          );
        },
      ),
    );
  }
}
