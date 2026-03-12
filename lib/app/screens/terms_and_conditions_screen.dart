import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms and Conditions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: ${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSection(
                context,
                '1. Acceptance of Terms',
                'By accessing and using Iraq Bid mobile application, you accept and agree to be bound by the terms and conditions of this agreement. If you do not agree to these terms, please do not use our services.',
                isDark,
              ),
              
              _buildSection(
                context,
                '2. User Account',
                'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. We reserve the right to suspend or terminate your account if we suspect any fraudulent activity.',
                isDark,
              ),
              
              _buildSection(
                context,
                '3. Bidding and Auctions',
                'All bids placed are final and cannot be withdrawn. By placing a bid, you agree to purchase the item if you are the winning bidder. The auctioneer reserves the right to cancel any auction or reject any bid at their discretion.',
                isDark,
              ),
              
              _buildSection(
                context,
                '4. Payment Terms',
                'Payment must be made within the specified time frame after winning an auction. We accept various payment methods as specified in the app. Failure to make payment may result in cancellation of your purchase and account suspension.',
                isDark,
              ),
              
              _buildSection(
                context,
                '5. Product Information',
                'We strive to provide accurate product descriptions and images. However, we do not warrant that product descriptions or other content are accurate, complete, reliable, current, or error-free.',
                isDark,
              ),
              
              _buildSection(
                context,
                '6. Referral Program',
                'Our referral program allows users to earn rewards by referring new users. Rewards are subject to terms and conditions and may be modified or discontinued at any time. Referral rewards are non-transferable and cannot be withdrawn as cash.',
                isDark,
              ),
              
              _buildSection(
                context,
                '7. Prohibited Activities',
                'You agree not to engage in any fraudulent, abusive, or illegal activity while using our services. This includes but is not limited to: creating fake accounts, manipulating bids, or attempting to circumvent our security measures.',
                isDark,
              ),
              
              _buildSection(
                context,
                '8. Privacy Policy',
                'Your use of our services is also governed by our Privacy Policy. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.',
                isDark,
              ),
              
              _buildSection(
                context,
                '9. Limitation of Liability',
                'To the maximum extent permitted by law, Iraq Bid shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
                isDark,
              ),
              
              _buildSection(
                context,
                '10. Changes to Terms',
                'We reserve the right to modify these terms and conditions at any time. We will notify users of any significant changes. Continued use of the service after changes constitutes acceptance of the new terms.',
                isDark,
              ),
              
              _buildSection(
                context,
                '11. Contact Information',
                'If you have any questions about these Terms and Conditions, please contact us through the app or via email at support@iraqbid.com.',
                isDark,
              ),
              
              const SizedBox(height: 32),
              
              // Accept Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('I Understand'),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

