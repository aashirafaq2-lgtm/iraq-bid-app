import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../widgets/bottom_nav_bar.dart';

class BuyerBiddingHistoryScreen extends StatefulWidget {
  const BuyerBiddingHistoryScreen({super.key});

  @override
  State<BuyerBiddingHistoryScreen> createState() =>
      _BuyerBiddingHistoryScreenState();
}

class _BuyerBiddingHistoryScreenState extends State<BuyerBiddingHistoryScreen> {
  List<Map<String, dynamic>> _bids = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _selectedStatus; // null (all), 'active', 'won', 'lost'
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadMoreScheduled = false;

  static const int usdToIqdRate = 1520;

  @override
  void initState() {
    super.initState();
    _loadBiddingHistory();
  }

  Future<void> _loadBiddingHistory({bool loadMore = false}) async {
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
        _bids = [];
        _hasMore = true;
        _loadMoreScheduled = false;
        _errorMessage = null;
      });
    }

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final response = await apiService.getBuyerBiddingHistory(
        status: _selectedStatus,
        page: page,
        limit: 20,
      );

      if (response['success'] == true) {
        final newBids = ((response['data'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final analytics = response['analytics'] as Map<String, dynamic>?;
        final pagination = response['pagination'] as Map<String, dynamic>?;

        setState(() {
          if (loadMore) {
            _bids.addAll(newBids);
          } else {
            _bids = newBids;
            _analytics = analytics;
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

  void _onStatusFilter(String? status) {
    if (_selectedStatus != status) {
      setState(() => _selectedStatus = status);
      _loadBiddingHistory();
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
                isArabic ? 'سجل المزايدات الحية' : 'Live Bid Activity',
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
                  onPressed: () => _loadBiddingHistory(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                // Analytics Summary Metrics
                _buildAnalyticsBar(isArabic),

                // Status Filter Chips
                _buildStatusFilters(isArabic),

                const SizedBox(height: 8),

                // Bids List
                Expanded(child: _buildBidsList(isArabic)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsBar(bool isArabic) {
    final totalBids = _analytics?['total_bids'] ?? _bids.length;
    final activeBids = _analytics?['active_bids'] ?? 0;
    final wonBids = _analytics?['won_bids'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            title: isArabic ? 'إجمالي المزايدات' : 'Total Bids',
            value: '$totalBids',
            color: const Color(0xFF0066FF),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          _buildMetric(
            title: isArabic ? 'مزادات جارية' : 'In Progress',
            value: '$activeBids',
            color: const Color(0xFFF59E0B),
          ),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          _buildMetric(
            title: isArabic ? 'مزادات رابحة' : 'Auctions Won',
            value: '$wonBids',
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilters(bool isArabic) {
    final filters = [
      {'key': null, 'en': 'All', 'ar': 'الكل'},
      {'key': 'active', 'en': 'Active', 'ar': 'جارية'},
      {'key': 'won', 'en': 'Won', 'ar': 'رابحة'},
      {'key': 'lost', 'en': 'Outbid', 'ar': 'تم تجاوزه'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatus == f['key'];
          final label = isArabic ? f['ar']! : f['en']!;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onStatusFilter(f['key']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBidsList(bool isArabic) {
    if (_isLoading && _bids.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0066FF),
        ),
      );
    }

    if (_errorMessage != null && _bids.isEmpty) {
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
                onPressed: () => _loadBiddingHistory(),
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

    if (_bids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  size: 40,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isArabic ? 'لا توجد مزايدات مسجلة' : 'No Bids Found',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'ابدأ المزايدة على المنتجات الحية لتظهر في سجلك هنا.'
                    : 'Place your first bid on live items to see your tracking record.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0066FF),
      onRefresh: () => _loadBiddingHistory(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _bids.length + (_hasMore && _isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _bids.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_loadMoreScheduled) {
                _loadMoreScheduled = true;
                _loadBiddingHistory(loadMore: true);
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

          final bid = _bids[index];
          final productId = (bid['product_id'] ??
              bid['productId'] ??
              bid['id']) as int?;
          final title = (bid['product_title'] ??
              bid['title'] ??
              'Product') as String;
          final imageUrl = (bid['product_image'] ??
              bid['image_url'] ??
              bid['imageUrl'] ??
              '') as String;
          final bidAmount = _safeToDouble(bid['amount'] ?? 0);
          final status =
              (bid['bid_status'] ?? bid['status'] ?? 'active').toString().toLowerCase();

          final iqdAmount = (bidAmount * usdToIqdRate).toInt();
          final formattedIqd = iqdAmount.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},');

          return InkWell(
            onTap: () {
              if (productId != null) {
                context.push('/product/$productId');
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 74,
                      height: 74,
                      color: const Color(0xFFF8FAFC),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBadge(status, isArabic),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '\$${bidAmount.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0066FF),
                              ),
                            ),
                            const SizedBox(width: 6),
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
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Color(0xFFCBD5E1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isArabic) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'won':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        text = isArabic ? 'فوز بالصفقة' : 'WON';
        break;
      case 'lost':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        text = isArabic ? 'تم تجاوزه' : 'OUTBID';
        break;
      case 'active':
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        text = isArabic ? 'مزايدة جارية' : 'ACTIVE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
