import 'package:flutter/material.dart';

import '../../../core/mock/mock_skin_data.dart';
import '../../../core/widgets/premium_card.dart';

class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({super.key, required this.step});

  final RoutineStep step;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.productName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('${step.brand} · ${step.category}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Text(step.instruction, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text('Price: ${step.price}', style: Theme.of(context).textTheme.bodyMedium),
              if (step.warning != null) ...[
                const SizedBox(height: 12),
                Text('Warning: ${step.warning}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
