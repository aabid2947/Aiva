import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the user's theme preference (system / light / dark) and persists it.
/// Provided above MaterialApp; `themeMode` reads `mode`.
class ThemeController extends ChangeNotifier {
  ThemeController([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'aiva_theme_mode';
  final FlutterSecureStorage _storage;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final saved = await _storage.read(key: _key);
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _storage.write(key: _key, value: mode.name);
  }
}
