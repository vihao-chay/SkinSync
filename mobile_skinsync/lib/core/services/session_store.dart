import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class SessionStore {
  static const _sessionKey = 'skinsync_session';
  static const _pendingOnboardingUsersKey = 'skinsync_pending_onboarding_users';

  Future<AuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<bool> isOnboardingPendingFor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingUsers =
        prefs.getStringList(_pendingOnboardingUsersKey) ?? const <String>[];
    return pendingUsers.contains(userId);
  }

  Future<void> markOnboardingPendingFor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingUsers =
        prefs.getStringList(_pendingOnboardingUsersKey) ?? const <String>[];
    if (pendingUsers.contains(userId)) {
      return;
    }

    await prefs.setStringList(_pendingOnboardingUsersKey, [
      ...pendingUsers,
      userId,
    ]);
  }

  Future<void> clearOnboardingPendingFor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingUsers =
        prefs.getStringList(_pendingOnboardingUsersKey) ?? const <String>[];
    await prefs.setStringList(
      _pendingOnboardingUsersKey,
      pendingUsers.where((id) => id != userId).toList(),
    );
  }
}
