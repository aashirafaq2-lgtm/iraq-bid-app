import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                'Privacy Policy',
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
                '1. Information We Collect',
                'We collect information that you provide directly to us, including:\n\n• Phone number (for account verification)\n• Name and email address\n• Bidding history and preferences\n• Payment information (processed securely)\n• Device information and usage data\n• Referral codes and reward balances',
                isDark,
              ),
              
              _buildSection(
                context,
                '2. How We Use Your Information',
                'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process transactions and send related information\n• Send you technical notices and support messages\n• Respond to your comments and questions\n• Monitor and analyze trends and usage\n• Detect, prevent, and address technical issues\n• Personalize your experience',
                isDark,
              ),
              
              _buildSection(
                context,
                '3. Information Sharing',
                'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n• With your consent\n• To comply with legal obligations\n• To protect our rights and safety\n• With service providers who assist us in operating our app (under strict confidentiality agreements)',
                isDark,
              ),
              
              _buildSection(
                context,
                '4. Data Security',
                'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
                isDark,
              ),
              
              _buildSection(
                context,
                '5. Your Rights',
                'You have the right to:\n\n• Access your personal information\n• Correct inaccurate data\n• Request deletion of your account\n• Object to processing of your data\n• Data portability\n• Withdraw consent at any time',
                isDark,
              ),
              
              _buildSection(
                context,
                '6. Cookies and Tracking',
                'We use cookies and similar tracking technologies to track activity on our app and store certain information. You can instruct your device to refuse all cookies, but this may limit your ability to use some features of our service.',
                isDark,
              ),
              
              _buildSection(
                context,
                '7. Third-Party Services',
                'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.',
                isDark,
              ),
              
              _buildSection(
                context,
                '8. Children\'s Privacy',
                'Our services are not intended for children under the age of 18. We do not knowingly collect personal information from children. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
                isDark,
              ),
              
              _buildSection(
                context,
                '9. Data Retention',
                'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.',
                isDark,
              ),
              
              _buildSection(
                context,
                '10. Changes to This Policy',
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
                isDark,
              ),
              
              _buildSection(
                context,
                '11. Contact Us',
                'If you have any questions about this Privacy Policy, please contact us:\n\nEmail: privacy@iraqbid.com\nPhone: Support through app',
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

