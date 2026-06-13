import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/premium_card.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: AppRoutes.adminUsers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Users',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const AppTextField(
            label: 'Search users',
            hint: 'Email, name, or status',
          ),
          const SizedBox(height: 16),
          ...const [
            _UserRow(
              name: 'Linh Nguyen',
              email: 'linh@skinsync.app',
              status: 'Active',
            ),
            _UserRow(
              name: 'Mai Tran',
              email: 'mai@skinsync.app',
              status: 'Pending',
            ),
            _UserRow(
              name: 'Anh Le',
              email: 'anh@skinsync.app',
              status: 'Suspended',
            ),
          ],
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.name,
    required this.email,
    required this.status,
  });

  final String name;
  final String email;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(name),
          subtitle: Text(email),
          trailing: Chip(label: Text(status)),
        ),
      ),
    );
  }
}
