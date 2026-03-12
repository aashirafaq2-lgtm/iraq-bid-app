import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/home_header.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/product_model.dart';
import '../utils/image_url_helper.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all'; // all, pending, approved, sold
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Categories loaded from API
  List<String> _categories = ['All'];
  bool _categoriesLoaded = false;
  bool _isLoadingMore = false;
  bool _loadMoreScheduled = false;
  int _currentPage = 1;
  bool _hasMore = true;

  List<StatData> get _stats {
    final activeProducts = _products.where((p) => p.status == 'approved').length;
    final pendingProducts = _products.where((p) => p.status == 'pending').length;

    // Simplified stats - removed Total Earnings and Total Bids
    // Seller dashboard is for listing management only, not analytics
    return [
      StatData(
        label: 'Active Listings',
        value: '$activeProducts',
        change: pendingProducts > 0 ? '$pendingProducts pending' : 'All active',
        icon: Icons.inventory_2_rounded,
        gradientColors: [AppColors.blue500, AppColors.blue600],
      ),
    ];
  }

  List<ProductModel> get _filteredListings {
    if (_selectedStatus == 'all') return _products;
    return _products.where((p) => p.status == _selectedStatus).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      
      if (kDebugMode) {
        print('📂 Seller Dashboard - Categories loaded: ${categoryNames.length}');
        print('   Categories: $categoryNames');
      }
      
      setState(() {
        _categories = ['All', ...categoryNames];
        _categoriesLoaded = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading categories in seller dashboard: $e');
      }
      // Keep 'All' as default even if loading fails
      setState(() {
        _categories = ['All'];
        _categoriesLoaded = true;
      });
    }
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _loadProducts(reset: true);
      }
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
      _loadProducts(reset: true);
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _products = [];
        _hasMore = true;
      });
    }

    if (_isLoadingMore) return;

    setState(() {
      if (!reset) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      // Get seller's products
      final products = await apiService.getMyProducts();
      
      // Apply filters client-side
      List<ProductModel> filteredProducts = products;
      
      // Filter by status
      if (_selectedStatus != 'all') {
        filteredProducts = filteredProducts.where((p) => p.status == _selectedStatus).toList();
      }
      
      // Filter by category
      if (_selectedCategory != 'All') {
        filteredProducts = filteredProducts.where((p) => p.categoryName == _selectedCategory).toList();
      }
      
      // Filter by search query (search in title, description, and category name)
      final searchQuery = _searchController.text.trim().toLowerCase();
      if (searchQuery.isNotEmpty) {
        filteredProducts = filteredProducts.where((p) {
          // Search in title
          if (p.title.toLowerCase().contains(searchQuery)) return true;
          // Search in description
          if (p.description?.toLowerCase().contains(searchQuery) ?? false) return true;
          // Search in category name
          if (p.categoryName?.toLowerCase().contains(searchQuery) ?? false) return true;
          return false;
        }).toList();
      }
      
      setState(() {
        if (reset) {
          _products = filteredProducts;
        } else {
          _products.addAll(filteredProducts);
        }
        _hasMore = false; // getMyProducts returns all products, no pagination
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading products: $e');
      }
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }

  Widget _buildStatusFilter(String status, String label) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue600 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blue600 : AppColors.slate300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.cardWhite : AppColors.slate600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showStatsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Dashboard Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_stats.isNotEmpty) _StatCard(stat: _stats.first),
                  const SizedBox(height: 24),
                  Text(
                    'Filter Listings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildModalFilterChip('all', 'All', setStateModal),
                        const SizedBox(width: 12),
                        _buildModalFilterChip('pending', 'Pending', setStateModal),
                        const SizedBox(width: 12),
                        _buildModalFilterChip('approved', 'Active', setStateModal),
                        const SizedBox(width: 12),
                        _buildModalFilterChip('sold', 'Sold', setStateModal),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/seller/analytics');
                      },
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: const Text('View Detailed Analytics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildModalFilterChip(String status, String label, StateSetter setStateModal) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        // Update parent screen
        setState(() {
          _selectedStatus = status;
        });
        // Update modal UI
        setStateModal(() {});
        
        // Close modal to show results immediately (User UX choice)
        // Or keep open? User said "shift" them there. 
        // Let's close it so they see the filtered list.
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue600 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.blue600 : AppColors.slate300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppColors.cardWhite : AppColors.slate600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Show confirmation dialog before exiting
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        
        if (shouldExit == true && context.mounted) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      // bottomNavigationBar: const BottomNavBar(), // Handled by ShellRoute
      body: SafeArea(
        child: Column(
          children: [
            // Top Header - Same as Home Screen with Back Button
            HomeHeader(
              searchController: _searchController,
              onSearchSubmitted: () => _loadProducts(reset: true),
              showBackButton: true,
              onSellerStatsPressed: _showStatsModal,
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadProducts(reset: true),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Carousel - Same as Home Screen
                      const BannerCarousel().animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack),

                      // Category Filter Chips - Same as Home Screen (Always visible)
                      // Always show CategoryChips - it handles empty state internally
                      CategoryChips(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        onCategorySelected: _onCategorySelected,
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

                      const SizedBox(height: 16),





                      // Products Grid - Same as Home Screen (2 columns)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isLoading && _products.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_errorMessage != null && _products.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Failed to load listings',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _errorMessage!,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => _loadProducts(reset: true),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_filteredListings.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.slate400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No listings found',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Create your first listing to get started',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          context.push('/product-create').then((result) {
                                            if (result == true) {
                                              _loadProducts(reset: true);
                                            }
                                          });
                                        },
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('Create Product'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.62,
                                ),
                                itemCount: _filteredListings.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredListings[index];
                                  final imageUrls = product.imageUrls;
                                  final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
                                  
                                  return RepaintBoundary(
                                    child: Stack(
                                      children: [
                                        ProductCard(
                                          id: product.id.toString(),
                                          title: product.title,
                                          imageUrl: imageUrl ?? '',
                                          currentBid: (product.currentBid ?? product.startingBid ?? product.startingPrice).toInt(),
                                          totalBids: product.totalBids ?? 0,
                                          endTime: product.auctionEndTime ?? DateTime.now().add(const Duration(days: 7)),
                                          category: product.categoryName,
                                          status: product.status, // Pass status to card
                                          onTap: product.status == 'approved'
                                              ? () {
                                                  context.go('/product-details/${product.id}');
                                                }
                                              : () {}, // Empty function for non-approved products
                                        ),
                                        // Status Badge
                                        if (product.status != 'ended')
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: product.status == 'pending'
                                                    ? AppColors.yellow100
                                                    : product.status == 'approved'
                                                        ? AppColors.green100
                                                        : AppColors.red100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                product.status == 'pending' 
                                                    ? 'Pending' 
                                                    : product.status == 'approved'
                                                        ? 'Active'
                                                        : product.status!.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: product.status == 'pending'
                                                      ? AppColors.yellow700
                                                      : product.status == 'approved'
                                                          ? AppColors.green700
                                                          : AppColors.red700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        // Edit/Delete buttons overlay - Professional design with subtle appearance
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.95),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final result = await context.push(
                                                        '/product-create',
                                                        extra: product,
                                                      );
                                                      if (result == true) {
                                                        _loadProducts(reset: true);
                                                      }
                                                    },
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(8),
                                                      bottomLeft: Radius.circular(8),
                                                    ),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Icon(
                                                        Icons.edit_outlined,
                                                        size: 18,
                                                        color: AppColors.primaryBlue,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 24,
                                                  color: Colors.grey.withOpacity(0.3),
                                                ),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final confirmed = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Delete Product'),
                                                          content: Text('Are you sure you want to delete "${product.title}"?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, false),
                                                              child: const Text('Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              style: TextButton.styleFrom(
                                                                foregroundColor: AppColors.red600,
                                                              ),
                                                              child: const Text('Delete'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirmed == true) {
                                                        try {
                                                          await apiService.deleteProduct(product.id);
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('Product deleted successfully'),
                                                                backgroundColor: AppColors.green600,
                                                              ),
                                                            );
                                                            _loadProducts(reset: true);
                                                          }
                                                        } catch (e) {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('Failed to delete: ${e.toString()}'),
                                                                backgroundColor: AppColors.red600,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                    borderRadius: const BorderRadius.only(
                                                      topRight: Radius.circular(8),
                                                      bottomRight: Radius.circular(8),
                                                    ),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Icon(
                                                        Icons.delete_outline,
                                                        size: 18,
                                                        color: AppColors.red600,
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
                                  ).animate().fadeIn( delay: (50 * index).ms ).slideY(begin: 0.1, end: 0, delay: (50 * index).ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: (50 * index).ms);
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
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
}

// Keep existing _StatCard and _ListingCard classes below
class _StatCard extends StatelessWidget {
  final StatData stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stat.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: stat.gradientColors.first.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cardWhite.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.cardWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.change,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.cardWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cardWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardWhite.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: stat.gradientColors.first.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(stat.icon, size: 26, color: AppColors.cardWhite),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ProductModel product;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ListingCard({
    required this.product,
    required this.imageUrl,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? AppColors.slate900 : AppColors.slate100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        ImageUrlHelper.fixImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image, size: 32);
                        },
                      )
                    : const Icon(Icons.image, size: 32),
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.status == 'pending')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.yellow100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.yellow700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Category Display
                  if (product.categoryName != null && product.categoryName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.categoryName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (product.status == 'approved')
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Bid',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                            ),
                            Text(
                              '\$${_formatCurrency((product.currentBid ?? product.startingBid ?? product.startingPrice).toInt())}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 14,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.totalBids ?? 0}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                ),
                              ],
                            ),
                            // Show countdown only if product is approved
                            // Pending products should show "Waiting for approval"
                            if (product.status == 'approved' && product.auctionEndTime != null)
                              CountdownTimer(
                                endTime: product.auctionEndTime!,
                                size: CountdownSize.small,
                              ),
                          ],
                        ),
                      ],
                    )
                  else
                    Text(
                      product.status == 'pending'
                          ? 'Waiting for approval'
                          : 'Status: ${product.status}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  // View Winner button for sold products
                  if (product.status == 'sold')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.go('/seller/winner/${product.id}');
                          },
                          icon: const Icon(Icons.emoji_events_rounded, size: 16),
                          label: const Text('View Winner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green600,
                            foregroundColor: AppColors.cardWhite,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                  // Edit/Delete buttons (only for seller's own products)
                  if (onEdit != null || onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onEdit != null)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.blue600.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.blue600.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                color: AppColors.blue600,
                                onPressed: () {
                                  // Stop tap propagation
                                  if (onTap != null) {
                                    // Don't navigate to details
                                  }
                                  onEdit?.call();
                                },
                                tooltip: 'Edit',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.red600.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.red600.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_rounded, size: 18),
                                color: AppColors.red600,
                                onPressed: () {
                                  // Stop tap propagation
                                  if (onTap != null) {
                                    // Don't navigate to details
                                  }
                                  onDelete?.call();
                                },
                                tooltip: 'Delete',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ],
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class StatData {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final List<Color> gradientColors;

  StatData({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.gradientColors,
  });
}

// ListingData class removed - using ProductModel instead

