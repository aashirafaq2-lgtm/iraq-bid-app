import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../utils/image_url_helper.dart';

class SellerWinnerDetailsScreen extends StatefulWidget {
  final String productId;

  const SellerWinnerDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<SellerWinnerDetailsScreen> createState() => _SellerWinnerDetailsScreenState();
}

class _SellerWinnerDetailsScreenState extends State<SellerWinnerDetailsScreen> {
  Map<String, dynamic>? _winnerData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWinnerData();
  }

  Future<void> _loadWinnerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) {
        throw Exception('Invalid product ID');
      }

      final response = await apiService.getSellerWinner(productId);
      if (response['success'] == true) {
        setState(() {
          _winnerData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load winner details';
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

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Winner Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/seller-dashboard');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
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
                        onPressed: _loadWinnerData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _winnerData == null
                  ? const Center(child: Text('No winner data'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Product Info Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Information',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_winnerData!['product']?['image_url'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        ImageUrlHelper.fixImageUrl(_winnerData!['product']?['image_url']),
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            color: AppColors.slate200,
                                            child: const Icon(Icons.image, size: 64),
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _winnerData!['product']?['title'] ?? 'Product',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Final Bid',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '\$${_formatCurrency((_winnerData!['product']?['final_bid'] ?? 0.0).toDouble())}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.green600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Auction Ended',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        _formatDate(_winnerData!['product']?['auction_end_time']),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Winner Info Card
                          if (_winnerData!['winner'] != null)
                            Card(
                              color: AppColors.green50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.emoji_events, color: AppColors.green600),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Winner Information',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.green600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _InfoRow(
                                      label: 'Name',
                                      value: _winnerData!['winner']?['name'] ?? 'N/A',
                                      icon: Icons.person,
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoRow(
                                      label: 'Email',
                                      value: _winnerData!['winner']?['email'] ?? 'N/A',
                                      icon: Icons.email,
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoRow(
                                      label: 'Phone',
                                      value: _winnerData!['winner']?['phone'] ?? 'N/A',
                                      icon: Icons.phone,
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          final phone = _winnerData!['winner']?['phone'];
                                          if (phone != null) {
                                            // You can implement phone call functionality here
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Calling $phone...'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.phone),
                                        label: const Text('Contact Winner'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.green600,
                                          foregroundColor: AppColors.cardWhite,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline, size: 64, color: AppColors.slate400),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Winner',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No bids were placed on this auction',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


