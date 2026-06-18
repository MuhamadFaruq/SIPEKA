import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryDarkBlue = Color(0xFF00479E);
  
  // Status Colors
  static const Color expenseRed = Color(0xFFFF5252);
  static const Color incomeGreen = Color(0xFF00C853);
  static const Color warningOrange = Colors.orange;

  // Background Colors
  static const Color lightBackground = Color(0xFFF5F7FF);
  static const Color darkBackground = Color(0xFF121212);
  static const Color lightCard = Colors.white;
  static const Color darkCard = Color(0xFF1E1E1E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryDarkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  // Title / Headers
  static TextStyle headline(BuildContext context) => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      );

  static TextStyle title(BuildContext context) => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleMedium?.color,
      );

  // Body
  static TextStyle body(BuildContext context) => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      );

  static TextStyle bodyBold(BuildContext context) => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      );

  // Caption
  static TextStyle caption(BuildContext context) => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
      );

  static TextStyle captionBold(BuildContext context) => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
      );
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCard,
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
          surface: AppColors.lightCard,
          primary: AppColors.primaryBlue,
          error: AppColors.expenseRed,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          bodyLarge: const TextStyle(color: Color(0xFF1A1A1A)),
          bodyMedium: const TextStyle(color: Color(0xFF454545)),
          bodySmall: const TextStyle(color: Colors.grey),
        ),
        dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.1)),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
          surface: AppColors.darkCard,
          primary: AppColors.primaryBlue,
          error: AppColors.expenseRed,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ).copyWith(
          bodySmall: const TextStyle(color: Colors.grey),
        ),
        dividerTheme: const DividerThemeData(color: Colors.white10),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkCard,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
}
