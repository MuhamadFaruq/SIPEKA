import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';
import 'onboarding_screen.dart';
import 'pin_screen.dart';
import 'pre_login_screen.dart';

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
    await Future.delayed(const Duration(milliseconds: 800)); 
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!isCompleted) {
      // Jika belum onboarding, ke onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // APAPUN kondisinya (pakai PIN atau tidak), arahkan ke PreLogin dulu
      // Halaman PIN baru akan dipanggil di dalam PreLogin saat tombol 'Login' diklik
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
    // Kita tetap pakai biru utama SIPEKA sebagai identitas brand
    const Color primaryBlue = Color(0xFF2972FF);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Jika mode gelap, kita buat birunya sedikit lebih deep agar tidak terlalu kontras saat dibuka malam hari
      backgroundColor: isDark ? const Color(0xFF1A4BB3) : primaryBlue,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo SIPEKA dengan efek glow tipis
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
          // Indikator Loading
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