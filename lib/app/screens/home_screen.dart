import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  Timer? _searchDebounce;

  // Ultra-crisp category tabs matching the reference UI exactly
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'name_ar': 'الكل', 'icon': Icons.grid_view_rounded},
    {'name': 'Luxury', 'name_ar': 'فاخر', 'icon': Icons.workspace_premium_outlined},
    {'name': 'Shoes', 'name_ar': 'أحذية', 'icon': Icons.directions_run_rounded},
    {'name': 'Electronics', 'name_ar': 'إلكترونيات', 'icon': Icons.devices_other_rounded},
    {'name': 'Fashion', 'name_ar': 'أزياء', 'icon': Icons.checkroom_outlined},
    {'name': 'Home', 'name_ar': 'المنزل', 'icon': Icons.chair_outlined},
    {'name': 'Watches', 'name_ar': 'ساعات', 'icon': Icons.watch_outlined},
    {'name': 'Mobiles', 'name_ar': 'موبايل', 'icon': Icons.smartphone_rounded},
    {'name': 'Gaming', 'name_ar': 'ألعاب', 'icon': Icons.sports_esports_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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
    setState(() {
      _isLoading = true;
    });

    try {
      final responseMap = await apiService.getAllProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        limit: 50,
      );

      final List<ProductModel> items = responseMap['products'] as List<ProductModel>? ?? [];

      if (mounted) {
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
                          child: LuxuryBannerCarousel(),
                        ),

                        const SizedBox(height: 14),

                        // 5b. Dual Gamification Cards ("Lucky Wheel" & "Daily Challenge")
                        _buildGamificationFeatureCards(isArabic),

                        const SizedBox(height: 18),

                        // 6. Section Header
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
                                isArabic ? 'المزادات الحية الحالية' : 'Live Auction Catalog',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 7. Grid of Live Auction Cards (Matches 2-Column Reference Layout)
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
                        hintText: isArabic ? 'ابحث عن منتجات...' : 'Search for products...',
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

          // English / Arabic Quick Toggle Pill
          GestureDetector(
            onTap: () {
              final current = LanguageService.getLanguageName();
              final next = current == 'Arabic' ? 'English' : 'Arabic';
              LanguageService.setLanguage(next);
              setState(() {});
            },
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
                    isArabic ? 'EN' : 'عربي',
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

  // --- DUAL HERO ACTION CARDS ("Our Product" & "Sellers") ---
  Widget _buildDualActionCards(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Our Product Card (Luxury Warm Cream/Gold Gradient)
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                      color: const Color(0xFFF97316).withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFEA580C),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'منتجاتنا' : 'Our Product',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Icon(
                      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 20,
                      color: const Color(0xFF1E293B),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. Sellers Card (Soft Rose/Ruby Gradient)
          Expanded(
            child: GestureDetector(
              onTap: () {
                _searchController.clear();
                _onCategorySelected('All');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic ? 'عرض منتجات البائعين المعتمدين' : 'Filtering Sellers Marketplace',
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFFE11D48),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFFE11D48),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'البائعين' : 'Sellers',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE11D48),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Icon(
                      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 20,
                      color: const Color(0xFFE11D48),
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

  // --- DUAL GAMIFICATION CARDS ("Lucky Wheel" & "Daily Challenge") ---
  Widget _buildGamificationFeatureCards(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. LUCKY WHEEL CARD
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showGamificationDialog(
                  title: isArabic ? 'عجلة الحظ اليومية' : 'Lucky Wheel',
                  subtitle: isArabic
                      ? 'ميزة الأسبوع القادم: دوّر العجلة يومياً واربح رصيد مزايدة مجاني وهدايا حصرية!'
                      : 'Next Week Update: Spin daily & win free bid credit and exclusive gifts!',
                  icon: Icons.casino_rounded,
                  color: const Color(0xFFEA580C),
                );
              },
              child: Container(
                height: 105,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Wheel Visual Container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xFFEF4444),
                            Color(0xFFFFFFFF),
                            Color(0xFFEF4444),
                            Color(0xFFFFFFFF),
                            Color(0xFFEF4444),
                            Color(0xFFFFFFFF),
                            Color(0xFFEF4444),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFF59E0B), width: 2.5),
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.star_rounded, color: Colors.white, size: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Texts & Action Button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isArabic ? 'عجلة الحظ' : 'Lucky Wheel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic ? 'دوّر واربح رصيداً' : 'Spin Daily & Win Bid Credit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isArabic ? 'العب الآن >' : 'SPIN NOW >',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
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

          const SizedBox(width: 10),

          // 2. DAILY CHALLENGE CARD
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showGamificationDialog(
                  title: isArabic ? 'التحدي اليومي' : 'Daily Challenge',
                  subtitle: isArabic
                      ? 'ميزة الأسبوع القادم: ادعُ أصدقاءك وأكمل المهام لتربح جوائز وهواتف ذكية!'
                      : "Next Week Update: Invite more friends & win today's prize!",
                  icon: Icons.card_giftcard_rounded,
                  color: const Color(0xFF7C3AED),
                );
              },
              child: Container(
                height: 105,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
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
                    Row(
                      children: [
                        // Gift Visual Container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC084FC), Color(0xFF7C3AED)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Texts & Action Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isArabic ? 'التحدي اليومي' : 'Daily Challenge',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF5B21B6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isArabic ? 'شارك واربح اليوم' : "Win Today's Prize",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6D28D9),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isArabic ? 'انضم الآن >' : 'JOIN NOW >',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Top Right Floating "Daily Prize" Pill
                    Positioned(
                      top: 0,
                      right: isArabic ? null : 0,
                      left: isArabic ? 0 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wallet_giftcard_rounded, size: 8, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              isArabic ? 'هدية' : 'Daily Prize',
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
        ],
      ),
    );
  }

  void _showGamificationDialog({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  LanguageService.isArabic ? 'حسناً، فهمت' : 'Got it!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
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
          final label = isArabic ? cat['name_ar'] : cat['name'];

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
              isArabic ? 'لا توجد مزادات نشطة في هذا القسم حالياً' : 'No active live auctions in this category',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.54,
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
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
            onTap: () => context.push('/product-details/${p.id}'),
          );
        },
      ),
    );
  }
}
