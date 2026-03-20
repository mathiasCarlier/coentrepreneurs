import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class ThemeNotifier extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode;

  ThemeNotifier() : _mode = _load();

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _save(_mode);
    notifyListeners();
  }

  static ThemeMode _load() {
    if (!kIsWeb) return ThemeMode.light;
    try {
      final stored = html.window.localStorage[_key];
      return stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      return ThemeMode.light;
    }
  }

  void _save(ThemeMode mode) {
    if (!kIsWeb) return;
    try {
      html.window.localStorage[_key] = mode == ThemeMode.dark ? 'dark' : 'light';
    } catch (_) {}
  }
}
