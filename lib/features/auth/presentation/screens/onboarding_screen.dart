import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipeka/core/constants/constants.dart';
import 'package:sipeka/widgets/custom_button.dart';
import 'package:sipeka/core/services/notifications.dart'; 
import 'package:sipeka/features/dashboard/presentation/screens/main_navigation.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/core/theme/theme_provider.dart';
import 'package:sipeka/core/theme/app_theme.dart' hide AppColors;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Multi-Dompet & Transaksi',
      description: 'Kelola kas fisik, bank, dan e-wallet secara terpisah. Catat pengeluaran, pemasukan, serta transfer saldo antar dompet dengan praktis.',
    ),
    OnboardingPageData(
      icon: Icons.psychology_rounded,
      title: 'Asisten AI & Pemindai Pintar',
      description: 'Catat otomatis lewat suara (Voice Input) atau pemindaian foto struk belanja (OCR), serta konsultasikan masalah keuanganmu dengan SIPEKA AI.',
    ),
    OnboardingPageData(
      icon: Icons.people_alt_rounded,
      title: 'Dompet Bersama (Shared Wallet)',
      description: 'Bagikan akses dompet khusus secara real-time ke pasangan atau keluarga via kode undangan untuk mengelola keuangan rumah tangga bersama.',
    ),
    OnboardingPageData(
      icon: Icons.insights_rounded,
      title: 'Laporan Visual & Target',
      description: 'Pantau pola keuangan lewat grafik interaktif, capai barang impian (Wishlist), serta ekspor laporan bulanan berformat PDF yang elegan.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length) { 
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_nameController.text.trim().isEmpty) {
        SipekaNotification.showWarning(context, "Isi nama dulu ya biar lebih akrab!");
      } else {
        _completeOnboarding();
      }
    }
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      _pages.length,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      // Perbarui nama melalui ThemeProvider agar langsung terhubung ke settings dan seluruh aplikasi
      Provider.of<ThemeProvider>(context, listen: false).updateName(name);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(child: const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true, 
      body: SafeArea(
        child: Column(
          children: [
            AnimatedOpacity(
              opacity: _currentPage < _pages.length ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _currentPage < _pages.length ? _skipOnboarding : null,
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.nunito(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length + 1, 
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildOnboardingPage(context, _pages[index]);
                  } else {
                    return _buildNameInputPage(context);
                  }
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length + 1,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF2972FF)
                              : (isDark ? Colors.white24 : AppColors.neutralGrey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  
                  CustomButton(
                    text: _currentPage < _pages.length ? 'Lanjut' : 'Mulai',
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(BuildContext context, OnboardingPageData page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2972FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon, 
              size: 60,
              color: const Color(0xFF2972FF),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXXL),
          Text(
            page.title,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            page.description,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNameInputPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacingXXL),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2972FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 60,
              color: Color(0xFF2972FF),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXXL),
          Text(
            'Siapa Namamu?',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'Kita kenalan dulu, biar lebih akrab!',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXXL),
          TextField(
            controller: _nameController,
            onSubmitted: (_) => _nextPage(), 
            textInputAction: TextInputAction.done,
            autofocus: false, 
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan nama kamu',
              hintStyle: GoogleFonts.nunito(color: Colors.grey),
              filled: true,
              fillColor: Theme.of(context).cardColor, 
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppDimensions.spacingXXL), 
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
