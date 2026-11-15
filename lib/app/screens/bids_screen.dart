import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../models/bid_model.dart';
import '../utils/image_url_helper.dart';

class BidsScreen extends StatefulWidget {
  const BidsScreen({super.key});

  @override
  State<BidsScreen> createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _listFade;

  List<BidModel> _bids = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  static const double _kRate = 1520;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _listFade =
        CurvedAnimation(parent: _listController, curve: Curves.easeOut);

    _loadBids();
  }

  Future<void> _loadBids() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await apiService.getMyBids();
      setState(() {
        _bids = result;
        _isLoading = false;
      });
      _headerController.forward();
      Future.delayed(
          const Duration(milliseconds: 200), () => _listController.forward());
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _headerController.forward();
    }
  }

  List<BidModel> get _filteredBids {
    if (_selectedFilter == 'all') return _bids;
    return _bids
        .where((b) =>
            (b.auctionStatus ?? b.productStatus ?? '')
                .toLowerCase() ==
            _selectedFilter)
        .toList();
  }

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.languageNotifier,
      builder: (context, _, __) {
        return Directionality(
          textDirection:
              _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(),
              ],
              body: _isLoading
                  ? _buildLoader()
                  : _errorMessage != null
                      ? _buildError()
                      : _filteredBids.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0284C7),
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _t('My Bids', 'مزاياتي'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(38),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withAlpha(77)),
                            ),
                            child: Text(
                              '${_bids.length} ${_t('Bids', 'مزاد')}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildFilterChips(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', _t('All', 'الكل')),
      ('active', _t('Active', 'نشط')),
      ('won', _t('Won', 'فاز')),
      ('outbid', _t('Outbid', 'تجاوزت')),
      ('lost', _t('Lost', 'خسر')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withAlpha(77),
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0284C7)
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _t('Connection Error', 'خطأ في الاتصال'),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBids,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_t('Try Again', 'حاول مرة أخرى')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return FadeTransition(
      opacity: _listFade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.gavel_rounded,
                    color: Color(0xFF0284C7), size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                _t('No Bids Yet', 'لا مزايدات بعد'),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Text(
                _t(
                  'Start bidding on products to see your bid history here.',
                  'ابدأ المزايدة على المنتجات لترى سجل مزاياتك هنا.',
                ),
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: Text(_t('Explore Auctions', 'استكشف المزادات')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final bids = _filteredBids;
    return FadeTransition(
      opacity: _listFade,
      child: RefreshIndicator(
        color: const Color(0xFF0284C7),
        onRefresh: _loadBids,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: bids.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration:
                  Duration(milliseconds: 400 + index * 60),
              curve: Curves.easeOut,
              builder: (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                    offset: Offset(0, 30 * (1 - v)), child: child),
              ),
              child: _BidCard(
                bid: bids[index],
                isArabic: _isArabic,
                rate: _kRate,
                onTap: () => context
                    .push('/product/${bids[index].productId}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Bid Card ────────────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final bool isArabic;
  final double rate;
  final VoidCallback onTap;

  const _BidCard({
    required this.bid,
    required this.isArabic,
    required this.rate,
    required this.onTap,
  });

  String _t(String en, String ar) => isArabic ? ar : en;

  String get _statusKey =>
      (bid.auctionStatus ?? bid.productStatus ?? '').toLowerCase();

  Color get _statusColor {
    if (_statusKey == 'won' || _statusKey == 'active') {
      return const Color(0xFF10B981);
    }
    if (_statusKey == 'outbid') return const Color(0xFFF59E0B);
    if (_statusKey == 'lost') return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }

  String get _statusLabel {
    if (_statusKey == 'won') return _t('Won', 'فاز');
    if (_statusKey == 'active') return _t('Active', 'نشط');
    if (_statusKey == 'outbid') return _t('Outbid', 'تجاوزت');
    if (_statusKey == 'lost') return _t('Lost', 'خسر');
    return _statusKey;
  }

  IconData get _statusIcon {
    if (_statusKey == 'won') return Icons.emoji_events_rounded;
    if (_statusKey == 'active') return Icons.local_fire_department_rounded;
    if (_statusKey == 'outbid') return Icons.trending_up_rounded;
    if (_statusKey == 'lost') return Icons.close_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final amount = bid.amount;
    final productTitle = bid.productTitle ?? _t('Auction Item', 'عنصر المزاد');
    final imageUrl = bid.productImage != null
        ? ImageUrlHelper.fixImageUrl(bid.productImage)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${(amount * rate).toStringAsFixed(0)} IQD)',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon,
                              color: _statusColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                                color: _statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                isArabic
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: const Color(0xFFCBD5E1),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFF94A3B8), size: 30),
    );
  }
}
