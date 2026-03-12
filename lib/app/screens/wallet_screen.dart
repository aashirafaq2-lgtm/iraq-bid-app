import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/network_utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole; // Track user role to hide seller earnings from customers

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    // Load wallet data immediately - ensures wallet opens properly
    _loadWalletData();
  }

  Future<void> _loadUserRole() async {
    final role = await StorageService.getUserRole();
    setState(() {
      _userRole = role;
    });
  }

  // Check if current user is a seller
  bool get _isSeller {
    return _userRole?.toLowerCase() == 'seller_products';
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check if user is logged in
    final isLoggedIn = await StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();
    
    if (!isLoggedIn || accessToken == null) {
      setState(() {
        _errorMessage = 'Please login first';
        _isLoading = false;
      });
      // Redirect to login after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.go('/auth');
        }
      });
      return;
    }

    try {
      final response = await apiService.getWallet();
      
      // Handle different response formats
      if (response['success'] == true) {
        // Check if data exists
        if (response['data'] != null) {
          setState(() {
            _walletData = response['data'] as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          // If success but no data, initialize with empty structure
          setState(() {
            _walletData = {
              'total_balance': 0.0,
              'breakdown': {
                'referral_rewards': 0.0,
                'seller_earnings': 0.0,
                'pending_earnings': 0.0,
              },
              'transactions': <Map<String, dynamic>>[],
            };
            _isLoading = false;
          });
        }
      } else {
        // Handle error response
        final errorMsg = response['message'] ?? response['error'] ?? 'Failed to load wallet data';
        setState(() {
          _errorMessage = errorMsg.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Wallet] Error loading wallet data: $e');
      }
      
      // Check for network errors
      String errorMsg = 'Failed to load wallet data';
      if (NetworkUtils.isNetworkError(e)) {
        errorMsg = NetworkUtils.getNetworkErrorMessage(e);
      } else if (e is DioException) {
        if (e.response != null) {
          final data = e.response?.data;
          if (data is Map && data.containsKey('message')) {
            errorMsg = data['message'] as String;
          } else if (e.response?.statusCode == 401) {
            errorMsg = 'Please login first';
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go('/auth');
              }
            });
          } else {
            errorMsg = 'Server error: ${e.response?.statusCode}';
          }
        } else {
          errorMsg = e.message ?? 'Network error occurred';
        }
      } else {
        errorMsg = e.toString();
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  double _safeGetDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
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

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'referral':
        return AppColors.green600;
      case 'sale':
        return AppColors.blue600;
      default:
        return AppColors.slate600;
    }
  }

  IconData _getTransactionTypeIcon(String type) {
    switch (type) {
      case 'referral':
        return Icons.people;
      case 'sale':
        return Icons.shopping_bag;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Wallet'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 24),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadWalletData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_errorMessage!.contains('login') || _errorMessage!.contains('Login'))
                          const SizedBox(height: 16),
                        if (_errorMessage!.contains('login') || _errorMessage!.contains('Login'))
                          TextButton(
                            onPressed: () {
                              context.go('/auth');
                            },
                            child: const Text('Go to Login'),
                          ),
                      ],
                    ),
                  ),
                )
              : _walletData == null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet, size: 64, color: AppColors.slate400),
                            SizedBox(height: 16),
                            Text('No wallet data available'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadWalletData(),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWalletData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Total Balance Card - Updated with Glassmorphism
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Stack(
                                children: [
                                  // Background Gradient
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.blue600.withOpacity(0.8),
                                          AppColors.blue700.withOpacity(0.9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                  // Glass Effect
                                  BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Total Balance',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.white.withOpacity(0.9),
                                                  letterSpacing: 1.2,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '\$${_formatCurrency((_walletData?['total_balance'] ?? 0.0) is num ? (_walletData!['total_balance'] as num).toDouble() : 0.0)}',
                                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 42,
                                                ),
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _BalanceItem(
                                                label: 'Referral',
                                                amount: _safeGetDouble(_walletData?['breakdown']?['referral_rewards']),
                                                color: Colors.greenAccent,
                                              ),
                                              if (_isSeller) ...[
                                                _BalanceItem(
                                                  label: 'Earnings',
                                                  amount: _safeGetDouble(_walletData?['breakdown']?['seller_earnings']),
                                                  color: Colors.amberAccent,
                                                ),
                                                if (_safeGetDouble(_walletData?['breakdown']?['pending_earnings']) > 0)
                                                  _BalanceItem(
                                                    label: 'Pending',
                                                    amount: _safeGetDouble(_walletData?['breakdown']?['pending_earnings']),
                                                    color: AppColors.yellow600,
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Transaction History
                            Text(
                              'Transaction History',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            if ((_walletData?['transactions'] as List?)?.isEmpty ?? true)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.history, size: 64, color: AppColors.slate400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No transactions yet',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...((_walletData?['transactions'] as List?) ?? []).map((transaction) {
                                final type = transaction['transaction_type'] ?? 'unknown';
                                final amount = (transaction['amount'] ?? 0.0).toDouble();
                                final date = transaction['transaction_date'] ?? '';
                                final status = transaction['status'] ?? 'completed';
                                final description = transaction['title'] ?? transaction['description'] ?? 'Transaction';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getTransactionTypeColor(type).withOpacity(0.2),
                                      child: Icon(
                                        _getTransactionTypeIcon(type),
                                        color: _getTransactionTypeColor(type),
                                      ),
                                    ),
                                    title: Text(
                                      description,
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
                                            color: _getTransactionTypeColor(type),
                                          ),
                                        ),
                                        if (status != 'awarded' && status != 'completed')
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
    } catch (e) {
      // Fallback UI if build fails - prevents white screen
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wallet'),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Error loading wallet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                      _walletData = null;
                    });
                    _loadWalletData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BalanceItem({
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
          style: TextStyle(
            fontSize: 16,
            color: AppColors.cardWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


