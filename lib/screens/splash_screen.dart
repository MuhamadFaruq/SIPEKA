import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; 
import 'package:shared_preferences/shared_preferences.dart'; // <--- Tambahkan ini
import 'main_navigation.dart';
import 'onboarding_screen.dart'; // <--- Tambahkan ini

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

  // LOGIKA: Cek status Onboarding dari Memori HP
  void _navigateToNext() async {
    // Tunggu sebentar agar logo sempat terlihat (misal 1.5 detik)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    // Ambil status apakah onboarding sudah selesai
    final bool isCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (isCompleted) {
      // Jika sudah kenalan, langsung ke Menu Utama
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(), // atau OnboardingScreen()
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // Jika user baru, arahkan ke Onboarding/Kenalan Nama
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan warna primer biru SIPEKA agar konsisten
    const Color primaryBlue = Color(0xFF2972FF);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo SIPEKA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
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
          // Indikator Loading di bagian bawah
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}