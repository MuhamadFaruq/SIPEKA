import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _userName = "User"; 

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName; 

  ThemeProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _userName = prefs.getString('user_name') ?? "User";
    notifyListeners();
  }

  void updateName(String newName) async {
    _userName = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
    notifyListeners(); 
  }

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;
}
