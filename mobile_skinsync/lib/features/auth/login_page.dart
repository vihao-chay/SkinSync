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
  final _confirmPasswordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isAuthenticated) {
      final nextRoute = appState.profile?.isOnboardingCompleted == true ? AppRoutes.dashboard : AppRoutes.onboarding;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, nextRoute);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: AppRoutes.login,
        title: 'SkinSync',
        showBack: false,
      ),
      body: ResponsiveContainer(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              24,
            ),
            children: [
              const SizedBox(height: 12),
              Text(
                _isRegisterMode ? 'Create account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegisterMode
                    ? 'Tạo tài khoản để bắt đầu quiz, upload ảnh và nhận routine cá nhân hoá.'
                    : 'Đăng nhập để tiếp tục hành trình chăm sóc da của bạn.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Email',
                      hint: 'skincare@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      onChanged: (_) => context.read<AppState>().clearError(),
                    ),
                    const SizedBox(height: AppSpacing.mediumGap),
                    AppTextField(
                      label: 'Password',
                      hint: '********',
                      obscureText: true,
                      controller: _passwordController,
                      onChanged: (_) => context.read<AppState>().clearError(),
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: AppSpacing.mediumGap),
                      AppTextField(
                        label: 'Confirm password',
                        hint: 'Nhập lại mật khẩu',
                        obscureText: true,
                        controller: _confirmPasswordController,
                        onChanged: (_) => context.read<AppState>().clearError(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.largeGap),
                    if (appState.errorMessage != null) ...[
                      _ErrorBanner(message: appState.errorMessage!),
                      const SizedBox(height: 12),
                    ],
                    GradientPillButton(
                      label: _isRegisterMode ? 'Create account' : 'Sign in',
                      isLoading: appState.isBusy,
                      expanded: true,
                      onPressed: () => _submit(appState),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: appState.isBusy ? null : () => _submitGoogle(appState),
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: const Text('Continue with Google'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.mediumGap),
              TextButton(
                onPressed: appState.isBusy ? null : () => setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(_isRegisterMode ? 'Already have an account? Sign in' : 'Create a new account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppState appState) async {
    try {
      if (_isRegisterMode) {
        if (_passwordController.text != _confirmPasswordController.text) {
          appState.clearError();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password confirmation does not match.')),
          );
          return;
        }
        await appState.register(
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

      await appState.refreshProfileState();
      final nextRoute = appState.profile?.isOnboardingCompleted == true ? AppRoutes.dashboard : AppRoutes.onboarding;
      Navigator.pushReplacementNamed(context, nextRoute);
    } catch (_) {}
  }

  Future<void> _submitGoogle(AppState appState) async {
    try {
      await appState.loginWithGoogle();
      if (!mounted) {
        return;
      }

      await appState.refreshProfileState();
      final nextRoute = appState.profile?.isOnboardingCompleted == true ? AppRoutes.dashboard : AppRoutes.onboarding;
      Navigator.pushReplacementNamed(context, nextRoute);
    } catch (_) {}
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
      ),
    );
  }
}
