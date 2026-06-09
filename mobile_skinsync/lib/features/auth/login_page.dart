import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      });
    }

    return Scaffold(
      appBar: const GlassHeader(
        currentRoute: AppRoutes.login,
        title: 'SkinSync Account',
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
                  _isRegisterMode
                      ? 'Create your skincare account and continue into the quiz.'
                      : 'Sign in to continue your skincare journey.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isRegisterMode) ...[
                        AppTextField(
                          label: 'Full name',
                          hint: 'Nguyen Van A',
                          controller: _fullNameController,
                        ),
                        const SizedBox(height: AppSpacing.mediumGap),
                      ],
                      AppTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),
                      const SizedBox(height: AppSpacing.mediumGap),
                      AppTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: AppSpacing.largeGap),
                      if (appState.errorMessage != null) ...[
                        Text(
                          appState.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      GradientPillButton(
                        label: _isRegisterMode ? 'Create Account' : 'Sign In',
                        isLoading: appState.isBusy,
                        expanded: true,
                        onPressed: () => _submit(appState),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.mediumGap),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                    child: Text(_isRegisterMode ? 'Already have an account?' : 'Create a new account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppState appState) async {
    try {
      if (_isRegisterMode) {
        await appState.register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await appState.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) {
        return;
      }

      final nextRoute = appState.profile == null ? AppRoutes.quiz : AppRoutes.dashboard;
      Navigator.pushReplacementNamed(context, nextRoute);
    } catch (_) {
    }
  }
}
