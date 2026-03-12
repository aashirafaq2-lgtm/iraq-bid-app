import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../utils/image_url_helper.dart';

class SellerEarningsScreen extends StatefulWidget {
  const SellerEarningsScreen({super.key});

  @override
  State<SellerEarningsScreen> createState() => _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends State<SellerEarningsScreen> {
  Map<String, dynamic>? _earningsData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await apiService.getSellerEarnings();
      if (response['success'] == true) {
        setState(() {
          _earningsData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load earnings data';
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
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
        title: const Text('Earnings'),
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
                        onPressed: _loadEarningsData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _earningsData == null
                  ? const Center(child: Text('No earnings data'))
                  : RefreshIndicator(
                      onRefresh: _loadEarningsData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Total Earnings Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primaryBlue, AppColors.darkBlue],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Total Earnings',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.cardWhite,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${_formatCurrency(_earningsData!['total_earnings'] ?? 0.0)}',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          color: AppColors.cardWhite,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _EarningsStat(
                                        label: 'Available',
                                        amount: _earningsData!['available_balance'] ?? 0.0,
                                        color: AppColors.green500,
                                      ),
                                      _EarningsStat(
                                        label: 'Pending',
                                        amount: _earningsData!['pending_earnings'] ?? 0.0,
                                        color: AppColors.yellow500,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Statistics Cards
                            if (_earningsData!['statistics'] != null)
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Total Sales',
                                      value: '${_earningsData!['statistics']?['total_sales'] ?? 0}',
                                      icon: Icons.shopping_bag,
                                      color: AppColors.blue600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      label: 'Avg per Sale',
                                      value: '\$${_formatCurrency((_earningsData!['statistics']?['average_per_sale'] ?? 0.0).toDouble())}',
                                      icon: Icons.trending_up,
                                      color: AppColors.yellow600,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 24),

                            // Earnings Breakdown
                            Text(
                              'Earnings Breakdown',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            if ((_earningsData!['breakdown'] as List?)?.isEmpty ?? true)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 64, color: AppColors.slate400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No earnings yet',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...((_earningsData!['breakdown'] as List?) ?? []).map((item) {
                                final title = item['title'] ?? 'Product';
                                final amount = (item['amount'] ?? 0.0).toDouble();
                                final status = item['status'] ?? 'sold';
                                final date = item['sold_date'] ?? '';
                                final imageUrl = item['image_url'] ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              ImageUrlHelper.fixImageUrl(imageUrl),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: AppColors.slate200,
                                                  child: const Icon(Icons.image),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppColors.slate200,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.image),
                                          ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(_formatDate(date)),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${_formatCurrency(amount)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.green600,
                                          ),
                                        ),
                                        if (status != 'sold')
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.yellow100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.yellow700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _EarningsStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.cardWhite.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.cardWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}


