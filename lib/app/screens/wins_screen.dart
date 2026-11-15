import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';

class WinsScreen extends StatefulWidget {
  const WinsScreen({super.key});

  @override
  State<WinsScreen> createState() => _WinsScreenState();
}

class _WinsScreenState extends State<WinsScreen> {
  List<Map<String, dynamic>> _wonBids = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadMoreScheduled = false;

  static const int usdToIqdRate = 1520;

  @override
  void initState() {
    super.initState();
    _loadWonBids();
  }

  Future<void> _loadWonBids({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _isLoading || !_hasMore || _loadMoreScheduled) {
        return;
      }
      setState(() {
        _isLoadingMore = true;
        _loadMoreScheduled = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _wonBids = [];
        _hasMore = true;
        _loadMoreScheduled = false;
        _errorMessage = null;
      });
    }

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final response = await apiService.getBuyerBiddingHistory(
        status: 'won',
        page: page,
        limit: 20,
      );

      if (response['success'] == true) {
        final newBids = ((response['data'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final pagination = response['pagination'] as Map<String, dynamic>?;

        setState(() {
          if (loadMore) {
            _wonBids.addAll(newBids);
          } else {
            _wonBids = newBids;
          }
          _currentPage = page;
          _hasMore = pagination?['hasMore'] == true || newBids.length >= 20;
          _isLoading = false;
          _isLoadingMore = false;
          _loadMoreScheduled = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] as String? ?? 'Failed to load';
          _isLoading = false;
          _isLoadingMore = false;
          _loadMoreScheduled = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
        _loadMoreScheduled = false;
      });
    }
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
                isArabic ? 'المزادات الرابحة' : 'Won Auctions',
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
                  onPressed: () => _loadWonBids(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildContent(isArabic),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isArabic) {
    if (_isLoading && _wonBids.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0066FF),
        ),
      );
    }

    if (_errorMessage != null && _wonBids.isEmpty) {
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
                onPressed: () => _loadWonBids(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isArabic ? 'إعادة المحاولة' : 'Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_wonBids.isEmpty) {
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
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'لا توجد مزادات رابحة بعد' : 'No Won Auctions Yet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'شارك في المزادات الحية وكن الفائز بالصفقات الفاخرة.'
                    : 'Join live auctions now to win premium items and deals.',
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
                  isArabic ? 'استكشف المزادات' : 'Explore Auctions',
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
      onRefresh: () => _loadWonBids(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _wonBids.length + (_hasMore && _isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == _wonBids.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_loadMoreScheduled) {
                _loadMoreScheduled = true;
                _loadWonBids(loadMore: true);
              }
            });
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0066FF)),
              ),
            );
          }

          final bid = _wonBids[index];
          final productId = (bid['product_id'] ??
              bid['productId'] ??
              bid['id']) as int?;
          final title = (bid['product_title'] ??
              bid['title'] ??
              'Luxury Item') as String;
          final imageUrl = (bid['product_image'] ??
              bid['image_url'] ??
              bid['imageUrl'] ??
              '') as String;
          final wonPrice = _safeToDouble(
              bid['amount'] ?? bid['current_highest_bid'] ?? 0);
          final iqdPrice = (wonPrice * usdToIqdRate).toInt();
          final formattedIqd = iqdPrice.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},');

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 86,
                    height: 86,
                    color: const Color(0xFFF8FAFC),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_rounded,
                                  color: Color(0xFFCBD5E1)),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: Color(0xFFCBD5E1)),
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Won Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isArabic ? 'تم الفوز بالصفقة' : 'AUCTION WON',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${wonPrice.toInt()}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0066FF),
                                ),
                              ),
                              Text(
                                '≈ $formattedIqd IQD',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),

                          // Checkout / View Action Button
                          ElevatedButton(
                            onPressed: () {
                              if (productId != null) {
                                context.push('/product/$productId');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isArabic ? 'إتمام الطلب' : 'Checkout',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
