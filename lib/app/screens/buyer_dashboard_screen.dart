import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../widgets/product_card.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  // Categories loaded from API
  List<String> _categories = ['All']; // 'All' is always available, rest loaded from API
  bool _categoriesLoaded = false; // Prevent multiple loads
  bool _isLoadingMore = false; // Prevent multiple load-more calls
  bool _loadMoreScheduled = false; // Prevent scheduling multiple load-more calls during build

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCategories() async {
    if (_categoriesLoaded) return; // Prevent multiple loads
    
    try {
      final categories = await apiService.getAllCategories();
      // Extract unique category names and remove duplicates
      final categoryNames = categories
          .map((cat) => cat['name'] as String)
          .where((name) => name != null && name.isNotEmpty)
          .toSet() // Remove duplicates using Set
          .toList();
      
      setState(() {
        _categories = ['All', ...categoryNames];
        _categoriesLoaded = true;
      });
    } catch (e) {
      print('Error loading categories: $e');
      // Keep 'All' as default
    }
  }

  void _onSearchChanged() {
    // Debounce search - reload after user stops typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _loadProducts(reset: true);
      }
    });
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _products = [];
        _hasMore = true;
      });
    }

    if (!_hasMore && !reset) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await apiService.getAllProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        limit: 20,
      );

      final newProducts = result['products'] as List<ProductModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      
      final now = DateTime.now();
      // Filter out expired products (auctionEndTime < now)
      final activeProducts = newProducts.where((product) {
        if (product.auctionEndTime == null) {
          return true; // Keep products without end time (might be pending)
        }
        return product.auctionEndTime!.isAfter(now); // Only show if auction hasn't ended
      }).toList();

      setState(() {
        if (reset) {
          _products = activeProducts;
        } else {
          _products.addAll(activeProducts);
        }
        _currentPage = pagination['page'] as int;
        _hasMore = _currentPage < (pagination['pages'] as int);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ProductModel> get _filteredProducts {
    // Backend already filters by category and search, but we can do client-side filtering if needed
    return _products;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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

  void _showSettingsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate600 : AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Settings Title
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: AppColors.blue600,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Settings Options
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.blue600),
              title: const Text('Profile'),
              subtitle: const Text('View and edit your profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.warning),
              title: const Text('Switch Role'),
              subtitle: const Text('Change between Buyer and Seller'),
              onTap: () {
                Navigator.pop(context);
                context.push('/role-selection');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: AppColors.green600),
              title: const Text('Wallet'),
              subtitle: const Text('View your wallet and earnings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wallet');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: AppColors.yellow600),
              title: const Text('Notifications'),
              subtitle: const Text('Manage your notifications'),
              onTap: () {
                Navigator.pop(context);
                context.push('/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: AppColors.red600),
              title: const Text('Wishlist'),
              subtitle: const Text('View your saved products'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wishlist');
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: AppColors.green600),
              title: const Text('Wins'),
              subtitle: const Text('View your won auctions'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wins');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Title and Filter Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${_filteredProducts.length} active auctions',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              context.push('/profile');
                            },
                            icon: const Icon(Icons.person),
                            tooltip: 'Profile',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  isDark ? AppColors.slate800 : AppColors.slate100,
                              shape: const CircleBorder(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              context.go('/buyer/bidding-history');
                            },
                            icon: const Icon(Icons.history),
                            tooltip: 'Bidding History',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  isDark ? AppColors.slate800 : AppColors.slate100,
                              shape: const CircleBorder(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              _showSettingsBottomSheet(context);
                            },
                            icon: const Icon(Icons.settings),
                            tooltip: 'Settings',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  isDark ? AppColors.slate800 : AppColors.slate100,
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search auctions...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.backgroundDark : AppColors.slate50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.slate800 : AppColors.slate200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.slate800 : AppColors.slate200,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Filter
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        key: const ValueKey('category_filter_list'),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            key: ValueKey('category_${index}_$category'),
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              key: ValueKey('filter_chip_$category'),
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                _onCategorySelected(category);
                              },
                              selectedColor: AppColors.blue600,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.cardWhite
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Products Grid
                    Text(
                      'Active Auctions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 16),

                    // Product List
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
                                'Failed to load products',
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
                    else if (_filteredProducts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: AppColors.slate400),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      RepaintBoundary(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredProducts.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == _filteredProducts.length) {
                            // Load more indicator
                            if (!_isLoading && !_isLoadingMore && !_loadMoreScheduled && _hasMore) {
                              // Mark as scheduled to prevent multiple calls during same build
                              _loadMoreScheduled = true;
                              
                              // Use SchedulerBinding to ensure callback runs AFTER frame is complete
                              // This guarantees setState won't be called during build
                              SchedulerBinding.instance.addPostFrameCallback((_) {
                                // Reset the flag first
                                _loadMoreScheduled = false;
                                
                                if (mounted && !_isLoading && !_isLoadingMore && _hasMore) {
                                  setState(() {
                                    _isLoadingMore = true;
                                  });
                                  _loadProducts().then((_) {
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingMore = false;
                                      });
                                    }
                                  }).catchError((_) {
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingMore = false;
                                      });
                                    }
                                  });
                                }
                              });
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          final product = _filteredProducts[index];
                          // Get first image URL or use placeholder
                          final imageUrls = product.imageUrls;
                          final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
                          
                          return RepaintBoundary(
                            child: ProductCard(
                              id: product.id.toString(),
                              title: product.title,
                              imageUrl: imageUrl ?? '',
                              currentBid: (product.currentBid ?? product.startingBid ?? product.startingPrice).toInt(),
                              totalBids: product.totalBids ?? 0,
                              endTime: product.auctionEndTime ?? DateTime.now().add(const Duration(days: 7)),
                              category: product.categoryName,
                              onTap: () {
                                context.go('/product-details/${product.id}');
                              },
                            ),
                          );
                        },
                      ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradientColors;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.cardWhite),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.cardWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.cardWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ProductData class removed - using ProductModel instead

