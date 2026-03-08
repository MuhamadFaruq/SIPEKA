// main.dart

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
  
  // Inisialisasi format tanggal Indonesia
  await initializeDateFormatting('id_ID', null); 
  
  runApp(const SIPEKAApp());
}

class SIPEKAApp extends StatelessWidget {
  const SIPEKAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // PERBAIKAN: Memanggil fungsi fetch data dari SQLite saat Provider pertama kali dibuat
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..fetchAndSetTransactions(),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider()..fetchAndSetBudgets(),
        ),
        
        // Provider lainnya
        ChangeNotifierProvider(
          create: (_) => WishlistProvider()..fetchAndSetWishlist(),
        ),
        ChangeNotifierProvider(
          create: (_) => DebtProvider()..fetchAndSetDebts(),
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        ChangeNotifierProvider(create: (_) => QuickActionProvider()),
      ],
      child: MaterialApp(
        title: 'SIPEKA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            primary: AppColors.primaryBlue,
            secondary: AppColors.darkBlue,
          ),
          scaffoldBackgroundColor: AppColors.backgroundLight,
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}