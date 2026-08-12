import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

/// Manages the current locale and provides translated strings.
///
/// Usage:
///   final locale = AppLocale.of(context);
///   locale.tr('nav_home')  // → "Trang chủ" or "Home"
class AppLocale extends ChangeNotifier {
  AppLocale() {
    _load();
  }

  static const String _prefKey = 'app_locale';
  static const String defaultLocale = 'vi';
  static const List<String> supportedLocales = ['vi', 'en'];

  String _locale = defaultLocale;
  late Map<String, String> _strings = AppStrings.forLocale(_locale);

  /// Current locale code ('vi' or 'en').
  String get locale => _locale;

  /// Whether current locale is Vietnamese.
  bool get isVietnamese => _locale == 'vi';

  /// Translate a key. Returns the key itself if not found.
  String tr(String key) =>
      _strings[key] ?? AppStrings.forLocale(_locale)[key] ?? key;

  /// Convenience: read AppLocale from the widget tree.
  static AppLocale of(BuildContext context, {bool listen = true}) =>
      _InheritedLocale.of(context, listen: listen);

  /// Change locale and persist.
  Future<void> setLocale(String newLocale) async {
    if (newLocale == _locale || !supportedLocales.contains(newLocale)) {
      return;
    }
    _locale = newLocale;
    _strings = AppStrings.forLocale(_locale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _locale);
  }

  /// Toggle between vi ↔ en.
  Future<void> toggleLocale() async {
    await setLocale(_locale == 'vi' ? 'en' : 'vi');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && supportedLocales.contains(saved)) {
      _locale = saved;
      _strings = AppStrings.forLocale(_locale);
      notifyListeners();
    }
  }

  /// Display name for the current locale.
  String get displayName => _locale == 'vi' ? 'Tiếng Việt' : 'English';

  /// Display name for a locale code.
  static String localeName(String code) =>
      code == 'vi' ? 'Tiếng Việt' : 'English';
}

/// InheritedWidget so `AppLocale.of(context)` works with rebuilds.
class _InheritedLocale extends InheritedNotifier<AppLocale> {
  const _InheritedLocale({required AppLocale locale, required super.child})
    : super(notifier: locale);

  static AppLocale of(BuildContext context, {bool listen = true}) {
    final _InheritedLocale? widget;
    if (listen) {
      widget = context.dependOnInheritedWidgetOfExactType<_InheritedLocale>();
    } else {
      widget =
          context
                  .getElementForInheritedWidgetOfExactType<_InheritedLocale>()
                  ?.widget
              as _InheritedLocale?;
    }
    assert(widget != null, 'No _InheritedLocale found. Wrap with LocaleScope.');
    return widget!.notifier!;
  }
}

/// Wraps a subtree so that `AppLocale.of(context)` works.
///
/// Place this above MaterialApp in the widget tree.
class LocaleScope extends StatelessWidget {
  const LocaleScope({super.key, required this.locale, required this.child});

  final AppLocale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _InheritedLocale(locale: locale, child: child);
  }
}
