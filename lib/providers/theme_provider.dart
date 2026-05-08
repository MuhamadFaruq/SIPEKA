import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  // --- TAMBAHKAN VARIABEL NAMA ---
  String _userName = "User"; 

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName; // Getter untuk dipanggil di UI

  ThemeProvider() {
    _loadSettings();
  }

  // Load status tema DAN nama dari memori HP
  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    // Ambil nama, kalau kosong defaultnya "User" agar tidak null"
    _userName = prefs.getString('user_name') ?? "User";
    notifyListeners();
  }

  // --- FUNGSI UPDATE NAMA DINAMIS ---
  void updateName(String newName) async {
    _userName = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
    notifyListeners(); // Memicu perubahan di semua layar yang pakai nama ini
  }

  // --- TOGGLE TEMA ---
  void toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  // --- TEMA TERANG ---
  ThemeData get lightTheme => AppTheme.lightTheme;

  // --- TEMA GELAP ---
  ThemeData get darkTheme => AppTheme.darkTheme;
}