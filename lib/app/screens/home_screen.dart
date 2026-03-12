import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../services/app_localizations.dart';
import '../services/storage_service.dart';
import '../theme/colors.dart';
import '../utils/rtl_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoryKey = GlobalKey();
  
  // Separate product lists for company and seller products
  List<ProductModel> _companyProducts = [];
  List<ProductModel> _sellerProducts = [];
  
  bool _isLoadingCompany = true;
  bool _isLoadingSeller = true;
  String? _errorMessage;
  String? _currentUserRole;

  // Categories loaded from API
  List<String> _categories = ['All'];
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole().then((_) {
      if (mounted) _loadProducts();
    });
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUserRole() async {
    final role = await StorageService.getUserRole();
    setState(() {
      _currentUserRole = role ?? 'company_products';
    });
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
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  String _lastSearchQuery = '';
  
  void _onSearchChanged() {
    final currentQuery = _searchController.text.trim();
    if (currentQuery != _lastSearchQuery) {
      _lastSearchQuery = currentQuery;
      Future.delayed(const Duration(milliseconds: 500), () {
        final finalQuery = _searchController.text.trim();
        if (finalQuery == currentQuery) {
          _lastSearchQuery = finalQuery;
          _loadProducts(reset: true);
        }
      });
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (!mounted) return;
    
    final isCompany = _currentUserRole != 'seller_products';
    
    if (reset) {
      setState(() {
        if (isCompany) {
          _companyProducts = [];
        } else {
          _sellerProducts = [];
        }
      });
    }

    setState(() {
      if (isCompany) {
        _isLoadingCompany = true;
      } else {
        _isLoadingSeller = true;
      }
      _errorMessage = null;
    });

    final searchQuery = _searchController.text.trim();

    try {
      if (isCompany) {
        final result = await apiService.getCompanyProducts(
          category: _selectedCategory == 'All' ? null : _selectedCategory,
          search: searchQuery.isEmpty ? null : searchQuery,
          page: 1,
          limit: 20,
        );
        if (mounted) {
          setState(() {
            _companyProducts = result['products'] as List<ProductModel>;
            _isLoadingCompany = false;
          });
        }
      } else {
        final result = await apiService.getSellerProducts(
          category: _selectedCategory == 'All' ? null : _selectedCategory,
          search: searchQuery.isEmpty ? null : searchQuery,
          page: 1,
          limit: 20,
        );
        if (mounted) {
          setState(() {
            _sellerProducts = result['products'] as List<ProductModel>;
            _isLoadingSeller = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isCompany) _isLoadingCompany = false;
          else _isLoadingSeller = false;
          _errorMessage = e.toString();
        });
      }
      debugPrint('Error loading products: $e');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
      _loadProducts(reset: true);
    }
  }

  Widget _buildShimmerGrid() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Shimmer.fromColors(
                baseColor: isDark ? AppColors.slate800 : AppColors.slate100,
                highlightColor: isDark ? AppColors.slate700 : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 14, width: 120, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 18, width: 60, color: Colors.white),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(height: 24, width: 70, color: Colors.white),
                              Container(height: 20, width: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => Directionality(
            textDirection: RTLHelper.getTextDirection(context),
            child: AlertDialog(
              title: Text(AppLocalizations.of(context)?.exitApp ?? 'Exit App'),
              content: Text(AppLocalizations.of(context)?.exitAppMessage ?? 'Do you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(AppLocalizations.of(context)?.exit ?? 'Exit'),
                ),
              ],
            ),
          ),
        );
        
        if (shouldExit == true && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Directionality(
        textDirection: RTLHelper.getTextDirection(context),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          drawer: RTLHelper.isRTL(context) ? null : const AppDrawer(),
          endDrawer: RTLHelper.isRTL(context) ? const AppDrawer() : null,
          drawerEdgeDragWidth: MediaQuery.of(context).size.width,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _loadProducts(reset: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top Header
                  SliverToBoxAdapter(
                    child: HomeHeader(
                      searchController: _searchController,
                      onSearchSubmitted: () => _loadProducts(reset: true),
                      onSellerStatsPressed: () {
                        context.go('/seller-dashboard');
                      },
                      onRoleChanged: () async {
                        await _loadUserRole();
                        await _loadProducts(reset: true);
                      },
                    ),
                  ),
                  
                  // Banner Carousel
                  const SliverToBoxAdapter(
                    child: BannerCarousel(),
                  ),
                  
                  // Category Chips
                  SliverToBoxAdapter(
                    child: CategoryChips(
                      key: _categoryKey,
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: _onCategorySelected,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  
                  // Dynamic Products Grid Section
                  Builder(
                    builder: (context) {
                      final isCompany = _currentUserRole != 'seller_products';
                      final activeProducts = isCompany ? _companyProducts : _sellerProducts;
                      final isLoading = isCompany ? _isLoadingCompany : _isLoadingSeller;
                      final emptyMessage = isCompany 
                          ? (AppLocalizations.of(context)?.noCompanyProducts ?? 'No company products available')
                          : (AppLocalizations.of(context)?.noSellerProducts ?? 'No seller products yet');

                      if (isLoading) {
                        return _buildShimmerGrid();
                      }
                      
                      if (activeProducts.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            height: 300,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  emptyMessage,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = activeProducts[index];
                              final imageUrls = product.imageUrls;
                              final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
                              
                              return ProductCard(
                                id: product.id.toString(),
                                title: product.title,
                                imageUrl: imageUrl ?? '',
                                currentBid: (product.currentBid ?? product.startingBid ?? product.startingPrice).toInt(),
                                totalBids: product.totalBids ?? 0,
                                endTime: product.auctionEndTime ?? DateTime.now().add(const Duration(days: 1)),
                                category: product.categoryName,
                                onTap: () {
                                  context.go('/product-details/${product.id}');
                                },
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
                            },
                            childCount: activeProducts.length,
                          ),
                        ),
                      );
                    }
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
