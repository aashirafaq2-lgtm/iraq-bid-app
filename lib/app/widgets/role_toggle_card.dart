import 'package:flutter/material.dart';
import '../theme/colors.dart';

class RoleToggleCard extends StatelessWidget {
  final String? userRole;
  final bool isTogglingRole;
  final ValueChanged<bool> onRoleChanged;

  const RoleToggleCard({
    super.key,
    required this.userRole,
    required this.isTogglingRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Role',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (userRole == 'seller_products') ? 'Seller Products' : (userRole == 'company_products' ? 'Company Products' : 'Not Set'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: userRole == 'seller_products' 
                                  ? AppColors.warning 
                                  : AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isTogglingRole)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: userRole == 'seller_products',
                    onChanged: onRoleChanged,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Switch between Company Products and Seller Products roles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

