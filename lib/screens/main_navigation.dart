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
    const Color primaryBlue = Color(0xFF2972FF);

    return Scaffold(
      // PERBAIKAN UTAMA: Mencegah FAB dan Bottom Bar terangkat saat keyboard muncul
      resizeToAvoidBottomInset: false, 
      
      body: _screens[_selectedIndex],

      // FAB Besar di Tengah
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: _onFabTapped,
          backgroundColor: primaryBlue,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Navigasi Bawah
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(vertical: 0),
        height: 65, // Sedikit ditinggikan agar pas dengan Notch FAB
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        color: primaryBlue,
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

  // Widget Nav Item dengan Urutan Parameter yang Benar (index, icon, label)
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Membuat isi kolom sependek mungkin
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              size: 24, // Perkecil sedikit dari 30 ke 24 agar teks di bawahnya punya ruang
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
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