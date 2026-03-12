import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PlaceBidModal extends StatefulWidget {
  final int currentBid;
  final String productTitle;
  final int productId;

  const PlaceBidModal({
    super.key,
    required this.currentBid,
    required this.productTitle,
    required this.productId,
  });

  @override
  State<PlaceBidModal> createState() => _PlaceBidModalState();
}

class _PlaceBidModalState extends State<PlaceBidModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _bidController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  int get _minBid => widget.currentBid + 1;

  List<int> get _suggestedBids => [
        widget.currentBid + 1,
        widget.currentBid + 5,
        widget.currentBid + 10,
        widget.currentBid + 25,
      ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_bidController.text);
    if (amount == null || amount < _minBid) {
      HapticFeedback.vibrate();
      return;
    }

    // Trigger feedback on submission
    HapticFeedback.mediumImpact();

    // Check if user is logged in before placing bid
    final isLoggedIn = await StorageService.isLoggedIn();
    final accessToken = await StorageService.getAccessToken();
    
    if (!isLoggedIn || accessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/auth');
          }
        });
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await apiService.placeBid(
        productId: widget.productId,
        amount: amount,
      );

      // Trigger success feedback
      HapticFeedback.heavyImpact();

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        // Extract user-friendly error message
        String errorMessage = 'Failed to place bid. Please try again.';
        
        final errorString = e.toString().toLowerCase();
        
        // ... (rest of error handling remains same)
        // [TRUNCATED FOR CONTEXT]
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  bool get _isValidBid {
    final amount = double.tryParse(_bidController.text);
    return amount != null && amount >= _minBid;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: screenHeight * 0.9,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: _isSuccess
                ? _buildSuccessView()
                : _buildFormView(isDark),
          ),
        );
      },
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_afwjh8re.json', // Celebration Lottie
            width: 200,
            height: 200,
            repeat: false,
          ),
          const SizedBox(height: 24),
          Text(
            'Bid Placed!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 8),
          Text(
            'Your bid of \$${_formatCurrency(int.parse(_bidController.text))} has been successfully placed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Place Your Bid',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.slate800 : AppColors.slate100,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title
                Text(
                  'Auction Item',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.productTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 24),

                // Current Bid Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Bid',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.blue600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_formatCurrency(widget.currentBid)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Minimum Bid',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.blue600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_formatCurrency(_minBid)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bid Amount Input
                Text(
                  'Your Bid Amount',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bidController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    hintText: _minBid.toString(),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                if (_bidController.text.isNotEmpty &&
                    (int.tryParse(_bidController.text) ?? 0) < _minBid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Bid must be at least \$${_formatCurrency(_minBid)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Quick Bid Options
                Text(
                  'Quick Bid Options',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _suggestedBids.length,
                  itemBuilder: (context, index) {
                    final amount = _suggestedBids[index];
                    final isSelected =
                        _bidController.text == amount.toString();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _bidController.text = amount.toString();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.blue50
                              : (isDark
                                  ? AppColors.slate800
                                  : AppColors.surfaceLight),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.blue600
                                : (isDark
                                    ? AppColors.slate700
                                    : AppColors.slate200),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: isSelected
                                  ? AppColors.blue600
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${_formatCurrency(amount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.blue600
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isValidBid && !_isSubmitting
                        ? _handleSubmit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: AppColors.cardWhite,
                      disabledBackgroundColor: AppColors.blue600.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.cardWhite),
                            ),
                          )
                        : const Text(
                            'Confirm Bid',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Terms
                Text(
                  'By placing a bid, you agree to our terms and conditions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

