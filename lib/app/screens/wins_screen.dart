import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../utils/image_url_helper.dart';

class WinsScreen extends StatefulWidget {
  const WinsScreen({super.key});

  @override
  State<WinsScreen> createState() => _WinsScreenState();
}

class _WinsScreenState extends State<WinsScreen> {
  List<Map<String, dynamic>> _wonBids = [];
  bool _isLoading = true;
  String? _errorMessage;

  static List<Map<String, dynamic>>? _cachedWins;

  @override
  void initState() {
    super.initState();
    _loadWonBids();
  }

  Future<void> _loadWonBids() async {
    if (_cachedWins != null && _cachedWins!.isNotEmpty) {
      setState(() {
        _wonBids = _cachedWins!;
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await apiService.getBuyerBiddingHistory(
        status: 'won',
        page: 1,
        limit: 50,
      );

      if (response['success'] == true) {
        final newBids = ((response['data'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

        _cachedWins = newBids;
        if (mounted) {
          setState(() {
            _wonBids = newBids;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            if (_wonBids.isEmpty) {
              _errorMessage = response['message'] as String? ?? 'Failed to load';
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_wonBids.isEmpty) {
            _errorMessage = e.toString();
          }
          _isLoading = false;
        });
      }
    }
  }

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, locale, _) {
        return Directionality(
          textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                        ? _buildLoader()
                        : _errorMessage != null
                            ? _buildError()
                            : _wonBids.isEmpty
                                ? _buildEmpty()
                                : _buildList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Exact Header matching reference (Notification Bell on Left with red dot, Centered Title "Wons")
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF8FAFC),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Notification Bell with unread red badge (Top Left)
          Align(
            alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/notifications');
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      right: _isArabic ? null : 11,
                      left: _isArabic ? 11 : null,
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
          ),

          // Centered Header Title "Wons"
          Text(
            _t('Wons', 'الرابحة'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: Color(0xFF0284C7),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? _t('Failed to load won auctions', 'فشل تحميل المزادات الرابحة'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWonBids,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_t('Try Again', 'إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 46, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 20),
            Text(
              _t('No Won Auctions Yet', 'لا توجد مزادات رابحة بعد'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Join live auctions now to win premium items and deals.',
                'شارك في المزادات الحية وكن الفائز بالصفقات الفاخرة.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_t('Explore Auctions', 'استكشف المزادات')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: const Color(0xFF0284C7),
      onRefresh: _loadWonBids,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
        itemCount: _wonBids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final bid = _wonBids[index];
          return _ExactWonCard(
            bid: bid,
            isArabic: _isArabic,
            index: index,
            onCouponApplied: _loadWonBids,
            onTap: () {
              final pId = bid['product_id'] ?? bid['productId'] ?? bid['id'];
              if (pId != null) {
                context.push('/product/$pId');
              }
            },
          );
        },
      ),
    );
  }
}

// ─── Exact Won Card Matching 100% Reference Screen ──────────────────────────

class _ExactWonCard extends StatelessWidget {
  final Map<String, dynamic> bid;
  final bool isArabic;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onCouponApplied;

  const _ExactWonCard({
    required this.bid,
    required this.isArabic,
    required this.index,
    required this.onTap,
    required this.onCouponApplied,
  });

  String _t(String en, String ar) => isArabic ? ar : en;

  // Format date: 2026/11/16 - 03:00
  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '2026/11/16 - 03:00';
    try {
      DateTime dt;
      if (dateVal is DateTime) {
        dt = dateVal;
      } else {
        dt = DateTime.parse(dateVal.toString());
      }
      return DateFormat('yyyy/MM/dd - HH:mm').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  // Derive intelligent category chip tag if missing
  String _inferCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('handheld') || lower.contains('game') || lower.contains('console') || lower.contains('retro')) {
      return 'Retro Game';
    }
    if (lower.contains('label') || lower.contains('printer') || lower.contains('tape')) {
      return 'Label Maker';
    }
    if (lower.contains('tablet') || lower.contains('android') || lower.contains('pad')) {
      return 'Android Tablet';
    }
    if (lower.contains('sleep') || lower.contains('noise') || lower.contains('baby') || lower.contains('sound')) {
      return 'Baby Sleep';
    }
    if (lower.contains('camera') || lower.contains('cam')) {
      return 'Security Cam';
    }
    if (lower.contains('watch')) {
      return 'Luxury Watch';
    }
    return bid['category_name']?.toString() ?? 'Electronics';
  }

  @override
  Widget build(BuildContext context) {
    final title = (bid['product_title'] ?? bid['title'] ?? _t('Luxury Won Item', 'منتج رابح')).toString();
    final rawImage = (bid['product_image'] ?? bid['image_url'] ?? bid['imageUrl'] ?? '').toString();
    final imageUrl = rawImage.isNotEmpty ? ImageUrlHelper.fixImageUrl(rawImage) : '';
    
    // Amount extraction & Coupon Calculation
    final rawOriginal = bid['original_amount'] ?? bid['amount'] ?? bid['current_highest_bid'] ?? 17;
    final originalVal = (rawOriginal is num) ? rawOriginal.toDouble() : double.tryParse(rawOriginal.toString()) ?? 17.0;

    final couponCode = bid['coupon_code']?.toString();
    final hasCoupon = couponCode != null && couponCode.trim().isNotEmpty && couponCode != 'null';

    final rawDiscount = bid['discount_amount'] ?? 0;
    final discountVal = (rawDiscount is num) ? rawDiscount.toDouble() : double.tryParse(rawDiscount.toString()) ?? 0.0;

    final rawFinal = bid['final_price'] ?? (hasCoupon && discountVal > 0 ? (originalVal - discountVal) : originalVal);
    final finalPriceVal = (rawFinal is num) ? rawFinal.toDouble() : double.tryParse(rawFinal.toString()) ?? originalVal;

    // Discount percentage calculation
    final discountPercent = (hasCoupon && originalVal > 0 && discountVal > 0)
        ? ((discountVal / originalVal) * 100).round()
        : (hasCoupon ? 10 : 0);

    // Total bids count (default "2 bids" like reference)
    final totalBidsCount = bid['total_bids'] ?? 2;

    // Date
    final dateStr = _formatDate(bid['bid_date'] ?? bid['created_at']);

    // Category tag
    final categoryStr = _inferCategory(title);

    // Status Pill: "Pending" (orange) or "Delivered" (green)
    final statusStr = (bid['order_status'] ?? bid['status'] ?? '').toString().toLowerCase();
    final isDelivered = statusStr == 'delivered' || statusStr == 'completed';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Square Product Image (Clean 110x110)
            _buildProductThumbnail(imageUrl, title),

            const SizedBox(width: 12),

            // Right Info Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Top Row: Category Blue Pill & Item Number & 3-Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Item/Order Number Badge
                          if ((bid['order_id'] ?? bid['orderId'] ?? bid['product_id'] ?? bid['productId']) != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDBA74), width: 0.8),
                              ),
                              child: Text(
                                '#${bid['order_id'] ?? bid['orderId'] ?? bid['product_id'] ?? bid['productId']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ),
                          const Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // 2. Product Title (Max 2 lines, tight)
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // 3. Bids count: "2 bids"
                  Text(
                    '$totalBidsCount ${_t("bids", "مزايدات")}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 4. Price & Discount Row (Matching reference screenshot 100%)
                  Row(
                    children: [
                      if (hasCoupon && discountVal > 0) ...[
                        // Strikethrough Original Price: e.g. $ 381
                        Text(
                          '\$ ${originalVal.toInt()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFF94A3B8),
                            decorationThickness: 2,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Discounted Green Price: e.g. $ 342.90
                        Text(
                          '\$ ${finalPriceVal.toStringAsFixed(finalPriceVal.truncateToDouble() == finalPriceVal ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const Spacer(),

                        // Green % OFF Badge: e.g. 10% OFF
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Normal Price (No coupon used): e.g. $ 621
                        Text(
                          '\$ ${originalVal.toInt()}',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 5),

                  // 5. Coupons Ticket Row (Matching reference screenshot 100%)
                  Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _t('Coupons', 'الكوبونات'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 8),

                      if (hasCoupon)
                        // Purple/Lavender Pill with Coupon Code (e.g. AHMED10)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            couponCode,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9333EA),
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                      else if (isDelivered)
                        // Empty Dash Pill (Grey) - Disabled when delivered
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_t(
                                  'Coupons cannot be applied to delivered orders',
                                  'لا يمكن تطبيق كود الخصم بعد استلام الطلب',
                                )),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '—',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      else
                        // Interactive Pill - Tap to input coupon before shipping
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showCouponBottomSheet(context, originalVal, title);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 11,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _t('+ Add Coupon', '+ إضافة كود خصم'),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 6. Bottom Row: Date & Status Pill (Pending / Delivered)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date with small calendar icon
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),

                      // Status Badge (Pending / Delivered)
                      if (isDelivered)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCFCE7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                _t('Delivered', 'تم التوصيل'),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFEA580C)),
                              const SizedBox(width: 4),
                              Text(
                                _t('Pending', 'قيد الانتظار'),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String imageUrl, String title) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 106,
        height: 106,
        color: const Color(0xFFF8FAFC),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => _buildFallbackThumbnail(title),
              )
            : _buildFallbackThumbnail(title),
      ),
    );
  }

  Widget _buildFallbackThumbnail(String title) {
    IconData iconData = Icons.shopping_bag_outlined;
    Color iconColor = const Color(0xFF0284C7);
    Color bgColor = const Color(0xFFF0F9FF);
    final lower = title.toLowerCase();
    if (lower.contains('iphone') || lower.contains('phone')) {
      iconData = Icons.phone_iphone_rounded;
      iconColor = const Color(0xFF475569);
      bgColor = const Color(0xFFF1F5F9);
    } else if (lower.contains('playstation') || lower.contains('ps5')) {
      iconData = Icons.sports_esports_rounded;
      iconColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFEFF6FF);
    } else if (lower.contains('rolex') || lower.contains('watch')) {
      iconData = Icons.watch_rounded;
      iconColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFEF3C7);
    } else if (lower.contains('vacuum') || lower.contains('dyson')) {
      iconData = Icons.cleaning_services_rounded;
      iconColor = const Color(0xFF7C3AED);
      bgColor = const Color(0xFFFAF5FF);
    }

    return Container(
      color: bgColor,
      child: Center(
        child: Icon(iconData, size: 38, color: iconColor),
      ),
    );
  }

  void _showCouponBottomSheet(BuildContext context, double originalPrice, String productTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ApplyCouponModal(
        bid: bid,
        originalPrice: originalPrice,
        productTitle: productTitle,
        isArabic: isArabic,
        onCouponApplied: onCouponApplied,
      ),
    );
  }
}

// ─── Modal Bottom Sheet: Apply Coupon Before Shipping ────────────────────────

class _ApplyCouponModal extends StatefulWidget {
  final Map<String, dynamic> bid;
  final double originalPrice;
  final String productTitle;
  final bool isArabic;
  final VoidCallback onCouponApplied;

  const _ApplyCouponModal({
    required this.bid,
    required this.originalPrice,
    required this.productTitle,
    required this.isArabic,
    required this.onCouponApplied,
  });

  @override
  State<_ApplyCouponModal> createState() => _ApplyCouponModalState();
}

class _ApplyCouponModalState extends State<_ApplyCouponModal> {
  final _couponController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  String _t(String en, String ar) => widget.isArabic ? ar : en;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = _t('Please enter a coupon code', 'يرجى إدخال كود الخصم'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final orderId = widget.bid['order_id'] ?? widget.bid['orderId'];
      final productId = widget.bid['product_id'] ?? widget.bid['productId'] ?? widget.bid['id'];

      final int? numOrderId = orderId != null ? int.tryParse(orderId.toString()) : null;
      final int? numProductId = productId != null ? int.tryParse(productId.toString()) : null;

      final res = await apiService.applyCoupon(
        couponCode: code,
        orderId: numOrderId,
        productId: numProductId,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop();

        widget.onCouponApplied();

        final discount = res['data']?['discount_amount'] ?? '';
        final msg = discount.toString().isNotEmpty
            ? _t('Coupon $code applied! You saved \$$discount', 'تم تطبيق الكوبون $code بنجاح! وفرت \$$discount')
            : _t('Coupon $code applied successfully!', 'تم تطبيق الكوبون $code بنجاح!');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.confirmation_number_outlined, size: 20, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _t('Apply Influencer Coupon', 'تطبيق كود خصم المؤثرين'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                splashRadius: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Product Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_t("Order Amount", "قيمة الطلب")}: \$${widget.originalPrice.toStringAsFixed(widget.originalPrice.truncateToDouble() == widget.originalPrice ? 0 : 2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Coupon Code Input
          TextField(
            controller: _couponController,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: _t('Influencer Coupon Code', 'كود خصم المؤثر'),
              hintText: _t('e.g. AHMED10, NOOR10', 'مثال: AHMED10'),
              prefixIcon: const Icon(Icons.local_offer_outlined, color: Color(0xFF0284C7)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
              ),
            ),
            onSubmitted: (_) => _applyCoupon(),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
          ],

          const SizedBox(height: 18),

          // Action Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _applyCoupon,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _t('Apply Coupon', 'تطبيق الكود'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}
