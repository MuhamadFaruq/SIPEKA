import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/budget/presentation/controllers/budget_provider.dart';
import 'package:sipeka/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:sipeka/features/auth/presentation/screens/pre_login_screen.dart';
import 'package:sipeka/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // 1. Jalankan timer delay minimal 800ms agar animasi splash terlihat bagus
    await Future.delayed(const Duration(milliseconds: 800)); 
    
    if (!mounted) return;

    // 2. Tunggu sampai data database selesai dimuat agar tidak ada kedipan skeleton loader saat masuk dashboard
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final bgProvider = Provider.of<BudgetProvider>(context, listen: false);
    while (txProvider.isLoading || bgProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    final bool isCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!isCompleted) {
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(child: const OnboardingScreen()),
      );
    } else {
      // Setelah onboarding selesai → selalu ke PreLoginScreen
      // PreLoginScreen yang akan mengurus routing ke PinScreen atau MainNavigation
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const PreLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2972FF);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A4BB3) : primaryBlue,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SIPEKA',
                  style: GoogleFonts.nunito(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Teman Keuangan Kamu',
                  style: GoogleFonts.nunito(
                    fontSize: 16, 
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.2
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.5),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
