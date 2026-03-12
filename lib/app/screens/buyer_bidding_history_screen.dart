import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/image_url_helper.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class BuyerBiddingHistoryScreen extends StatefulWidget {
  const BuyerBiddingHistoryScreen({super.key});

  @override
  State<BuyerBiddingHistoryScreen> createState() => _BuyerBiddingHistoryScreenState();
}

class _BuyerBiddingHistoryScreenState extends State<BuyerBiddingHistoryScreen> {
  List<Map<String, dynamic>> _bids = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = false; // Start as false, set to true when loading
  bool _isLoadingMore = false; // Guard for load more
  String? _errorMessage;
  String? _selectedStatus;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadMoreScheduled = false; // Prevent duplicate load more calls
  bool _hasInitialLoad = false; // Track if initial load has been attempted
  int? _currentUserId; // To track if winning
  List<Map<String, dynamic>> _displayBids = []; // Grouped bids to show in list

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    // Ensure load is called exactly once after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialLoad) {
        _hasInitialLoad = true;
        _loadBiddingHistory();
      }
    });
  }

  Future<void> _loadCurrentUserId() async {
    final id = await StorageService.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = id;
      });
    }
  }

  Future<void> _loadBiddingHistory({bool loadMore = false}) async {
    // Prevent race conditions
    if (loadMore) {
      if (_isLoadingMore || _isLoading || !_hasMore || _loadMoreScheduled) {
        if (kDebugMode) {
          print('[Buyer Bids] Load more blocked: isLoadingMore=$_isLoadingMore, isLoading=$_isLoading, hasMore=$_hasMore, scheduled=$_loadMoreScheduled');
        }
        return;
      }
      setState(() {
        _isLoadingMore = true;
        _loadMoreScheduled = true;
      });
    } else {
      // For initial load, allow it even if _isLoading is true (first time)
      if (_isLoading && _bids.isNotEmpty) {
        if (kDebugMode) {
          print('[Buyer Bids] Initial load blocked: already loading and has data');
        }
        return;
      }
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        if (!loadMore) {
          _bids = []; // Clear bids only on fresh load, not on filter change
        }
        _hasMore = true;
        _loadMoreScheduled = false;
      });
    }
    
    setState(() {
      _errorMessage = null;
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final limit = 20;
      
      if (kDebugMode) {
        print('[Buyer Bids] Fetching: status=$_selectedStatus, page=$page, limit=$limit, loadMore=$loadMore');
      }
      
      final response = await apiService.getBuyerBiddingHistory(
        status: _selectedStatus,
        page: page,
        limit: limit,
      );
      
      if (kDebugMode) {
        print('[Buyer Bids] API Response received: success=${response['success']}, dataCount=${(response['data'] as List?)?.length ?? 0}');
      }

      if (response['success'] == true) {
        final newBids = ((response['data'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final analytics = response['analytics'] as Map<String, dynamic>?;
        final pagination = response['pagination'] as Map<String, dynamic>?;
        
        // Debug: Log analytics types to verify backend is sending numbers
        if (kDebugMode && analytics != null) {
          print('[Buyer Bids] Analytics received:');
          analytics.forEach((key, value) {
            print('  $key: $value (type: ${value.runtimeType})');
          });
        }

        if (kDebugMode) {
          print('[Buyer Bids] Processing response: newBids=${newBids.length}, loadMore=$loadMore');
        }

        setState(() {
          if (loadMore) {
            _bids.addAll(newBids);
            _currentPage = page;
            _isLoadingMore = false;
            _loadMoreScheduled = false;
          } else {
            _bids = newBids;
            _currentPage = 1;
            _analytics = analytics;
            _isLoading = false; 
            _loadMoreScheduled = false;
          }
          
          // Trust backend as single source of truth
          _displayBids = _bids;

          _hasMore = pagination != null && 
                     pagination['pages'] != null && 
                     page < (pagination['pages'] as int);
        });
      } else {
        if (kDebugMode) {
          print('[Buyer Bids] API returned success=false: ${response['message']}');
        }
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load bidding history';
          _isLoading = false;
          _isLoadingMore = false;
          _loadMoreScheduled = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Buyer Bids] API Error: $e');
      }
      
      String errorMsg = 'Failed to load bidding history';
      if (e.toString().contains('Network')) {
        errorMsg = 'Network error. Please check your connection.';
      } else if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        errorMsg = 'Session expired. Please login again.';
      } else if (e.toString().contains('500')) {
        errorMsg = 'Server error. Please try again later.';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
        _isLoadingMore = false;
        _loadMoreScheduled = false;
      });
    }
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadBiddingHistory();
  }

  // Safe conversion helper - handles both string and numeric values
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove any currency symbols or commas
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      final parsed = double.tryParse(cleaned);
      if (kDebugMode && parsed == null) {
        print('[Buyer Bids] Warning: Could not parse string to double: "$value"');
      }
      return parsed ?? 0.0;
    }
    // Try to convert to string first, then parse
    try {
      final str = value.toString();
      final cleaned = str.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('[Buyer Bids] Error converting to double: $value (${value.runtimeType})');
      }
      return 0.0;
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(amount);
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return AppColors.green600;
      case 'active':
        return AppColors.blue600;
      case 'lost':
        return AppColors.red600;
      case 'ended':
        return AppColors.slate600;
      default:
        return AppColors.slate600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return Icons.emoji_events;
      case 'active':
        return Icons.gavel;
      case 'lost':
        return Icons.close;
      case 'ended':
        return Icons.timer_off;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Bids', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
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
      body: Column(
        children: [
          // Analytics Cards
          if (_analytics != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Bids',
                      value: '${_displayBids.length}',
                      color: AppColors.blue600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total Value',
                      value: _formatCurrency(_safeToDouble(_analytics?['total_amount_bid'] ?? 0.0)),
                      color: AppColors.green600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Win Rate',
                      value: '${_safeToDouble(_analytics?['win_rate'] ?? 0.0).toStringAsFixed(1)}%',
                      color: AppColors.yellow600,
                    ),
                  ),
                ],
              ),
            ),

          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Bids',
                    isSelected: _selectedStatus == null,
                    onSelected: () => _onStatusFilterChanged(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    isSelected: _selectedStatus == 'active',
                    onSelected: () => _onStatusFilterChanged('active'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Won',
                    isSelected: _selectedStatus == 'won',
                    onSelected: () => _onStatusFilterChanged('won'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Lost',
                    isSelected: _selectedStatus == 'lost',
                    onSelected: () => _onStatusFilterChanged('lost'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Ended',
                    isSelected: _selectedStatus == 'ended',
                    onSelected: () => _onStatusFilterChanged('ended'),
                  ),
                ],
              ),
            ),
          ),

          // Bids List
          Expanded(
            child: _isLoading && _bids.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _bids.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                                _loadBiddingHistory();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : !_isLoading && _bids.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gavel, size: 64, color: AppColors.slate400),
                                const SizedBox(height: 16),
                                Text(
                                  'No bids found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start bidding on products to see your history here',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadBiddingHistory(),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _displayBids.length + (_hasMore ? 1 : 0),
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                if (index == _displayBids.length) {
                                  if (!_isLoading && !_isLoadingMore && _hasMore && !_loadMoreScheduled) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted && !_isLoading && !_isLoadingMore && _hasMore && !_loadMoreScheduled) {
                                        _loadBiddingHistory(loadMore: true);
                                      }
                                    });
                                  }
                                  return _isLoadingMore
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox(height: 80);
                                }

                                  final bid = _displayBids[index];
                                  final status = (bid['bid_status'] ?? 'active').toString();
                                  final productTitle = bid['product_title'] ?? 'Unknown Product';
                                  final amount = _safeToDouble(bid['amount'] ?? 0.0);
                                  final bidDateStr = bid['bid_date'];
                                  final productId = bid['product_id'];
                                  final imageUrl = (bid['product_image'] ?? bid['image_url'] ?? bid['imageUrl'] ?? '') as String;
                                  
                                  // Parse auction end time if available
                                  DateTime? auctionEndTime;
                                  if (bid['auction_end_time'] != null) {
                                    try {
                                      auctionEndTime = DateTime.parse(bid['auction_end_time'].toString());
                                    } catch (e) {
                                      debugPrint('Error parsing auction_end_time: $e');
                                    }
                                  }

                                  // Check if user is the highest bidder
                                  final highestBidderId = bid['highest_bidder_id'];
                                  final isWinning = _currentUserId != null && highestBidderId != null && _currentUserId == highestBidderId;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: productId != null
                                          ? () => context.push('/product-details/$productId')
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 1. Product Image (Left)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(15),
                                              child: imageUrl.isNotEmpty
                                                   ? CachedNetworkImage(
                                                    imageUrl: ImageUrlHelper.fixImageUrl(imageUrl),
                                                    width: 85,
                                                    height: 85,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => Shimmer.fromColors(
                                                      baseColor: isDark ? AppColors.slate800 : AppColors.slate200,
                                                      highlightColor: isDark ? AppColors.slate700 : Colors.white,
                                                      child: Container(
                                                        width: 85,
                                                        height: 85,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    errorWidget: (_, __, ___) => Container(
                                                      width: 85,
                                                      height: 85,
                                                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                                                      child: Icon(Icons.image_not_supported, color: AppColors.slate400),
                                                    ),
                                                  )
                                                  : Container(
                                                      width: 85,
                                                      height: 85,
                                                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                                                      child: Icon(Icons.image, color: AppColors.slate400),
                                                    ),
                                            ),
                                            const SizedBox(width: 16),
                                            
                                            // 2. Details (Right)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Title and Winning Badge Row
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          productTitle,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            height: 1.3,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isWinning)
                                                        Container(
                                                          margin: const EdgeInsets.only(left: 8),
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFDFF6DD), // Light green
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: const Text(
                                                            'Winning',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF4CAF50), // Darker green
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  
                                                  const SizedBox(height: 8),
                                                  
                                                  // Current Price Label
                                                  Text(
                                                    'Current Price',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  
                                                  // Price Row
                                                  Text(
                                                    '\$${amount.toInt()}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF3498DB), // Blue as per design
                                                    ),
                                                  ),
                                                  
                                                  const SizedBox(height: 12),
                                                  
                                                  // Countdown Timer Bar (Blue background)
                                                  if (auctionEndTime != null && status == 'active')
                                                    _HistoryCountdownBar(endTime: auctionEndTime)
                                                  else
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        status.toUpperCase(),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.grey,
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
                                  );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.blue600,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.cardWhite
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}


class _HistoryCountdownBar extends StatefulWidget {
  final DateTime endTime;
  const _HistoryCountdownBar({required this.endTime});

  @override
  State<_HistoryCountdownBar> createState() => _HistoryCountdownBarState();
}

class _HistoryCountdownBarState extends State<_HistoryCountdownBar> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final diff = widget.endTime.difference(now);
    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
    if (diff.isNegative) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    if (_remaining == Duration.zero) return "Ended";
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    
    return "${days.toString().padLeft(2, '0')}d   ${hours.toString().padLeft(2, '0')}h   ${minutes.toString().padLeft(2, '0')}m   ${seconds.toString().padLeft(2, '0')}s";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4B89FF), // Bright blue bar
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          _formatTime(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
