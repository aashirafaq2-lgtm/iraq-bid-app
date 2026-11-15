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

                        const SizedBox(height: 18),

                        // 6. Section Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_products.length} ${isArabic ? "مزاد" : "Auctions"}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
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

  // --- DUAL HERO ACTION CARDS ("Company Product" & "Live Sales") ---
  Widget _buildDualActionCards(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Company Product Card (Peach/Amber Tint)
          Expanded(
            child: GestureDetector(
              onTap: () {
                _searchController.clear();
                _onCategorySelected('Luxury');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic ? 'عرض منتجات الشركة الموثقة' : 'Filtering Verified Company Products',
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFFEA580C),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: Color(0xFFEA580C), size: 19),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'منتجات\nالشركة' : 'Company\nProduct',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9A3412),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Icon(
                      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 18,
                      color: const Color(0xFFEA580C),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. Live Sales Hot Card (Pink/Red Tint)
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.push('/live-sales');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE4E6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFFE11D48), size: 21),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? 'تخفيضات\nحصرية' : 'Live\nSales',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBE123C),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Icon(
                      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 18,
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
