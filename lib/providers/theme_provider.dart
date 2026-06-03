import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'theme_mode_v1';

  ThemeProvider() {
    load();
  }

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_storageKey);
    if (index == null) return;

    switch (index) {
      case 0:
        _mode = ThemeMode.light;
        break;
      case 1:
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    final index = switch (mode) {
      ThemeMode.light => 0,
      ThemeMode.dark => 1,
      _ => 2,
    };
    await prefs.setInt(_storageKey, index);
    notifyListeners();
  }
}
