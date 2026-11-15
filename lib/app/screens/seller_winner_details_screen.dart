import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
import '../utils/image_url_helper.dart';

class SellerWinnerDetailsScreen extends StatefulWidget {
  final String productId;

  const SellerWinnerDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<SellerWinnerDetailsScreen> createState() =>
      _SellerWinnerDetailsScreenState();
}

class _SellerWinnerDetailsScreenState extends State<SellerWinnerDetailsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _winnerData;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _pulseAnim;

  static const double _kRate = 1520;

  bool get _isArabic => LanguageService.isArabic;
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
        lowerBound: 0.95,
        upperBound: 1.05)
      ..repeat(reverse: true);

    _entryFade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _pulseAnim = _pulseController;

    _loadWinnerData();
  }

  Future<void> _loadWinnerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) throw Exception('Invalid product ID');

      final response = await apiService.getSellerWinner(productId);
      if (response['success'] == true) {
        setState(() {
          _winnerData = response['data'];
          _isLoading = false;
        });
        _entryController.forward();
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? _t('Failed to load winner details', 'فشل تحميل تفاصيل الفائز');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return _t('N/A', 'غير متوفر');
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
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
            body: CustomScrollView(
              slivers: [
                _buildAppBar(),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0284C7)),
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(child: _buildError())
                else if (_winnerData == null)
                  SliverFillRemaining(child: _buildNoWinner())
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildWinnerHero(),
                        const SizedBox(height: 16),
                        _buildProductCard(),
                        const SizedBox(height: 16),
                        _buildBidCard(),
                        const SizedBox(height: 16),
                        _buildWinnerContactCard(),
                        const SizedBox(height: 16),
                        _buildActionButton(),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0284C7),
      leading: IconButton(
        icon: Icon(
          _isArabic
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/seller-dashboard');
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Auction Winner', 'الفائز بالمزاد'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t('Winner details for your auction', 'تفاصيل الفائز في مزادك'),
                    style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
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
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _t('Something went wrong', 'حدث خطأ ما'),
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
              onPressed: _loadWinnerData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_t('Retry', 'إعادة المحاولة')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWinner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.gavel_rounded,
                  color: Color(0xFF94A3B8), size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              _t('No Winner Yet', 'لا يوجد فائز بعد'),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                'No bids were placed on this auction.',
                'لم يتم تقديم أي عروض في هذا المزاد.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerHero() {
    final winner = _winnerData?['winner'];
    final name = winner?['name'] ?? winner?['full_name'] ?? _t('Winner', 'الفائز');

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFF59E0B).withAlpha(77)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withAlpha(26),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t('Congratulations!', 'تهانينا!'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF78350F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t('has won your auction!', 'فاز في مزادك!'),
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF92400E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    final product = _winnerData?['product'];
    if (product == null) return const SizedBox.shrink();

    final imgUrl = product['image_url'] != null
        ? ImageUrlHelper.fixImageUrl(product['image_url'])
        : null;
    final title = product['title'] ?? _t('Product', 'المنتج');

    return FadeTransition(
      opacity: _entryFade,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imgUrl != null && imgUrl.isNotEmpty
                    ? Image.network(imgUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFF94A3B8)),
                        ))
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.inventory_2_rounded,
                            color: Color(0xFF94A3B8)),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Auctioned Product', 'المنتج المُزاد'),
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidCard() {
    final bid = _winnerData?['bid'] ?? _winnerData?['winning_bid'];
    if (bid == null) return const SizedBox.shrink();

    final amount =
        (bid['amount'] ?? bid['bid_amount'] ?? 0.0).toDouble();
    final bidDate = _formatDate(bid['created_at'] ?? bid['bid_time']);

    return FadeTransition(
      opacity: _entryFade,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withAlpha(18),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Winning Bid', 'العرض الفائز'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF)),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${(amount * _kRate).toStringAsFixed(0)} IQD',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  bidDate,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerContactCard() {
    final winner = _winnerData?['winner'];
    if (winner == null) return const SizedBox.shrink();

    final name = winner['name'] ?? winner['full_name'] ?? _t('Winner', 'الفائز');
    final email = winner['email'] ?? _t('N/A', 'غير متوفر');
    final phone = winner['phone'] ?? _t('N/A', 'غير متوفر');

    return FadeTransition(
      opacity: _entryFade,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Winner Contact Info', 'معلومات تواصل الفائز'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
                icon: Icons.person_rounded,
                label: _t('Name', 'الاسم'),
                value: name.toString()),
            const Divider(height: 24),
            _InfoRow(
                icon: Icons.email_rounded,
                label: _t('Email', 'البريد الإلكتروني'),
                value: email.toString()),
            const Divider(height: 24),
            _InfoRow(
                icon: Icons.phone_rounded,
                label: _t('Phone', 'الهاتف'),
                value: phone.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final winner = _winnerData?['winner'];
    final phone = winner?['phone'];

    return FadeTransition(
      opacity: _entryFade,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            if (phone != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${_t('Contacting', 'الاتصال بـ')} $phone...'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          icon: const Icon(Icons.phone_rounded, size: 20),
          label: Text(
            _t('Contact Winner', 'تواصل مع الفائز'),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0284C7), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
