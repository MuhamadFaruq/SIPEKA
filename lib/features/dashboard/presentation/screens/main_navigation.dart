import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sipeka/features/budget/presentation/screens/budget_screen.dart';
import 'package:sipeka/features/transaction/presentation/screens/home_screen.dart';
import 'package:sipeka/features/insight/presentation/screens/insight_screen.dart'; 
import 'package:sipeka/features/wishlist/presentation/screens/wishlist_screen.dart'; 
import 'package:sipeka/features/transaction/presentation/screens/input_transaction_screen.dart'; 

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
      MaterialPageRoute(builder: (context) => const InputTransactionScreen()),
    );

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
    
    // Gunakan primaryBlue asli saat terang, atau warna primary dari theme saat gelap
    final Color primaryBlue = const Color(0xFF2972FF);
    
    // Warna background BottomBar: Biru saat terang, CardColor (Gelap) saat malam
    final Color navBarColor = isDark ? Theme.of(context).cardColor : primaryBlue;

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

      // FAB Besar di Tengah
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: _onFabTapped,
          // FAB tetap biru agar menonjol sebagai tombol utama
          backgroundColor: primaryBlue,
          shape: const CircleBorder(),
          elevation: isDark ? 0 : 4,
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Navigasi Bawah
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(vertical: 0),
        height: 65, 
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        // --- FIX: Warna background nav dinamis ---
        color: navBarColor, 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menu Kiri
              Row(
                children: [
                  _buildNavItem(0, Icons.home, "Rumah"),
                  const SizedBox(width: 15),
                  _buildNavItem(1, Icons.bar_chart, "Grafik"),
                ],
              ),
              // Menu Kanan
              Row(
                children: [
                  _buildNavItem(2, Icons.pie_chart, "Anggaran"),
                  const SizedBox(width: 15),
                  _buildNavItem(3, Icons.favorite, "Wishlist"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- FIX: Warna Ikon & Teks ---
    // Di mode gelap: Putih saat dipilih, Abu-abu saat tidak.
    // Di mode terang: Putih saat dipilih, Putih transparan saat tidak.
    Color contentColor;
    if (isDark) {
      contentColor = isSelected ? const Color(0xFF2972FF) : Colors.grey;
    } else {
      contentColor = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5);
    }

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF2972FF).withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.18 : 1.0,
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
