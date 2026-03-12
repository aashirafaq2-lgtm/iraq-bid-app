import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/colors.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class InviteAndEarnScreen extends StatefulWidget {
  const InviteAndEarnScreen({super.key});

  @override
  State<InviteAndEarnScreen> createState() => _InviteAndEarnScreenState();
}

class _InviteAndEarnScreenState extends State<InviteAndEarnScreen> {
  String? _referralCode;
  double _rewardBalance = 0.0;
  List<Map<String, dynamic>> _referralHistory = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load referral code and balance
      final response = await apiService.getReferralCode();
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _referralCode = data['referral_code'];
          _rewardBalance = (data['reward_balance'] is num)
              ? (data['reward_balance'] as num).toDouble()
              : double.tryParse(data['reward_balance'].toString()) ?? 0.0;
        });
        
        // Save to storage
        if (_referralCode != null) {
          await StorageService.saveReferralCode(_referralCode!);
        }
        await StorageService.saveRewardBalance(_rewardBalance);
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load referral data';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading referral code: $e');
      }
      setState(() {
        _error = 'Failed to load referral information';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // Load referral history
    await _loadReferralHistory();
  }

  Future<void> _loadReferralHistory({bool loadMore = false}) async {
    if (_isLoadingHistory && !loadMore) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final response = await apiService.getReferralHistory(page: page, limit: 20);

      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>? ?? [];
        final pagination = response['pagination'];

        setState(() {
          if (loadMore) {
            _referralHistory.addAll(data.map((e) => e as Map<String, dynamic>));
            _currentPage = page;
          } else {
            _referralHistory = data.map((e) => e as Map<String, dynamic>).toList();
            _currentPage = 1;
          }
          _hasMore = pagination != null && page < (pagination['pages'] ?? 1);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading referral history: $e');
      }
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _copyReferralCode() async {
    if (_referralCode == null) return;

    await Clipboard.setData(ClipboardData(text: _referralCode!));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareReferralLink() async {
    if (_referralCode == null) return;

    // Generate referral link
    const baseUrl = 'https://yourapp.com/signup'; // Update with your actual app URL
    final referralLink = '$baseUrl?ref=$_referralCode';

    final shareText = '''
🎉 Invite your friends to BidMaster and earn rewards!

Use my referral code: $_referralCode

Sign up here: $referralLink

Start earning today! 💰
''';

    try {
      await Share.share(shareText, subject: 'Join BidMaster with my referral code!');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sharing: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share referral link'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'awarded':
        return 'Awarded';
      case 'pending':
        return 'Pending';
      case 'revoked':
        return 'Revoked';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'awarded':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'revoked':
        return AppColors.error;
      default:
        return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite & Earn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop, otherwise navigate to home
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
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReferralData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReferralData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Referral Code Card
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  'Your Referral Code',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    _referralCode ?? 'Loading...',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _copyReferralCode,
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Copy'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _shareReferralLink,
                                        icon: const Icon(Icons.share),
                                        label: const Text('Share'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Reward Balance Card
                        Card(
                          elevation: 2,
                          color: AppColors.blue50,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      size: 32,
                                      color: AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Reward Balance',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '\$${_rewardBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Earn \$1 when someone signs up with your code!\nThey get \$2 as a welcome bonus.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Referral History
                        Text(
                          'Referral History',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),

                        _isLoadingHistory && _referralHistory.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _referralHistory.isEmpty
                                ? Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.people_outline,
                                            size: 64,
                                            color: AppColors.slate400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No referrals yet',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Share your referral code to start earning!',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : RepaintBoundary(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _referralHistory.length + (_hasMore ? 1 : 0) + (_isLoadingHistory ? 1 : 0),
                                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        if (index == _referralHistory.length) {
                                          if (_isLoadingHistory) {
                                            return const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Center(child: CircularProgressIndicator()),
                                            );
                                          }
                                          if (_hasMore) {
                                            return Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: ElevatedButton(
                                                onPressed: () => _loadReferralHistory(loadMore: true),
                                                child: const Text('Load More'),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        }
                                        
                                        final referral = _referralHistory[index];
                                        return RepaintBoundary(
                                          child: Card(
                                            margin: EdgeInsets.zero,
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: _getStatusColor(
                                                  referral['status'] ?? 'pending',
                                                ).withOpacity(0.2),
                                                child: Icon(
                                                  Icons.person,
                                                  color: _getStatusColor(
                                                    referral['status'] ?? 'pending',
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                referral['invitee_phone'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle: Text(
                                                _formatDate(
                                                  referral['created_at'] ?? '',
                                                ),
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '\$${(referral['amount'] ?? 0.0).toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primaryBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                        referral['status'] ?? 'pending',
                                                      ).withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      _getStatusText(
                                                        referral['status'] ?? 'pending',
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: _getStatusColor(
                                                          referral['status'] ?? 'pending',
                                                        ),
                                                        fontWeight: FontWeight.w600,
                                                      ),
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
                      ],
                    ),
                  ),
                ),
    );
  }
}



