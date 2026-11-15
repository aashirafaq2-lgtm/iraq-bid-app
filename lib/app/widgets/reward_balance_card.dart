import 'package:flutter/material.dart';
import '../theme/colors.dart';

class RewardBalanceCard extends StatelessWidget {
  final double rewardBalance;

  const RewardBalanceCard({
    super.key,
    required this.rewardBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.blue50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward Balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${rewardBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}

