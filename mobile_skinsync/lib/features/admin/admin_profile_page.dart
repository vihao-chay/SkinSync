import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/premium_card.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: AppRoutes.adminProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Admin User'),
                  subtitle: Text('ops@skinsync.app'),
                  leading: CircleAvatar(
                    child: Icon(Icons.admin_panel_settings_outlined),
                  ),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Security settings'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Notification preferences'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
