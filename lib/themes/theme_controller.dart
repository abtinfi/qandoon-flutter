import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeMode get currentThemeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
