import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.white,
      shape: const CircularNotchedRectangle(), // Membuat lubang untuk tombol +
      notchMargin: 8.0, // Jarak antara lubang dan tombol
      elevation: 10,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Menu Kiri
            Row(
              children: [
                _buildSimpleNavItem(Icons.home_rounded, 'Home', 0),
                const SizedBox(width: 20),
                _buildSimpleNavItem(Icons.account_balance_wallet_rounded, 'Anggaran', 1),
              ],
            ),
            
            const SizedBox(width: 40), // Ruang kosong untuk tombol melayang di tengah

            // Menu Kanan
            Row(
              children: [
                _buildSimpleNavItem(Icons.favorite_rounded, 'Wishlist', 3),
                const SizedBox(width: 20),
                _buildSimpleNavItem(Icons.settings_rounded, 'Settings', 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleNavItem(IconData icon, String label, int index) {
    bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primaryBlue : AppColors.neutralGrey,
            size: 24,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColors.primaryBlue : AppColors.neutralGrey,
            ),
          ),
        ],
      ),
    );
  }
}