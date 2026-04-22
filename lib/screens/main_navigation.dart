import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'insight_screen.dart'; 
import 'wishlist_screen.dart'; 
import 'input_transaction_screen.dart'; 

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const InsightScreen(),
    const BudgetScreen(),
    const WishlistScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFabTapped() async { 
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InputTransactionScreen()),
    );

    if (result != null && result is int) {
      setState(() {
        _selectedIndex = result;
      });
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
      body: _screens[_selectedIndex],

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
      contentColor = isSelected ? Colors.white : Colors.white.withOpacity(0.5);
    }

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: contentColor,
              size: 24,
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