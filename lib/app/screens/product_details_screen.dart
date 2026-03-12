import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../widgets/countdown_timer.dart';
import 'place_bid_modal.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../utils/image_url_helper.dart';
import '../theme/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../services/socket_service.dart';
import '../services/app_localizations.dart';

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
  String? _userRole;
  int? _userId;
  bool _isDescriptionExpanded = false;
  bool _isAboutExpanded = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProductData();
  }

  Future<void> _loadUserInfo() async {
    final role = await StorageService.getUserRole();
    final userId = await StorageService.getUserId();
    final isLoggedIn = await StorageService.isLoggedIn();
    setState(() {
      _userRole = role;
      _userId = userId;
      _isLoggedIn = isLoggedIn;
    });

    // Initialize socket connection
    socketService.init();
    socketService.joinProductRoom(widget.productId);
    socketService.onBidUpdate((data) {
      if (mounted) {
        // Refresh product data when a new bid is placed
        _loadProductData();
        // Show a small notification or snakebar if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New bid placed!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Check if current user can edit/delete this product
  bool get _canEditProduct {
    if (_product == null || _userRole == null) return false;
    
    final role = _userRole!.toLowerCase();
    
    // Superadmin can edit/delete any product
    if (role == 'superadmin' || role == 'admin') {
      return true;
    }
    
    // Seller can only edit/delete their own products
    if (role == 'seller_products' && _userId != null) {
      return _product!.sellerId == _userId;
    }
    
    return false;
  }

  // Check if current user is the seller of this product
  bool _isSellerOfProduct() {
    if (_product == null || _userId == null) return false;
    return _product!.sellerId == _userId;
  }



  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) {
        throw Exception('Invalid product ID');
      }

      // Load product, bids, and wishlist status in parallel
      final results = await Future.wait([
        apiService.getProductById(productId),
        apiService.getBidsByProduct(productId),
        StorageService.isInWishlist(productId),
      ]);

      setState(() {
        _product = results[0] as ProductModel;
        _bids = results[1] as List<BidModel>;
        _isLiked = results[2] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _images {
    if (_product == null) return [];
    return _product!.imageUrls;
  }

  @override
  void dispose() {
    socketService.leaveProductRoom(widget.productId);
    super.dispose();
  }

  Future<void> _toggleWishlist() async {
    if (!_isLoggedIn) {
      context.push('/auth');
      return;
    }
    
    if (_product == null) return;
    
    setState(() {
      _isLiked = !_isLiked;
    });

    try {
      await StorageService.toggleWishlist(_product!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked ? 'Added to wishlist' : 'Removed from wishlist'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert if API fails
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update wishlist: $e')),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    if (_product == null) return;
    
    // final l10n = AppLocalizations.of(context);
    final String shareMessage = "Check out this auction: ${_product!.title}\n"
        "Current Bid: ${_product!.currentBid ?? _product!.startingBid} \$\n"
        "https://iraqbid.com/product/${_product!.id}"; // Replace with real deep link if available
        
    await Share.share(shareMessage);
  }
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar - Clean design matching image
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  Expanded(
                    child: Text(
                      'Product Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: _handleShare,
                    icon: Icon(
                      Icons.share_outlined,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_product != null) {
                        _toggleWishlist();
                      }
                    },
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Content reported. We will review it shortly.'),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.flag_outlined,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load product',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadProductData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.cardWhite,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _product == null
                          ? const Center(child: Text('Product not found'))
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image Carousel with Promotional Banner
                                  SizedBox(
                                    height: 400,
                                    child: Stack(
                                      children: [
                                        PageView.builder(
                                          itemCount: _images.length,
                                          onPageChanged: (index) {
                                            setState(() {
                                              _currentImageIndex = index;
                                            });
                                          },
                                          itemBuilder: (context, index) {
                                            final imageWidget = CachedNetworkImage(
                                              imageUrl: ImageUrlHelper.fixImageUrl(_images[index]),
                                              fit: BoxFit.cover,
                                              httpHeaders: const {'Accept': 'image/*'},
                                              placeholder: (context, url) => Shimmer.fromColors(
                                                baseColor: isDark ? AppColors.slate800 : AppColors.slate100,
                                                highlightColor: isDark ? AppColors.slate700 : Colors.white,
                                                child: Container(
                                                  color: Colors.white,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                                                child: Icon(Icons.image_not_supported_outlined, size: 64, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                              ),
                                            );

                                            return Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                if (index == 0)
                                                  Hero(
                                                    tag: 'product_image_${_product!.id}',
                                                    child: imageWidget,
                                                  )
                                                else
                                                  imageWidget,
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                   ),
                    ),
                    
                    // Image Indicators
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _images.length,
                          (index) => Container(
                            width: index == _currentImageIndex ? 32 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == _currentImageIndex
                                  ? AppColors.primaryBlue
                                  : (isDark ? AppColors.slate700 : AppColors.slate300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Product Info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            _product!.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Login/Register Button - Only show if not logged in
                          if (!_isLoggedIn)
                            GestureDetector(
                              onTap: () {
                                context.go('/auth');
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.warning.withOpacity(0.8) // Dark mode: warning color
                                      : const Color(0xFFD4A574), // Light mode: Light brown
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Login or register',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (!_isLoggedIn) const SizedBox(height: 24),
                          if (_isLoggedIn) const SizedBox(height: 16),

                          // Time Remaining - Green/Red Box (Red when time is low)
                          Builder(
                            builder: (context) {
                              // Calculate time remaining
                              Color timerColor = AppColors.green600; // Default green
                              if (_product!.auctionEndTime != null) {
                                final now = DateTime.now();
                                final timeRemaining = _product!.auctionEndTime!.difference(now);
                                // Change to red if less than 1 hour remaining
                                if (timeRemaining.inHours < 1) {
                                  timerColor = Colors.red; // Red when time is low
                                }
                              }
                              
                              return Row(
                                children: [
                                  Text(
                                    'Time Remaining:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: timerColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: _product!.auctionEndTime != null
                                        ? CountdownTimer(
                                            endTime: _product!.auctionEndTime!,
                                            size: CountdownSize.small,
                                          )
                                        : Text(
                                            '00h 00m 00s',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Current Bid Card with Bidder Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? AppColors.slate800.withOpacity(0.8) // Dark mode: dark slate with slight transparency
                                  : const Color(0xFFE8F5E9), // Light mode: Light green
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.green600.withOpacity(0.5)
                                    : AppColors.green600.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.gavel, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _bids.isNotEmpty
                                                      ? 'Bidder'
                                                      : 'No bids yet',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              if (_bids.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                                              ],
                                            ],
                                          ),
                                          if (_bids.isNotEmpty && _bids.first.createdAt != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDate(_bids.first.createdAt!),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${_formatCurrency((_product!.currentBid ?? _product!.startingBid ?? _product!.startingPrice).toInt())}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                        Icon(Icons.keyboard_arrow_down, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Product Details Section - Visible to ALL users
                          Text(
                            'Product details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                          ),
                          const SizedBox(height: 12),
                          // Guarantee Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.slate800.withOpacity(0.8) // Dark mode: dark slate
                                  : const Color(0xFFE3F2FD), // Light mode: Light blue
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.primaryBlue.withOpacity(0.5)
                                    : AppColors.primaryBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.slate700
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This product has a 7 days Guarantee.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Product Info Details
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Product ID
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Product ID',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      '#${_product!.id}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Real Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Real Price',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '\$',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(
                                            (_product!.currentPrice ?? _product!.startingPrice).toInt()
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Product Condition
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Condition',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    _ConditionTag(
                                      condition: _product!.condition,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Seller Information
                          if (true) ...[
                            Text(
                              'Seller Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isDark ? AppColors.slate800 : AppColors.slate100,
                                    child: Text(
                                      'S',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Seller',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Contact info hidden for customers
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.person_outline),
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDark ? AppColors.slate800 : AppColors.slate100,
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Description Section (Expandable Card)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded = !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        Icon(
                                          _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isDescriptionExpanded) ...[
                                  Divider(
                                    height: 1,
                                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _buildInfoRow('brand', _extractBrand(_product!.title) ?? 'Others'),
                                        const SizedBox(height: 12),
                                        _buildInfoRow('Model Name', _extractModel(_product!.title) ?? _product!.title),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // About this Item Section (Expandable Card)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isAboutExpanded = !_isAboutExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'About this Item',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        Icon(
                                          _isAboutExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isAboutExpanded) ...[
                                  Divider(
                                    height: 1,
                                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      _product!.description ?? 'No description provided',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Bid History
                          if (true) ...[
                            Text(
                              'Bid History',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (_bids.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No bids yet. Be the first to bid!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              RepaintBoundary(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _bids.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final bid = _bids[index];
                                    final timeAgo = _formatTimeAgo(bid.createdAt);
                                    return RepaintBoundary(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 16,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: isDark ? AppColors.slate800 : AppColors.slate100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'B',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryBlue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Bidder',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                    ),
                                                  ),
                                                  Text(
                                                    timeAgo,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '\$${_formatCurrency(bid.amount.toInt())}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],

                          const SizedBox(height: 100), // Space for bottom button
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.slate800 : AppColors.slate200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                // Check if user is logged in
                final isLoggedIn = await StorageService.isLoggedIn();
                if (!isLoggedIn) {
                  // Show login prompt
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Login Required'),
                        content: const Text('Please login first'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/auth');
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }
                
                // Check if product is pending (not approved)
                if (_product?.status == 'pending') {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This product is pending admin approval. Bidding will be available once approved.'),
                        backgroundColor: AppColors.error,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }
                
                // Check if user is the seller of this product
                if (_isSellerOfProduct()) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You cannot bid on your own product.'),
                        backgroundColor: AppColors.error,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }
                
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    final productId = int.tryParse(widget.productId);
                    final currentBid = _product?.currentBid?.toInt() ?? 
                                     _product?.startingBid?.toInt() ?? 
                                     _product?.startingPrice.toInt() ?? 
                                     0;
                    final productTitle = _product?.title ?? 'Product';
                    
                    return PlaceBidModal(
                      currentBid: currentBid,
                      productTitle: productTitle,
                      productId: productId ?? 0,
                    );
                  },
                );
                
                // Refresh product data if bid was successful
                // Delay refresh to ensure modal is fully closed and Navigator is stable
                if (result == true && mounted) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      // Add a small delay to ensure Navigator is fully stable
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          _loadProductData();
                        }
                      });
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.cardWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Place Bid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  // Helper methods to extract brand and model from product title
  String? _extractBrand(String title) {
    // Try to extract brand from title (common brands)
    final brands = ['JBL', 'Sony', 'Samsung', 'Apple', 'LG', 'Bose', 'Nike', 'Adidas'];
    for (var brand in brands) {
      if (title.toUpperCase().contains(brand.toUpperCase())) {
        return brand;
      }
    }
    return null;
  }

  String? _extractModel(String title) {
    // Try to extract model name from title
    // If title contains brand, return the part after brand
    final brands = ['JBL', 'Sony', 'Samsung', 'Apple', 'LG', 'Bose', 'Nike', 'Adidas'];
    for (var brand in brands) {
      if (title.toUpperCase().contains(brand.toUpperCase())) {
        final parts = title.split(RegExp(brand, caseSensitive: false));
        if (parts.length > 1) {
          return parts[1].trim().isEmpty ? title : parts[1].trim();
        }
      }
    }
    // If no brand found, return first few words as model
    final words = title.split(' ');
    if (words.length > 1) {
      return words.take(2).join(' ');
    }
    return null;
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${_product?.title ?? 'this product'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600,
              foregroundColor: AppColors.cardWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _product != null) {
      await _deleteProduct();
    }
  }

  Future<void> _deleteProduct() async {
    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) return;

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      await apiService.deleteProduct(productId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product deleted successfully'),
            backgroundColor: AppColors.green600,
          ),
        );

        // Navigate back
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: ${e.toString()}'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    }
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ConditionTag extends StatelessWidget {
  final String? condition;

  const _ConditionTag({
    required this.condition,
  });

  Color _getConditionColor(String? condition) {
    if (condition == null) return AppColors.slate400;
    switch (condition.toLowerCase()) {
      case 'new':
        return AppColors.green600;
      case 'used':
        return AppColors.warning;
      case 'working':
        return AppColors.blue600;
      default:
        return AppColors.slate400;
    }
  }

  String _getConditionLabel(String? condition) {
    if (condition == null || condition.isEmpty) return 'Not Specified';
    switch (condition.toLowerCase()) {
      case 'new':
        return 'New';
      case 'used':
        return 'Used';
      case 'working':
        return 'Working';
      default:
        return condition;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conditionColor = _getConditionColor(condition);
    final conditionLabel = _getConditionLabel(condition);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: conditionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: conditionColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        conditionLabel,
        style: TextStyle(
          fontSize: 12,
          color: conditionColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}



