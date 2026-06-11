import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/premium_card.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: AppRoutes.adminProducts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Products', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  children: const [
                    Chip(label: Text('Cleanser')),
                    Chip(label: Text('Serum')),
                    Chip(label: Text('Moisturizer')),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...const [
            _ProductRow(name: 'Barrier Comfort Cream', category: 'Moisturizer'),
            _ProductRow(name: 'Balance Niacinamide Serum', category: 'Serum'),
            _ProductRow(name: 'Daily Veil SPF 50', category: 'Sunscreen'),
          ],
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.name, required this.category});

  final String name;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(name),
          subtitle: Text(category),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
