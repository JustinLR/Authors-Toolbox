// lib/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPreferences(); // Load the saved theme on initialization
  }

  // Toggle the theme and save the preference
  void toggleTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    _saveThemeToPreferences();
    notifyListeners();
  }

  // Save theme preference to shared_preferences
  Future<void> _saveThemeToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Load theme preference from shared_preferences
  Future<void> _loadThemeFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode =
        prefs.getBool('isDarkMode') ?? false; // Default to false if not found
    notifyListeners(); // Notify listeners after loading the preference
  }
}
