import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Providers
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/quick_action_provider.dart';
import 'providers/debt_provider.dart';

// Import Utils & Screens
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); 
  runApp(const SIPEKAApp());
}

class SIPEKAApp extends StatelessWidget {
  const SIPEKAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider yang butuh load data
        ChangeNotifierProvider(create: (_) => TransactionProvider()..loadTransactions()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        
        // PERBAIKAN DI SINI:
        // Cukup panggil BudgetProvider() saja tanpa loadBudgets()
        ChangeNotifierProvider(create: (_) => BudgetProvider()), 
        ChangeNotifierProvider(create: (_) => QuickActionProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        title: 'SIPEKA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            primary: AppColors.primaryBlue,
            secondary: AppColors.darkBlue,
            background: AppColors.backgroundLight,
            surface: AppColors.white,
          ),
          scaffoldBackgroundColor: AppColors.backgroundLight,
          textTheme: GoogleFonts.poppinsTextTheme(),
          cardTheme: CardThemeData(
            elevation: AppDimensions.elevationLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            color: AppColors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.darkBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}