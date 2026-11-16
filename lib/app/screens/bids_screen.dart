import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import '../models/bid_model.dart';
import '../utils/image_url_helper.dart';
import '../widgets/bottom_nav_bar.dart';

class BidsScreen extends StatefulWidget {
  const BidsScreen({super.key});

  @override
  State<BidsScreen> createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> with SingleTickerProviderStateMixin {
  List<BidModel> _bids = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Real-time countdown timer to update time left live
  Timer? _tickerTimer;

  // Pulse animation for Winning badges
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _loadBids();

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadBids() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await apiService.getMyBids();
      if (mounted) {
        setState(() {
          _bids = result;
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

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, _, __) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                            : _bids.isEmpty
                                ? _buildEmpty()
                                : _buildList(),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const IraqBidBottomNavBar(currentRoute: '/bids'),
          ),
        );
      },
    );
  }

  // Exact Header matching reference (Notification Bell on Left with red unread dot, Centered Title "Bids")
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

          // Centered Header Title "Bids"
          Text(
            _t('Bids', 'المزايدات'),
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
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
        strokeWidth: 2.5,
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
            const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? _t('Failed to load bids', 'فشل تحميل المزايدات'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBids,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_t('Retry', 'إعادة المحاولة')),
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
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel_rounded, color: Color(0xFF0284C7), size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              _t('No Bids Yet', 'لا توجد مزايدات بعد'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Place bids on live auctions to see them here in real-time.',
                'شارك في المزادات الحية لتراها هنا فورياً.',
              ),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: Text(_t('Explore Auctions', 'استكشف المزادات')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: const Color(0xFF0284C7),
      onRefresh: _loadBids,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
        itemCount: _bids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final bid = _bids[index];
          return _ExactBidCard(
            bid: bid,
            isArabic: _isArabic,
            scaleAnim: _scaleAnimation,
            onTap: () => context.push('/product/${bid.productId}'),
          );
        },
      ),
    );
  }
}

// ─── Exact Bid Card Matching 100% Reference Screen ──────────────────────────

class _ExactBidCard extends StatelessWidget {
  final BidModel bid;
  final bool isArabic;
  final Animation<double> scaleAnim;
  final VoidCallback onTap;

  const _ExactBidCard({
    required this.bid,
    required this.isArabic,
    required this.scaleAnim,
    required this.onTap,
  });

  String _t(String en, String ar) => isArabic ? ar : en;

  // Calculate formatted countdown string (01h 11m 41s)
  String _formatTimeLeft() {
    final now = DateTime.now();
    DateTime endTime;

    if (bid.auctionEndTime != null) {
      endTime = bid.auctionEndTime!;
    } else if (bid.hoursLeft != null && bid.hoursLeft! > 0) {
      endTime = now.add(Duration(seconds: (bid.hoursLeft! * 3600).toInt()));
    } else {
      endTime = bid.createdAt.add(const Duration(hours: 24));
    }

    final diff = endTime.difference(now);
    if (diff.isNegative || diff.inSeconds <= 0) {
      return '00h 00m 00s';
    }

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return '${hours}h   ${minutes}m   ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final title = bid.productTitle ?? _t('Auction Item', 'عنصر المزاد');
    final imageUrl = bid.productImage != null ? ImageUrlHelper.fixImageUrl(bid.productImage!) : '';
    final amountVal = bid.amount.toInt();
    final timeLeftStr = _formatTimeLeft();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 122,
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
          children: [
            // Left Square Image with rounded corners
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
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
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                        ),
                ),
              ),
            ),

            // Right Info Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Title (2 lines max)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),

                    // Price & Winning Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _t('Current Price', 'السعر الحالي'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '\$ $amountVal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),

                        // Animated Winning Badge with Trophy
                        ScaleTransition(
                          scale: scaleAnim,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 14,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _t('Winning', 'فائز'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Time Left Pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              timeLeftStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16A34A),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
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
