import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/language_service.dart';

class LuxuryBannerCarousel extends StatefulWidget {
  const LuxuryBannerCarousel({super.key});

  @override
  State<LuxuryBannerCarousel> createState() => _LuxuryBannerCarouselState();
}

class _LuxuryBannerCarouselState extends State<LuxuryBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final List<Map<String, dynamic>> _banners = [
    {
      'badge_en': 'LIMITED TIME',
      'badge_ar': 'لفترة محدودة',
      'title_en': 'Special Deals',
      'title_ar': 'عروض استثنائية',
      'subtitle_en': 'Bid & Save on Amazing Products',
      'subtitle_ar': 'زايد ووفر على أفضل الأجهزة الذكية',
      'discount_en': 'UP TO\n50% OFF',
      'discount_ar': 'خصم حتى\n50%',
      'bg_gradient': [Color(0xFFEBF4FF), Color(0xFFD6E8FE)],
      'btn_color': Color(0xFFEA580C),
      'image_url': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
    },
    {
      'badge_en': 'EXCLUSIVE WATCHES',
      'badge_ar': 'ساعات فاخرة',
      'title_en': 'Luxury Timepieces',
      'title_ar': 'أرقى الساعات العالمية',
      'subtitle_en': 'Certified Swiss & Designer Watches',
      'subtitle_ar': 'ساعات سويسرية وأصلية 100%',
      'discount_en': 'TOP\nTIER',
      'discount_ar': 'إصدار\nحصري',
      'bg_gradient': [Color(0xFFF5F3FF), Color(0xFFDDD6FE)],
      'btn_color': Color(0xFF7C3AED),
      'image_url': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
    },
    {
      'badge_en': 'GAMING ZONE',
      'badge_ar': 'عالم الألعاب',
      'title_en': 'Next-Gen Consoles',
      'title_ar': 'أقوى منصات الألعاب',
      'subtitle_en': 'PS5, Xbox & High-End Peripherals',
      'subtitle_ar': 'أجهزة بلايستيشن وإكس بوكس وملحقاتها',
      'discount_en': 'HOT\nAUCTION',
      'discount_ar': 'مزاد\nمشتعل',
      'bg_gradient': [Color(0xFFFEF2F2), Color(0xFFFECACA)],
      'btn_color': Color(0xFFEF4444),
      'image_url': 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800&q=80',
    },
    {
      'badge_en': 'SMART HOME',
      'badge_ar': 'المنزل الذكي',
      'title_en': 'Home Essentials',
      'title_ar': 'أجهزة المطبخ والمنزل',
      'subtitle_en': 'Modern Living at Lowest Winning Bids',
      'subtitle_ar': 'حياة عصرية بأقل تكاليف الفوز بالمزاد',
      'discount_en': 'SAVE\nBIG',
      'discount_ar': 'توفير\nكبير',
      'bg_gradient': [Color(0xFFECFDF5), Color(0xFFA7F3D0)],
      'btn_color': Color(0xFF10B981),
      'image_url': 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=800&q=80',
    },
    {
      'badge_en': 'APPLE & FLAGSHIPS',
      'badge_ar': 'أبل وهواتف قمة',
      'title_en': 'Flagship Mobiles',
      'title_ar': 'أحدث الهواتف الذكية',
      'subtitle_en': 'iPhone 16 Pro, Galaxy S25 Ultra',
      'subtitle_ar': 'آيفون وجالكسي بأعلى جودة وضمان',
      'discount_en': 'VERIFIED\nSTOCK',
      'discount_ar': 'بضاعة\nموثقة',
      'bg_gradient': [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
      'btn_color': Color(0xFFD97706),
      'image_url': 'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageService.isArabic;

    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final b = _banners[index];
              final gradient = b['bg_gradient'] as List<Color>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (b['btn_color'] as Color).withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Right Image
                      Positioned(
                        top: -10,
                        bottom: -10,
                        right: isArabic ? null : -15,
                        left: isArabic ? -15 : null,
                        width: 200,
                        child: CachedNetworkImage(
                          imageUrl: b['image_url'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.transparent),
                          errorWidget: (context, url, error) => const Icon(Icons.shopping_bag_outlined, size: 40),
                        ),
                      ),

                      // Gradient Overlay for text readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                              end: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                              colors: [
                                gradient.first.withValues(alpha: 0.95),
                                gradient.first.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Text and Action Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Badge Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isArabic ? b['badge_ar'] : b['badge_en'],
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Headline Title
                            Text(
                              isArabic ? b['title_ar'] : b['title_en'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Subtitle
                            SizedBox(
                              width: 175,
                              child: Text(
                                isArabic ? b['subtitle_ar'] : b['subtitle_en'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Action Button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: b['btn_color'] as Color,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (b['btn_color'] as Color).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isArabic ? 'تصفح الآن' : 'Shop Now',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isArabic ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == idx ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == idx ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
