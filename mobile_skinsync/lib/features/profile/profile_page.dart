import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/user_shell.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserShell(
      currentRoute: AppRoutes.profile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumCard(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFF5E6D3),
                  child: Icon(Icons.person_outline_rounded, size: 40),
                ),
                const SizedBox(height: 14),
                Text(MockSkinData.user.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(MockSkinData.user.email, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skin Profile Summary', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Skin type: ${MockSkinData.user.skinType}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('Concerns: ${MockSkinData.user.concerns.join(', ')}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('Goal: ${MockSkinData.user.goal}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...const [
            _MenuItem(title: 'Edit Profile', subtitle: 'Update skin profile and personal details', icon: Icons.edit_outlined),
            _MenuItem(title: 'My Analysis History', subtitle: 'Review previous AI scans and reports', icon: Icons.history_outlined),
            _MenuItem(title: 'Reminders', subtitle: 'Manage your morning and evening alerts', icon: Icons.notifications_outlined),
            _MenuItem(title: 'Settings', subtitle: 'Language, preferences, and app behavior', icon: Icons.settings_outlined),
            _MenuItem(title: 'Help Center', subtitle: 'Guides, FAQs, and support', icon: Icons.help_outline_rounded),
            _MenuItem(title: 'Logout', subtitle: 'End the current session', icon: Icons.logout_rounded),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Icon(icon, size: 20)),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
