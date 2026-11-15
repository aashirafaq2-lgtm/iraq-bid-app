import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../models/product_model.dart';
import '../utils/image_url_helper.dart';
import '../widgets/luxury_product_card.dart';
import '../widgets/luxury_banner_carousel.dart';
import '../widgets/bottom_nav_bar.dart';

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────────────
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _contentFade;

  // ── State ──────────────────────────────────────────────────────────────────
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<String> _categories = ['All'];
  bool _categoriesLoaded = false;
  final ScrollController _scrollController = ScrollController();
  bool _searchFocused = false;
  final FocusNode _searchFocus = FocusNode();

  static const double _kRate = 1520;

  double get rate => _kRate;

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);

    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });

    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadProducts();

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300),
        () => _contentController.forward());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadCategories() async {
    if (_categoriesLoaded) return;
    try {
      final categories = await apiService.getAllCategories();
      final categoryNames = categories
          .map((cat) => cat['name'] as String)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      setState(() {
        _categories = ['All', ...categoryNames];
        _categoriesLoaded = true;
      });
    } catch (_) {}
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _products = [];
        _hasMore = true;
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await apiService.getAllProducts(
        category:
            _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        page: _currentPage,
        limit: 20,
      );

      final newProducts = result['products'] as List<ProductModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final now = DateTime.now();
      final active = newProducts.where((p) {
        if (p.auctionEndTime == null) return true;
        return p.auctionEndTime!.isAfter(now);
      }).toList();

      setState(() {
        if (reset || _currentPage == 1) {
          _products = active;
        } else {
          _products.addAll(active);
        }
        _currentPage = pagination['page'] as int;
        _hasMore = _currentPage < (pagination['pages'] as int);
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadProducts();
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    _loadProducts(reset: true);
  }

  void _onSearchSubmit(String _) {
    _loadProducts(reset: true);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, _, __) {
        return Directionality(
          textDirection:
              _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (ctx, inner) =>
                  [_buildSliverHeader(inner)],
              body: _buildBody(),
            ),
          ),
        );
      },
    );
  }

  // ── Sliver Header ──────────────────────────────────────────────────────────
  Widget _buildSliverHeader(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('Discover', 'اكتشف'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '${_products.length} ${_t('live auctions', 'مزاد مباشر')}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(204),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _TopBtn(
                                icon: Icons.notifications_outlined,
                                onTap: () => context.push('/notifications'),
                              ),
                              const SizedBox(width: 8),
                              _TopBtn(
                                icon: Icons.person_outline_rounded,
                                onTap: () => context.push('/profile'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ── Search Bar ──
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _searchFocused
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7)
                                        .withAlpha(51),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onSubmitted: _onSearchSubmit,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText: _t(
                                'Search products...', 'ابحث عن منتجات...'),
                            hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Color(0xFF64748B), size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: Color(0xFF64748B), size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadProducts(reset: true);
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return FadeTransition(
      opacity: _contentFade,
      child: RefreshIndicator(
        color: const Color(0xFF0284C7),
        onRefresh: () => _loadProducts(reset: true),
        child: CustomScrollView(
          slivers: [
            // Category Pills
            SliverToBoxAdapter(child: _buildCategoryPills()),
            // Banner Carousel
            const SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LuxuryBannerCarousel(),
            )),
            // Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'All'
                          ? _t('Live Auctions', 'المزادات المباشرة')
                          : _selectedCategory,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_products.length} ${_t('items', 'عنصر')}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
            // Products Grid or states
            if (_isLoading && _products.isEmpty)
              const SliverFillRemaining(child: _LoadingGrid())
            else if (_errorMessage != null && _products.isEmpty)
              SliverFillRemaining(
                  child: _ErrorState(
                error: _errorMessage!,
                onRetry: () => _loadProducts(reset: true),
                isArabic: _isArabic,
              ))
            else if (_products.isEmpty)
              SliverFillRemaining(
                  child: _EmptyState(isArabic: _isArabic))
            else
              _buildProductGrid(),
            // Load more indicator
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0284C7)),
                    ),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onCategorySelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0284C7)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withAlpha(51),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  cat == 'All' ? _t('All', 'الكل') : cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _products[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration:
                  Duration(milliseconds: 350 + (index % 8) * 50),
              curve: Curves.easeOut,
              builder: (ctx, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                    offset: Offset(0, 20 * (1 - v)), child: child),
              ),
              child: LuxuryProductCard(
                id: product.id.toString(),
                title: product.title,
                imageUrl: ImageUrlHelper.fixImageUrl(product.imageUrl ?? ''),
                currentBid: (product.currentBid ?? product.currentPrice ?? product.startingPrice).round(),
                totalBids: product.totalBids ?? 0,
                endTime: product.auctionEndTime ??
                    DateTime.now().add(const Duration(hours: 24)),
                category: product.categoryName,
                onTap: () =>
                    context.push('/product/${product.id}'),
              ),
            );
          },
          childCount: _products.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }
}

// ── Top Icon Button ────────────────────────────────────────────────────────

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withAlpha(77)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Loading Grid ───────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_anim),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isArabic;

  const _ErrorState(
      {required this.error,
      required this.onRetry,
      required this.isArabic});

  String _t(String en, String ar) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _t('Connection Error', 'خطأ في الاتصال'),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_t('Try Again', 'حاول مرة أخرى')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isArabic;

  const _EmptyState({required this.isArabic});

  String _t(String en, String ar) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.search_off_rounded,
                  color: Color(0xFF0284C7), size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              _t('No Products Found', 'لا توجد منتجات'),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                'Try a different category or search term.',
                'جرب فئة أو مصطلح بحث مختلف.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
