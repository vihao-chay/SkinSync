import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptedTerms = false;
  bool _isSubmittingAuth = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isAuthenticated && !_isSubmittingAuth && !_isRegisterMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            appState.shouldShowOnboarding
                ? AppRoutes.onboarding
                : AppRoutes.dashboard,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
                mobile: 520,
                tablet: 520,
                desktop: 520,
              ),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: Responsive.responsivePadding(
                  context,
                  top: 10,
                  bottom: 24,
                ),
              children: [
                const _BrandHeader(),
                const SizedBox(height: 16),
                _HeroCard(isRegisterMode: _isRegisterMode),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: _AuthCard(
                    isRegisterMode: _isRegisterMode,
                    isBusy: appState.isBusy,
                    errorMessage: appState.errorMessage,
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    showPassword: _showPassword,
                    showConfirmPassword: _showConfirmPassword,
                    acceptedTerms: _acceptedTerms,
                    onModeChanged: _switchMode,
                    onChanged: (_) => context.read<AppState>().clearError(),
                    onTogglePassword: () =>
                        setState(() => _showPassword = !_showPassword),
                    onToggleConfirmPassword: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                    onTermsChanged: (value) =>
                        setState(() => _acceptedTerms = value ?? false),
                    onSubmit: () => _submit(appState),
                    onGoogleSubmit: () => _submitGoogle(appState),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _switchMode(bool registerMode) {
    if (_isRegisterMode == registerMode) {
      return;
    }

    context.read<AppState>().clearError();
    setState(() {
      _isRegisterMode = registerMode;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _showPassword = false;
      _showConfirmPassword = false;
      _acceptedTerms = false;
    });
  }

  Future<void> _submit(AppState appState) async {
    if (!_validateInput()) {
      return;
    }

    setState(() => _isSubmittingAuth = true);
    try {
      if (_isRegisterMode) {
        await appState.register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
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

      Navigator.pushNamedAndRemoveUntil(
        context,
        appState.shouldShowOnboarding
            ? AppRoutes.onboarding
            : AppRoutes.dashboard,
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmittingAuth = false);
      }
    }
  }

  Future<void> _submitGoogle(AppState appState) async {
    setState(() => _isSubmittingAuth = true);
    try {
      await appState.loginWithGoogle();
      if (_isRegisterMode) {
        await appState.markOnboardingPendingForCurrentUser();
      }
      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        appState.shouldShowOnboarding
            ? AppRoutes.onboarding
            : AppRoutes.dashboard,
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmittingAuth = false);
      }
    }
  }

  bool _validateInput() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isRegisterMode && _nameController.text.trim().isEmpty) {
      _showMessage('Please enter your full name.');
      return false;
    }

    if (email.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email.');
      return false;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password.');
      return false;
    }

    if (_isRegisterMode && password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return false;
    }

    if (_isRegisterMode && password != _confirmPasswordController.text) {
      _showMessage('Confirm password does not match.');
      return false;
    }

    if (_isRegisterMode && !_acceptedTerms) {
      _showMessage('Please agree to the terms of service.');
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    context.read<AppState>().clearError();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const BrandLogo(size: 26, radius: 13, showShadow: false),
        Text(
          'SkinSync',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.primaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
            decorationThickness: 0.6,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isRegisterMode});

  final bool isRegisterMode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'login_register.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x99000000),
                    Color(0x3A000000),
                    Color(0x08000000),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(
                    label: isRegisterMode
                        ? 'AI Skin Analyze'
                        : 'Future · Science · AI Fusion',
                  ),
                  const Spacer(),
                  Text(
                    'Perfect skin\nstarts here',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 0.98,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Your personalized skincare journey\ncalibrated just for you.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isRegisterMode,
    required this.isBusy,
    required this.errorMessage,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.acceptedTerms,
    required this.onModeChanged,
    required this.onChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onTermsChanged,
    required this.onSubmit,
    required this.onGoogleSubmit,
  });

  final bool isRegisterMode;
  final bool isBusy;
  final String? errorMessage;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showPassword;
  final bool showConfirmPassword;
  final bool acceptedTerms;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeTabs(
            isRegisterMode: isRegisterMode,
            onModeChanged: onModeChanged,
          ),
          const SizedBox(height: 19),
          Text(
            isRegisterMode ? 'Create new account' : 'Welcome Back',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.foreground,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRegisterMode
                ? 'Start your personalized skincare journey with AI.'
                : 'Log in to continue your personalized skincare journey.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.foreground,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 19),
          if (errorMessage != null) ...[
            _ErrorBanner(message: errorMessage!),
            const SizedBox(height: 12),
          ],
          if (isRegisterMode) ...[
            _AuthTextField(
              label: 'Full Name',
              hint: 'John Doe',
              icon: Icons.person_outline_rounded,
              controller: nameController,
              onChanged: onChanged,
            ),
            const SizedBox(height: 12),
          ],
          _AuthTextField(
            label: 'Email',
            hint: 'hello@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          if (isRegisterMode) ...[
            _AuthTextField(
              label: 'Phone Number',
              hint: '+ 0901234567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              controller: phoneController,
              onChanged: onChanged,
            ),
            const SizedBox(height: 12),
          ],
          _AuthTextField(
            label: 'Password',
            hint: '••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: !showPassword,
            controller: passwordController,
            onChanged: onChanged,
            trailing: _EyeButton(
              showing: showPassword,
              onPressed: onTogglePassword,
            ),
          ),
          if (!isRegisterMode) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Forgot Password?',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (isRegisterMode) ...[
            const SizedBox(height: 12),
            _AuthTextField(
              label: 'Confirm Password',
              hint: '••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: !showConfirmPassword,
              controller: confirmPasswordController,
              onChanged: onChanged,
              trailing: _EyeButton(
                showing: showConfirmPassword,
                onPressed: onToggleConfirmPassword,
              ),
            ),
            const SizedBox(height: 12),
            _TermsRow(value: acceptedTerms, onChanged: onTermsChanged),
          ],
          const SizedBox(height: 14),
          _PrimaryButton(
            label: isRegisterMode ? 'Create Account' : 'Login',
            isLoading: isBusy,
            onPressed: isBusy ? null : onSubmit,
          ),
          const SizedBox(height: 15),
          const _DividerLabel(),
          const SizedBox(height: 15),
          _GoogleButton(
            isLoading: isBusy,
            onPressed: isBusy ? null : onGoogleSubmit,
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: isBusy ? null : () => onModeChanged(!isRegisterMode),
              child: Text.rich(
                TextSpan(
                  text: isRegisterMode
                      ? 'Already have an account? '
                      : "Don't have an account? ",
                  children: [
                    TextSpan(
                      text: isRegisterMode ? 'Login' : 'Sign up now',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                      ),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.foreground,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.isRegisterMode, required this.onModeChanged});

  final bool isRegisterMode;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Login',
              selected: !isRegisterMode,
              onTap: () => onModeChanged(false),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Register',
              selected: isRegisterMode,
              onTap: () => onModeChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.foreground,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.foreground,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 45,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.subtleText,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(icon, size: 16, color: AppColors.mutedText),
              suffixIcon: trailing,
              filled: true,
              fillColor: const Color(0xFFFEFCF9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.86),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.86),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: AppColors.primaryDark,
                  width: 1.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.showing, required this.onPressed});

  final bool showing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: showing ? 'Hide password' : 'Show password',
      icon: Icon(
        showing ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.primaryDark,
        size: 17,
      ),
      onPressed: onPressed,
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: value,
            activeColor: AppColors.primaryDark,
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.foreground,
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF9D7550),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.border.withValues(alpha: 0.65)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            'Or',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.foreground,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.border.withValues(alpha: 0.65)),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFCF8),
          foregroundColor: AppColors.foreground,
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.88)),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryDark,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GoogleMark(size: 15),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.17;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, math.pi * 1.08, math.pi * 0.48, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.70, math.pi * 0.42, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.30, math.pi * 0.46, false, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, math.pi * 1.65, math.pi * 0.62, false, paint);
    paint.strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.50),
      Offset(size.width * 0.92, size.height * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.error),
      ),
    );
  }
}
