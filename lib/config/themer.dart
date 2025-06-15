import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    final box = Hive.box('settingsBox');
    final stored = box.get('theme', defaultValue: 'dark');
    _themeMode = stored == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    Hive.box('settingsBox').put('theme', isDark ? 'dark' : 'light');
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
