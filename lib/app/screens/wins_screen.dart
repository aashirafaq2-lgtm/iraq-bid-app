import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../utils/image_url_helper.dart';

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
      });
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      
      if (kDebugMode) {
        print('[Wins Screen] Fetching won bids: page=$page, limit=20');
      }
      
      final response = await apiService.getBuyerBiddingHistory(
        status: 'won', // Filter for won bids only
        page: page,
        limit: 20,
      );

      if (kDebugMode) {
        print('[Wins Screen] API Response: success=${response['success']}, dataCount=${(response['data'] as List?)?.length ?? 0}');
      }

      if (response['success'] == true) {
        final newBids = ((response['data'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final pagination = response['pagination'] as Map<String, dynamic>?;
        
        if (kDebugMode) {
          print('[Wins Screen] Parsed ${newBids.length} won bids');
          if (newBids.isNotEmpty) {
            print('[Wins Screen] Sample bid: ${newBids[0]}');
          }
        }
        
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
        final errorMsg = response['message'] as String? ?? 'Failed to load wins';
        if (kDebugMode) {
          print('[Wins Screen] API Error: $errorMsg');
        }
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
          _isLoadingMore = false;
          _loadMoreScheduled = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Wins Screen] Exception: $e');
        print('[Wins Screen] Stack trace: ${StackTrace.current}');
      }
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
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

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Wins'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: _isLoading && _wonBids.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _wonBids.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadWonBids(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _wonBids.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: isDark ? AppColors.slate400 : AppColors.slate400),
                          const SizedBox(height: 16),
                          Text(
                            'No wins yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start bidding to win auctions!',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadWonBids(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _wonBids.length + (_hasMore && _isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _wonBids.length) {
                            // Load more indicator
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_loadMoreScheduled) {
                                _loadMoreScheduled = true;
                                _loadWonBids(loadMore: true);
                              }
                            });
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final bid = _wonBids[index];
                          
                          // Backend returns flat structure with product_* fields
                          // Structure: bid_id, amount, bid_date, product_id, product_title, product_image, etc.
                          final productId = (bid['product_id'] ?? bid['productId'] ?? bid['id']) as int?;
                          final title = (bid['product_title'] ?? bid['title'] ?? 'Unknown Product') as String;
                          final imageUrl = (bid['product_image'] ?? bid['image_url'] ?? bid['imageUrl'] ?? '') as String;
                          final currentBid = _safeToDouble(bid['amount'] ?? bid['current_highest_bid'] ?? 0);
                          final bidStatus = (bid['bid_status'] ?? 'won') as String;
                          
                          // Parse end time - backend returns auction_end_time
                          DateTime endTime = DateTime.now();
                          try {
                            if (bid['auction_end_time'] != null) {
                              endTime = DateTime.parse(bid['auction_end_time'].toString());
                            } else if (bid['bid_date'] != null) {
                              endTime = DateTime.parse(bid['bid_date'].toString());
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print('[Wins Screen] Error parsing date: $e');
                            }
                          }
                          
                          if (productId == null) {
                            if (kDebugMode) {
                              print('[Wins Screen] Product ID is null for bid: $bid');
                            }
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        ImageUrlHelper.fixImageUrl(imageUrl),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        headers: const {'Accept': 'image/*'},
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: isDark ? AppColors.slate800 : AppColors.slate200,
                                            child: Icon(Icons.image, color: isDark ? AppColors.slate400 : AppColors.slate400),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                                        child: Icon(Icons.image, color: isDark ? AppColors.slate400 : AppColors.slate400),
                                      ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.green600.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Won',
                                          style: TextStyle(
                                            color: AppColors.green600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Winning Bid: \$${_formatCurrency(currentBid)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Won on: ${_formatDate(endTime)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                onPressed: () {
                                  if (productId != null) {
                                    context.push('/product-details/$productId');
                                  }
                                },
                              ),
                              onTap: () {
                                if (productId != null) {
                                  context.push('/product-details/$productId');
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

