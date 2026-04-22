import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7FF), 
    cardColor: Colors.white,
    primaryColor: const Color(0xFF007AFF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      bodyLarge: const TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: const TextStyle(color: Color(0xFF454545)),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.1)),
  );

  // --- TEMA GELAP ---
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    primaryColor: const Color(0xFF007AFF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
    ),
    textTheme: GoogleFonts.nunitoTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
    dividerTheme: const DividerThemeData(color: Colors.white10),
  );
}