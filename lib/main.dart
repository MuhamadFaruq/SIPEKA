// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Providers
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/category/presentation/controllers/category_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/wishlist/presentation/controllers/wishlist_provider.dart';
import 'package:sipeka/features/quick_action/presentation/controllers/quick_action_provider.dart';
import 'package:sipeka/features/debt/presentation/controllers/debt_provider.dart';
import 'package:sipeka/core/theme/theme_provider.dart';

// Import Utils & Screens
import 'package:sipeka/features/auth/presentation/screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sipeka/core/services/notification_service.dart';


import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    debugPrint(".env Loaded Successfully!");
  } catch (e) {
    debugPrint("Error loading .env: $e");
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase Berhasil Terkoneksi!");
  } catch (e) {
    debugPrint("Firebase Error: $e");
  }

  // 1. Inisialisasi data dasar
  await initializeDateFormatting('id_ID', null); 
  await NotificationService.init();

  // --- TAMBAHKAN INI: Minta izin Notifikasi & Exact Alarm ---
  // Tanpa ini, scheduleReminder di bawah akan gagal di Android 13/14
  await NotificationService.requestPermission(); 
  // ----------------------------------------------------------

  // 2. Ambil status pengingat dari memori HP
  final prefs = await SharedPreferences.getInstance();
  final bool isReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;

  final int savedHour = prefs.getInt('reminder_hour') ?? 20;
  final int savedMinute = prefs.getInt('reminder_minute') ?? 0;

  // ✅ TAMBAHKAN DI SINI — tulis default sekali saat fresh install
  if (!prefs.containsKey('reminder_hour')) {
    await prefs.setInt('reminder_hour', 20);
    await prefs.setInt('reminder_minute', 0);
  }

  if (isReminderEnabled) {
    try {
      await NotificationService.scheduleReminder(hour: savedHour, minute: savedMinute);
      debugPrint("Pengingat dijadwalkan pukul $savedHour:$savedMinute");
    } catch (e) {
      debugPrint("Gagal menjadwalkan: $e");
    }
  } else {
    await NotificationService.cancelAll();
  }
  
  runApp(const SIPEKAApp());
}

class SIPEKAApp extends StatelessWidget {
  const SIPEKAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Tambahkan ThemeProvider di sini
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Fokus pada Fetching Data dari SQLite (Database Lokal)
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..fetchAndSetTransactions(),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider()..fetchAndSetBudgets(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider()..fetchAndSetWishlist(),
        ),
        ChangeNotifierProvider(
          create: (_) => DebtProvider()..fetchAndSetDebts(),
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        // Cari baris ini di main.dart dan ubah:
        ChangeNotifierProvider(create: (_) => QuickActionProvider()..loadActions()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'SIPEKA',
            debugShowCheckedModeBanner: false,
            
            // 1. Ambil status tema dari Provider
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // 2. Gunakan getter lightTheme yang sudah kita poles di ThemeProvider.dart
            theme: themeProvider.lightTheme, 

            // 3. Gunakan getter darkTheme yang ada di ThemeProvider.dart
            darkTheme: themeProvider.darkTheme,
            
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}