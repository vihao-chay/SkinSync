import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class SessionStore {
  static const _sessionKey = 'skinsync_session';
  static const _pendingOnboardingUsersKey = 'skinsync_pending_onboarding_users';
  static const _selectedAvatarKeyPrefix = 'skinsync_selected_avatar_';
  static const _installationIdKey = 'skinsync_installation_id';
  static const _appInstallRecordedKey = 'skinsync_app_install_recorded';

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

  Future<String?> readInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final installationId = prefs.getString(_installationIdKey)?.trim() ?? '';
    return installationId.isEmpty ? null : installationId;
  }

  Future<void> saveInstallationId(String installationId) async {
    final normalized = installationId.trim();
    if (normalized.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_installationIdKey, normalized);
  }

  Future<bool> isAppInstallRecorded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appInstallRecordedKey) ?? false;
  }

  Future<void> markAppInstallRecorded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appInstallRecordedKey, true);
  }

  Future<String?> selectedAvatarFor(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString(
      '$_selectedAvatarKeyPrefix$normalizedUserId',
    );
    final normalizedAvatar = avatar?.trim() ?? '';
    return normalizedAvatar.isEmpty ? null : normalizedAvatar;
  }

  Future<void> saveSelectedAvatarFor(String userId, String avatarUrl) async {
    final normalizedUserId = userId.trim();
    final normalizedAvatar = avatarUrl.trim();
    if (normalizedUserId.isEmpty || normalizedAvatar.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_selectedAvatarKeyPrefix$normalizedUserId',
      normalizedAvatar,
    );
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
