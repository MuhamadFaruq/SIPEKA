import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Strictly use these)
  static const Color primaryBlue = Color(0xFF007AFF); // Main Brand
  static const Color darkBlue = Color(0xFF00479E); // Headers/Accent
  
  // Background Colors
  static const Color neutralGrey = Color(0xFFD9D9D9); // Backgrounds/Inactive
  static const Color white = Color(0xFFFFFFFF); // Surface
  static const Color backgroundLight = Color(0xFFF5F7FA);
  
  // Status Colors
  static const Color expenseRed = Color(0xFFD40000); // Expense/Danger
  static const Color incomeGreen = Color(0xFF22CC00); // Income/Success
  static const Color warningYellow = Color(0xFFFFDD00); // Warning
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Legacy support (for existing code)
  static const Color primaryBlueDark = darkBlue;
  static const Color primaryBlueLight = primaryBlue;
  static const Color backgroundWhite = white;
  static const Color successGreen = incomeGreen;
  static const Color errorRed = expenseRed;
}

class AppDimensions {
  // Border Radius (Rounded corners for friendly feel)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0; // Updated to 20 for cards
  static const double radiusXLarge = 32.0;
  
  // Spacing (Golden Ratio based)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 40.0;
  static const double spacingXXL = 64.0;
  
  // Elevation/Shadows
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24.0);
}

class AppTextStyles {
  // Font families (Rounded/Friendly)
  static const String fontFamily = 'Poppins'; // Primary
  static const String fontFamilyAlt = 'Nunito'; // Alternative
}

