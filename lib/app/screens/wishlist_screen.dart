import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/luxury_product_card.dart';

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

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wishlistIds = await StorageService.getWishlist();
      if (wishlistIds.isEmpty) {
        if (mounted) {
          setState(() {
            _wishlistProducts = [];
            _isLoading = false;
          });
        }
        return;
      }

      final result = await apiService.getAllProducts(page: 1, limit: 50);
      final products = result['products'] as List<ProductModel>? ?? [];

      final filtered = products.where((p) => wishlistIds.contains(p.id)).toList();

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar' ||
            LanguageService.getLanguageName() == 'Arabic';

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFFFFF),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Text(
                isArabic ? 'قائمة المفضلة' : 'My Wishlist',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF0F172A), size: 22),
                  onPressed: _loadWishlist,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(isArabic),
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isArabic) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0066FF),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 52, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWishlist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_wishlistProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 46,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'قائمة المفضلة فارغة' : 'Your Wishlist is Empty',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'اضغط على أيقونة القلب في أي منتج لمتابعته بسهولة هنا.'
                    : 'Tap the heart icon on any product to save and track it here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isArabic ? 'استعراض المزادات' : 'Browse Auctions',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0066FF),
      onRefresh: _loadWishlist,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _wishlistProducts.length,
          itemBuilder: (context, index) {
            final p = _wishlistProducts[index];
            final imgUrl = (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                ? p.imageUrl!
                : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&q=80';

            return LuxuryProductCard(
              id: p.id.toString(),
              title: p.title,
              imageUrl: imgUrl,
              currentBid: (p.currentBid ?? p.startingPrice).toInt(),
              totalBids: p.totalBids ?? 0,
              endTime: p.auctionEndTime ??
                  DateTime.now().add(const Duration(hours: 24)),
              category: p.categoryName,
              tag: p.condition,
              onTap: () {
                context.push('/product/${p.id}');
              },
            );
          },
        ),
      ),
    );
  }
}
