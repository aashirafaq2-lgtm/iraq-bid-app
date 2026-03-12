import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/image_url_helper.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _bannerImages = [];
  final Set<String> _failedUrls = {}; // Track failed image URLs to prevent retries
  bool _isLoading = true;
  bool _hasError = false;

  // No fallback banners - Hide carousel if no banners from API
  // This prevents 404 errors and app hanging

  @override
  void initState() {
    super.initState();
    // Load banners from API (Production-ready)
    _loadBanners();
    // Auto-scroll slider will start after banners load
  }

  /// Load banners from backend API with fallback
  Future<void> _loadBanners() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Fetch banners from API (handles 404 and other errors gracefully)
      final banners = await apiService.getBanners();
      
      if (!mounted) return; // Check again after async operation
      
      if (banners.isNotEmpty) {
        // Extract image URLs from API response (Cloudinary URLs or local URLs)
        final imageUrls = banners
            .map((banner) {
              // Try multiple possible field names
              final url = banner['imageUrl'] ?? 
                         banner['image_url'] ?? 
                         banner['url'] ?? 
                         '';
              return url.toString();
            })
            .where((url) => url.isNotEmpty)
            .map((url) {
              // Fix URLs (handles Cloudinary & relative URLs)
              final fixedUrl = ImageUrlHelper.fixImageUrl(url);
              if (kDebugMode) {
                print('🖼️ Banner URL: $url -> $fixedUrl');
              }
              return fixedUrl;
            })
            .where((url) => url.isNotEmpty)
            // Filter out Unsplash URLs and previously failed URLs
            .where((url) => !url.contains('unsplash.com') && !_failedUrls.contains(url))
            .toList();
        
        if (imageUrls.isNotEmpty) {
          if (kDebugMode) {
            print('✅ Loaded ${imageUrls.length} banner images');
          }
          if (mounted) {
            setState(() {
              _bannerImages = imageUrls;
              _isLoading = false;
              _hasError = false;
            });
            _startAutoScroll();
          }
          return;
        } else {
          if (kDebugMode) {
            print('⚠️ No valid image URLs found in banners');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ No banners returned from API');
        }
      }
      
      // If API returns empty or no images, hide carousel
      if (kDebugMode) {
        print('⚠️ No banners available - hiding carousel');
      }
      if (mounted) {
        setState(() {
          _bannerImages = [];
          _isLoading = false;
          _hasError = false;
        });
      }
      // Don't start auto-scroll if no banners
    } catch (e) {
      // On error, hide carousel gracefully (no error thrown to user)
      if (kDebugMode) {
        print('❌ Error loading banners: $e');
        if (e is DioException) {
          print('   DioException Type: ${e.type}');
          print('   Status Code: ${e.response?.statusCode}');
          print('   Request URL: ${e.requestOptions.uri}');
          if (e.response?.statusCode == 404) {
            print('   ℹ️ 404 - Banners endpoint not found or no banners available');
            print('   This is expected if no banners are configured');
          }
        }
        print('   Hiding carousel gracefully (no error shown to user)');
      }
      if (mounted) {
        setState(() {
          _bannerImages = [];
          _isLoading = false;
          _hasError = false; // Don't mark as error - just no banners available
        });
      }
      // Don't start auto-scroll if error
    }
  }

  void _startAutoScroll() {
    // Only start auto-scroll if we have banners
    if (_bannerImages.isEmpty) return;
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _pageController.hasClients && _bannerImages.isNotEmpty) {
        if (_currentPage < _bannerImages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while fetching banners
    if (_isLoading) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFF1F3F5),
          highlightColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // Show empty state if no banners available
    if (_bannerImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200, // Increased height for better HD image display (BestBid.tech style)
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        children: [
          // Image Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentPage = index;
                });
              }
            },
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image - Production-ready with caching (Cloudinary support)
                      // Skip Unsplash URLs to prevent 404 errors
                      _bannerImages[index].contains('unsplash.com')
                          ? Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: const Color(0xFFF1F3F5),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: ImageUrlHelper.fixImageUrl(_bannerImages[index]), // Ensure URL is properly formatted
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              filterQuality: FilterQuality.high,
                              memCacheWidth: 1920, // Cache at HD resolution for performance
                              httpHeaders: const {'Accept': 'image/*'},
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: const Color(0xFFF1F3F5),
                                highlightColor: Colors.white,
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                // Mark URL as failed and remove from list to prevent retries
                                if (kDebugMode) {
                                  print('❌ Banner image failed to load: $url');
                                  print('   Removing from carousel to prevent 404 spam');
                                }
                                // Remove failed URL from list
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _failedUrls.add(url);
                                      _bannerImages.removeWhere((u) => u == url);
                                      // Reset page if current page is out of bounds
                                      if (_currentPage >= _bannerImages.length && _bannerImages.isNotEmpty) {
                                        _currentPage = _bannerImages.length - 1;
                                      } else if (_bannerImages.isEmpty) {
                                        _currentPage = 0;
                                      }
                                    });
                                  }
                                });
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: const Color(0xFFF1F3F5),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                );
                              },
                            ),
                      // Gradient Overlay - App Theme Colors
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0A3069).withOpacity(0.3), // Dark Blue
                              const Color(0xFF2BA8E0).withOpacity(0.2), // Light Blue
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Previous Button (Left)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_pageController.hasClients) {
                      final previousPage = _currentPage > 0
                          ? _currentPage - 1
                          : _bannerImages.length - 1;
                      _pageController.animateToPage(
                        previousPage,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: isDark ? Colors.white70 : const Color(0xFF222222),
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Next Button (Right)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_pageController.hasClients) {
                      final nextPage = _currentPage < _bannerImages.length - 1
                          ? _currentPage + 1
                          : 0;
                      _pageController.animateToPage(
                        nextPage,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.6)
                              : Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white70 : const Color(0xFF222222),
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Page Indicators (dots below)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _bannerImages.length,
                    (index) => Container(
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? (_currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4))
                            : (_currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}





