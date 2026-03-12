import 'package:flutter/material.dart';

class UserInfoCard extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  const UserInfoCard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName ?? 'User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (userEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                userEmail!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (userPhone != null) ...[
              const SizedBox(height: 4),
              Text(
                userPhone!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

