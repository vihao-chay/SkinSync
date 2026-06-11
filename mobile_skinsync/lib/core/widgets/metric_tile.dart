import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'premium_card.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary,
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Text(
              trend!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
