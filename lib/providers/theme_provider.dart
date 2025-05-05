import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that manages the app's theme mode preferences
///
/// Handles switching between light and dark mode and persists
/// the user's preference using SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _darkModeKey = 'darkMode';

  /// Whether the app is currently in dark mode
  bool get isDarkMode => _isDarkMode;

  /// The current theme mode (light or dark)
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Constructor initializes by loading saved theme preference
  ThemeProvider() {
    _loadThemePreference();
  }

  /// Loads the saved theme preference from SharedPreferences
  ///
  /// Defaults to light mode (false) if no preference is saved
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  /// Toggles between light and dark mode
  ///
  /// Saves the new preference to SharedPreferences and notifies listeners
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }
}
