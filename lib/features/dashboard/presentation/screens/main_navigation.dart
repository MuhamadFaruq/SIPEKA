import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/features/budget/presentation/screens/budget_screen.dart';
import 'package:sipeka/features/transaction/presentation/screens/home_screen.dart';
import 'package:sipeka/features/insight/presentation/screens/insight_screen.dart'; 
import 'package:sipeka/features/wishlist/presentation/screens/wishlist_screen.dart'; 
import 'package:sipeka/features/transaction/presentation/screens/input_transaction_screen.dart'; 
import 'package:sipeka/core/services/app_security_manager.dart';
import 'package:sipeka/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/core/services/shared_wallet_sync_service.dart';
import 'package:sipeka/features/transaction/presentation/controllers/transaction_provider.dart';
import 'package:sipeka/features/wallet/presentation/controllers/wallet_provider.dart';
import 'package:sipeka/features/insight/presentation/controllers/financial_health_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    AppSecurityManager.isAuthenticated = true;
    
    // Mulai listener sinkronisasi Dompet Bersama (real-time)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SharedWalletSyncService.instance.startListeningToSharedWallets(
          onTransactionUpdated: () {
            if (mounted) {
              Provider.of<TransactionProvider>(context, listen: false).fetchAndSetTransactions();
            }
          },
          onWalletUpdated: () {
            if (mounted) {
              Provider.of<WalletProvider>(context, listen: false).fetchAndSetWallets();
            }
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const InsightScreen(),
    const BudgetScreen(),
    const WishlistScreen(),
  ];

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onFabTapped() async { 
    final result = await Navigator.push(
      context,
      SmoothPageRoute(child: const InputTransactionScreen()),
    );

    if (mounted) {
      Provider.of<FinancialHealthProvider>(context, listen: false).calculateHealthScore();
    }

    if (result != null && result is int) {
      _pageController.animateToPage(
        result,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- VARIABEL TEMA ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna background BottomBar: Selalu gunakan cardColor (Putih saat terang, abu-abu saat malam)
    final Color navBarColor = Theme.of(context).cardColor;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),

      // FAB Besar di Tengah dengan Gradient & Glow Shadow
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF005BC5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: _onFabTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Navigasi Bawah
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomAppBar(
          padding: const EdgeInsets.symmetric(vertical: 0),
          height: 65, 
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          color: navBarColor, 
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu Kiri
                Row(
                  children: [
                    _buildNavItem(0, Icons.home_rounded, "Rumah"),
                    const SizedBox(width: 15),
                    _buildNavItem(1, Icons.bar_chart_rounded, "Grafik"),
                  ],
                ),
                // Menu Kanan
                Row(
                  children: [
                    _buildNavItem(2, Icons.pie_chart_rounded, "Anggaran"),
                    const SizedBox(width: 15),
                    _buildNavItem(3, Icons.favorite_rounded, "Wishlist"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;

    // --- WARNA IKON & TEKS MODERN ---
    // Biru saat dipilih, Abu-abu saat tidak aktif untuk mode terang maupun gelap.
    final Color contentColor = isSelected ? const Color(0xFF007AFF) : Colors.grey.withOpacity(0.8);

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: contentColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: contentColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
