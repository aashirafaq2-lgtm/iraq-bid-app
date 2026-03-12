import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/product_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';
import '../utils/image_url_helper.dart';
import '../theme/colors.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<ProductModel> _wishlistProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when screen becomes visible
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get wishlist product IDs from local storage
      final wishlistIds = await StorageService.getWishlist();
      
      if (wishlistIds.isEmpty) {
        setState(() {
          _wishlistProducts = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch all products and filter by wishlist IDs
      // Note: We need to fetch all pages to get all products
      // For now, we'll fetch multiple pages or use a different approach
      List<ProductModel> allProducts = [];
      int page = 1;
      bool hasMore = true;
      
      while (hasMore && allProducts.length < 100) { // Limit to prevent infinite loop
        final result = await apiService.getAllProducts(page: page, limit: 50);
        final products = result['products'] as List<ProductModel>;
        allProducts.addAll(products);
        
        final pagination = result['pagination'] as Map<String, dynamic>?;
        hasMore = pagination?['hasMore'] == true && products.length >= 50;
        page++;
      }
      
      final now = DateTime.now();
      // Filter products that are in wishlist AND haven't expired
      final wishlistProducts = allProducts
          .where((product) {
            // Must be in wishlist
            if (!wishlistIds.contains(product.id)) return false;
            // Must not have expired (auctionEndTime > now)
            if (product.auctionEndTime != null && product.auctionEndTime!.isBefore(now)) {
              return false; // Auction has ended, don't show
            }
            return true;
          })
          .toList();

      setState(() {
        _wishlistProducts = wishlistProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wishlist';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(int productId) async {
    await StorageService.removeFromWishlist(productId);
    _loadWishlist(); // Reload list
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Wishlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWishlist,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _wishlistProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 64, color: isDark ? AppColors.slate400 : AppColors.slate400),
                          const SizedBox(height: 16),
                          Text(
                            'Your wishlist is empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add products to wishlist to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWishlist,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: _wishlistProducts.length,
                        itemBuilder: (context, index) {
                          final product = _wishlistProducts[index];
                          final imageUrls = product.imageUrls;
                          final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
                          
                          return ProductCard(
                            id: product.id.toString(),
                            title: product.title,
                            imageUrl: imageUrl ?? '',
                            currentBid: (product.currentBid ?? product.currentPrice ?? product.startingPrice).toInt(),
                            totalBids: product.totalBids ?? 0,
                            endTime: product.auctionEndTime ?? DateTime.now().add(const Duration(days: 1)),
                            category: product.categoryName,
                            onTap: () {
                              context.push('/product-details/${product.id}');
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

