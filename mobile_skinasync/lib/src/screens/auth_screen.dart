import 'package:flutter/material.dart';

import '../auth/auth_api_client.dart';
import '../auth/auth_models.dart';
import '../auth/auth_repository.dart';
import '../auth/supabase_oauth_service.dart';
import '../theme.dart';
import '../widgets/auth_text_field.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authRepository,
    required this.onAuthenticated,
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthUser> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _apiMessage;
  bool _isSuccessMessage = false;
  final Map<String, String> _errors = {};

  bool get _isRegistering => _mode == AuthMode.register;
  bool get _isBusy => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _apiMessage = null;
      _isSuccessMessage = false;
      _errors.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  bool _validate() {
    final nextErrors = <String, String>{};
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isRegistering) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        nextErrors['name'] = 'Vui lòng nhập họ và tên';
      } else if (name.length > 120) {
        nextErrors['name'] = 'Họ tên không quá 120 ký tự';
      }

      if (_phoneController.text.trim().length > 30) {
        nextErrors['phone'] = 'Số điện thoại không quá 30 ký tự';
      }
    }

    if (email.isEmpty) {
      nextErrors['email'] = 'Vui lòng nhập email';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      nextErrors['email'] = 'Email không hợp lệ';
    }

    if (password.isEmpty) {
      nextErrors['password'] = 'Vui lòng nhập mật khẩu';
    } else if (_isRegistering && password.length < 8) {
      nextErrors['password'] = 'Mật khẩu phải có ít nhất 8 ký tự';
    }

    if (_isRegistering) {
      final confirmPassword = _confirmPasswordController.text;
      if (confirmPassword.isEmpty) {
        nextErrors['confirmPassword'] = 'Vui lòng xác nhận mật khẩu';
      } else if (confirmPassword != password) {
        nextErrors['confirmPassword'] = 'Mật khẩu xác nhận không khớp';
      }
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });

    return nextErrors.isEmpty;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _apiMessage = null;
      _isSuccessMessage = false;
    });

    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isRegistering) {
        await _handleRegister();
      } else {
        await _handleLogin();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final response = await widget.authRepository.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    final login = response.content;
    if (response.success && login != null) {
      widget.onAuthenticated(login.user);
      return;
    }

    setState(() {
      _apiMessage = response.message.isNotEmpty
          ? response.message
          : 'Email hoặc mật khẩu không đúng.';
      _isSuccessMessage = false;
    });
  }

  Future<void> _handleRegister() async {
    final response = await widget.authRepository.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (response.success) {
      final loginResponse = await widget.authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      final login = loginResponse.content;
      if (loginResponse.success && login != null) {
        widget.onAuthenticated(login.user);
        return;
      }

      setState(() {
        _apiMessage = response.message.isNotEmpty
            ? '${response.message} Vui lòng đăng nhập để tiếp tục.'
            : 'Đăng ký thành công. Vui lòng đăng nhập.';
        _isSuccessMessage = true;
        _mode = AuthMode.login;
        _passwordController.clear();
        _confirmPasswordController.clear();
        _errors.clear();
      });
      return;
    }

    setState(() {
      _apiMessage = response.message.isNotEmpty
          ? response.message
          : 'Đăng ký thất bại. Vui lòng thử lại.';
      _isSuccessMessage = false;
    });
  }

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isGoogleLoading = true;
      _apiMessage = null;
      _isSuccessMessage = false;
      _errors.clear();
    });

    try {
      final response = await widget.authRepository.loginWithGoogle();
      if (!mounted) return;

      final login = response.content;
      if (response.success && login != null) {
        widget.onAuthenticated(login.user);
        return;
      }

      setState(() {
        _apiMessage = response.message.isNotEmpty
            ? response.message
            : 'Đăng nhập Google thất bại. Vui lòng thử lại.';
        _isSuccessMessage = false;
      });
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SkinSyncGradients.warmBackground,
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _HeroHeader(isCompact: constraints.maxWidth < 390),
                      Transform.translate(
                        offset: const Offset(0, -26),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                          child: _buildFormSurface(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormSurface(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: SkinSyncColors.cocoa.withValues(alpha: .11),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeSwitch(mode: _mode, onChanged: _switchMode),
          const SizedBox(height: 22),
          Text(
            _isRegistering ? 'Tạo tài khoản mới' : 'Chào mừng trở lại',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _isRegistering
                ? 'Bắt đầu hành trình chăm sóc da cá nhân hóa với AI.'
                : 'Đăng nhập để tiếp tục lộ trình dưỡng da của bạn.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_apiMessage != null) ...[
            const SizedBox(height: 16),
            _MessageBanner(message: _apiMessage!, isSuccess: _isSuccessMessage),
          ],
          const SizedBox(height: 20),
          if (_isRegistering) ...[
            AuthTextField(
              controller: _nameController,
              label: 'Họ và tên',
              hint: 'Nguyễn Thị Lan',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              errorText: _errors['name'],
              onChanged: (_) => _clearError('name'),
            ),
            const SizedBox(height: 16),
          ],
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'hello@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _errors['email'],
            onChanged: (_) => _clearError('email'),
          ),
          if (_isRegistering) ...[
            const SizedBox(height: 16),
            AuthTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hint: '0901 234 567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              errorText: _errors['phone'],
              onChanged: (_) => _clearError('phone'),
            ),
          ],
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: !_showPassword,
            textInputAction: _isRegistering
                ? TextInputAction.next
                : TextInputAction.done,
            errorText: _errors['password'],
            onChanged: (_) => _clearError('password'),
            suffix: IconButton(
              tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: SkinSyncColors.muted,
              ),
            ),
          ),
          if (!_isRegistering)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showSnack(
                  'Tính năng quên mật khẩu sẽ được nối sau luồng auth chính.',
                ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
          if (_isRegistering) ...[
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu',
              hint: '••••••••',
              icon: Icons.lock_reset_rounded,
              obscureText: !_showConfirmPassword,
              textInputAction: TextInputAction.done,
              errorText: _errors['confirmPassword'],
              onChanged: (_) => _clearError('confirmPassword'),
              suffix: IconButton(
                tooltip: _showConfirmPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SkinSyncColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _TermsNote(),
          ],
          const SizedBox(height: 22),
          _PrimaryAuthButton(
            isLoading: _isLoading,
            label: _isRegistering ? 'Tạo tài khoản' : 'Đăng nhập',
            onPressed: _isBusy ? null : _submit,
          ),
          const SizedBox(height: 18),
          const _DividerLabel(label: 'Hoặc'),
          const SizedBox(height: 14),
          _GoogleSignInButton(
            isLoading: _isGoogleLoading,
            onPressed: _isBusy ? null : _handleGoogleLogin,
          ),
          const SizedBox(height: 20),
          _buildApiHint(),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () => _switchMode(
                _isRegistering ? AuthMode.login : AuthMode.register,
              ),
              child: Text(
                _isRegistering
                    ? 'Đã có tài khoản? Đăng nhập'
                    : 'Chưa có tài khoản? Đăng ký ngay',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SkinSyncColors.cream.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Icon(
            SupabaseConfig.isConfigured
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            color: SkinSyncColors.cocoa,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              SupabaseConfig.isConfigured
                  ? 'API: ${ApiConfig.baseUrl} · OAuth: ${SupabaseConfig.redirectUrl}'
                  : 'API: ${ApiConfig.baseUrl} · Thiếu cấu hình Supabase OAuth',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SkinSyncColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearError(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() => _errors.remove(key));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 292 : 322,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1665454486608-5c2f3f5ede35'
            '?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(gradient: SkinSyncGradients.brand),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SkinSyncColors.cocoa.withValues(alpha: .72),
                  SkinSyncColors.sand.withValues(alpha: .42),
                  SkinSyncColors.espresso.withValues(alpha: .55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white24,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SkinSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        color: Color(0xFFD4F4F4),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Phân tích da bằng AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Làn da hoàn hảo\nbắt đầu từ đây',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: .24),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Lộ trình dưỡng da cá nhân hóa được tạo riêng cho bạn.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SkinSyncColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'Đăng nhập',
            selected: mode == AuthMode.login,
            onTap: () => onChanged(AuthMode.login),
          ),
          _ModeButton(
            label: 'Đăng ký',
            selected: mode == AuthMode.register,
            onTap: () => onChanged(AuthMode.register),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: SkinSyncColors.cocoa.withValues(alpha: .09),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? SkinSyncColors.cocoa : SkinSyncColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : SkinSyncGradients.brand,
          color: onPressed == null ? const Color(0xFFD6D3D1) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: SkinSyncColors.sand.withValues(alpha: .28),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: SkinSyncColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: SkinSyncColors.text,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: SkinSyncColors.sand,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tiếp tục với Google',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF047857) : const Color(0xFFDC2626);
    final background = isSuccess
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);
    final border = isSuccess
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsNote extends StatelessWidget {
  const _TermsNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: SkinSyncColors.sand,
          size: 18,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Khi tạo tài khoản, bạn đồng ý với điều khoản dịch vụ và chính sách bảo mật của SkinSync.',
            style: TextStyle(
              color: SkinSyncColors.muted,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
