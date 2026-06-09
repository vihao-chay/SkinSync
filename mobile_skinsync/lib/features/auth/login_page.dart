import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassHeader(
        currentRoute: AppRoutes.login,
        title: 'Welcome Back',
      ),
      backgroundColor: AppColors.pageBackground,
      body: ResponsiveContainer(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in to continue your skincare journey.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.mediumGap),
                      const AppTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        obscureText: true,
                      ),
                      const SizedBox(height: AppSpacing.largeGap),
                      GradientPillButton(
                        label: 'Sign In',
                        expanded: true,
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.dashboard,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.mediumGap),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.quiz),
                    child: const Text('Continue as Demo User'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
