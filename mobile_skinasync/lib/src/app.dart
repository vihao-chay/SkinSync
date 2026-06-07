import 'package:flutter/material.dart';

import 'auth/auth_models.dart';
import 'auth/auth_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';
import 'widgets/brand_logo.dart';

class SkinSyncApp extends StatelessWidget {
  const SkinSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinSync',
      debugShowCheckedModeBanner: false,
      theme: buildSkinSyncTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthRepository _authRepository = AuthRepository();
  AuthUser? _user;
  bool _isBooting = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await _authRepository.restoreUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isBooting = false;
    });
  }

  void _handleAuthenticated(AuthUser user) {
    setState(() => _user = user);
  }

  Future<void> _handleLogout() async {
    await _authRepository.logout();
    if (!mounted) return;
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isBooting) {
      return const SplashScreen();
    }

    final user = _user;
    if (user == null) {
      return AuthScreen(
        authRepository: _authRepository,
        onAuthenticated: _handleAuthenticated,
      );
    }

    return HomeScreen(user: user, onLogout: _handleLogout);
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SkinSyncGradients.warmBackground,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(
                size: 78,
                borderRadius: 22,
                borderColor: SkinSyncColors.border.withValues(alpha: .7),
                boxShadow: [
                  BoxShadow(
                    color: SkinSyncColors.cocoa.withValues(alpha: .16),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('SkinSync', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: SkinSyncColors.sand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
