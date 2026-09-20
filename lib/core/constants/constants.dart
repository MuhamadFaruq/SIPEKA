import 'package:flutter/material.dart';

class AppIcons {
  static const Map<String, IconData> iconMapping = {
    // Pengeluaran
    'Makan': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Belanja': Icons.shopping_bag,
    'Kesehatan': Icons.medical_services,
    'Pendidikan': Icons.school,
    'Tagihan': Icons.receipt_long,
    'Hiburan': Icons.confirmation_number,
    'Rumah': Icons.home,
    'Camilan': Icons.fastfood,
    'Bensin': Icons.local_gas_station,
    'Parkir': Icons.local_parking,
    'Minum': Icons.local_cafe,
    'Internet': Icons.wifi,
    'Listrik': Icons.flash_on,
    'Transfer': Icons.swap_horiz,
    // Pemasukan
    'Gaji': Icons.work,
    'Hadiah': Icons.card_giftcard,
    'Bonus': Icons.monetization_on,
    'Penjualan': Icons.storefront,
    'Jualan': Icons.storefront,
    'Investasi': Icons.trending_up,
    'Freelance': Icons.laptop_mac,
    // Default
    'Lainnya': Icons.category,
  };

  /// Daftar ikon yang tersedia untuk dipilih user saat membuat kategori baru
  static const Map<String, IconData> availableIcons = {
    'Makan': Icons.restaurant,
    'Minum': Icons.local_cafe,
    'Camilan': Icons.fastfood,
    'Belanja': Icons.shopping_bag,
    'Transport': Icons.directions_car,
    'Bensin': Icons.local_gas_station,
    'Parkir': Icons.local_parking,
    'Tagihan': Icons.receipt_long,
    'Kesehatan': Icons.medical_services,
    'Pendidikan': Icons.school,
    'Hiburan': Icons.confirmation_number,
    'Rumah': Icons.home,
    'Internet': Icons.wifi,
    'Listrik': Icons.flash_on,
    'Gaji': Icons.work,
    'Hadiah': Icons.card_giftcard,
    'Bonus': Icons.monetization_on,
    'Investasi': Icons.trending_up,
    'Freelance': Icons.laptop_mac,
    'Penjualan': Icons.storefront,
    'Olahraga': Icons.fitness_center,
    'Pakaian': Icons.checkroom,
    'Kecantikan': Icons.face,
    'Hewan': Icons.pets,
    'Donasi': Icons.volunteer_activism,
    'Asuransi': Icons.shield,
    'Tabungan': Icons.savings,
    'Lainnya': Icons.category,
  };

  /// Daftar ikon yang diperluas (~90 ikon) dikelompokkan per kategori
  /// Digunakan oleh IconPickerSheet untuk tampilan grid grouped
  static const Map<String, Map<String, IconData>> groupedIcons = {
    'Keuangan': {
      'Dompet': Icons.wallet_rounded,
      'Bank': Icons.account_balance_rounded,
      'Kartu Kredit': Icons.credit_card_rounded,
      'Tabungan': Icons.savings_rounded,
      'Uang': Icons.money_rounded,
      'Pembayaran': Icons.payments_rounded,
      'Tukar Uang': Icons.currency_exchange_rounded,
      'Monetisasi': Icons.monetization_on_rounded,
      'Tagihan': Icons.receipt_long_rounded,
      'Koin': Icons.toll_rounded,
    },
    'Makanan & Minuman': {
      'Restoran': Icons.restaurant_rounded,
      'Cepat Saji': Icons.fastfood_rounded,
      'Kafe': Icons.local_cafe_rounded,
      'Bar': Icons.local_bar_rounded,
      'Pizza': Icons.local_pizza_rounded,
      'Kue': Icons.cake_rounded,
      'Minuman': Icons.coffee_rounded,
      'Es Krim': Icons.icecream_rounded,
      'Dapur': Icons.kitchen_rounded,
      'Belanja Makan': Icons.shopping_basket_rounded,
    },
    'Transportasi': {
      'Mobil': Icons.directions_car_rounded,
      'Bensin': Icons.local_gas_station_rounded,
      'Motor': Icons.two_wheeler_rounded,
      'Pesawat': Icons.flight_rounded,
      'Kereta': Icons.train_rounded,
      'Bus': Icons.directions_bus_rounded,
      'Taksi': Icons.local_taxi_rounded,
      'Parkir': Icons.local_parking_rounded,
      'Sepeda': Icons.pedal_bike_rounded,
      'Kapal': Icons.directions_boat_rounded,
    },
    'Belanja': {
      'Tas Belanja': Icons.shopping_bag_rounded,
      'Keranjang': Icons.shopping_cart_rounded,
      'Toko': Icons.store_rounded,
      'Etalase': Icons.storefront_rounded,
      'Mall': Icons.local_mall_rounded,
      'Hadiah': Icons.redeem_rounded,
      'Kado': Icons.card_giftcard_rounded,
      'Diskon': Icons.local_offer_rounded,
    },
    'Rumah & Utilitas': {
      'Rumah': Icons.home_rounded,
      'Listrik': Icons.flash_on_rounded,
      'WiFi': Icons.wifi_rounded,
      'Air': Icons.water_drop_rounded,
      'Perbaikan': Icons.build_rounded,
      'Kebersihan': Icons.cleaning_services_rounded,
      'AC': Icons.ac_unit_rounded,
      'Furniture': Icons.chair_rounded,
      'Taman': Icons.yard_rounded,
      'Kunci': Icons.vpn_key_rounded,
    },
    'Kesehatan': {
      'Medis': Icons.medical_services_rounded,
      'Rumah Sakit': Icons.local_hospital_rounded,
      'Gym': Icons.fitness_center_rounded,
      'Spa': Icons.spa_rounded,
      'Meditasi': Icons.self_improvement_rounded,
      'Obat': Icons.medication_rounded,
      'Favorit': Icons.favorite_rounded,
      'Kesehatan': Icons.health_and_safety_rounded,
    },
    'Pendidikan': {
      'Sekolah': Icons.school_rounded,
      'Buku': Icons.menu_book_rounded,
      'Sains': Icons.science_rounded,
      'Komputer': Icons.computer_rounded,
      'Kalkulator': Icons.calculate_rounded,
      'Bahasa': Icons.translate_rounded,
      'Perpustakaan': Icons.local_library_rounded,
      'Wisuda': Icons.psychology_rounded,
    },
    'Hiburan': {
      'Tiket': Icons.confirmation_number_rounded,
      'Game': Icons.sports_esports_rounded,
      'Film': Icons.movie_rounded,
      'Musik': Icons.music_note_rounded,
      'Headphone': Icons.headphones_rounded,
      'TV': Icons.tv_rounded,
      'Foto': Icons.photo_camera_rounded,
      'Seni': Icons.palette_rounded,
    },
    'Kerja & Bisnis': {
      'Kerja': Icons.work_rounded,
      'Laptop': Icons.laptop_mac_rounded,
      'Kantor': Icons.business_center_rounded,
      'Trending': Icons.trending_up_rounded,
      'Grafik': Icons.assessment_rounded,
      'Meeting': Icons.groups_rounded,
      'Email': Icons.email_rounded,
      'Telepon': Icons.phone_rounded,
    },
    'Lainnya': {
      'Hewan': Icons.pets_rounded,
      'Pakaian': Icons.checkroom_rounded,
      'Kecantikan': Icons.face_rounded,
      'Donasi': Icons.volunteer_activism_rounded,
      'Asuransi': Icons.shield_rounded,
      'Olahraga': Icons.sports_soccer_rounded,
      'Anak': Icons.child_care_rounded,
      'Bintang': Icons.star_rounded,
      'Kategori': Icons.category_rounded,
      'Lainnya': Icons.more_horiz_rounded,
    },
  };

  /// Semua ikon dari groupedIcons dalam satu flat list
  static List<IconData> get allIcons {
    final icons = <IconData>[];
    for (final group in groupedIcons.values) {
      icons.addAll(group.values);
    }
    return icons;
  }

  /// Cari nama ikon berdasarkan codePoint — mencari di semua daftar ikon
  static String getIconName(int codePoint) {
    // 1. Cari di groupedIcons (daftar baru ~90 ikon)
    for (final group in groupedIcons.entries) {
      for (final icon in group.value.entries) {
        if (icon.value.codePoint == codePoint) {
          return icon.key;
        }
      }
    }
    // 2. Cari di iconMapping (daftar lama by category name)
    for (final entry in iconMapping.entries) {
      if (entry.value.codePoint == codePoint) {
        return entry.key;
      }
    }
    // 3. Cari di availableIcons
    for (final entry in availableIcons.entries) {
      if (entry.value.codePoint == codePoint) {
        return entry.key;
      }
    }
    return 'Custom';
  }

  // Dynamic registry untuk ikon kategori kustom (diperbarui oleh BudgetProvider/user)
  static final Map<String, int> _customCategoryIcons = {};

  /// Daftarkan ikon kategori yang disesuaikan oleh user
  static void registerCategoryIcon(String categoryName, int iconCode) {
    if (categoryName.isNotEmpty && iconCode != 0) {
      _customCategoryIcons[categoryName.toLowerCase().trim()] = iconCode;
    }
  }

  /// Daftarkan daftar budget ke mapping ikon dinamis
  static void registerBudgets(List<dynamic> budgets) {
    for (final b in budgets) {
      try {
        final category = b.category as String;
        final iconCode = b.iconCode as int;
        if (category.isNotEmpty && iconCode != 0) {
          _customCategoryIcons[category.toLowerCase().trim()] = iconCode;
        }
      } catch (_) {}
    }
  }

  /// Hapus pendaftaran ikon kategori
  static void unregisterCategoryIcon(String categoryName) {
    _customCategoryIcons.remove(categoryName.toLowerCase().trim());
  }

  /// Fungsi pembantu untuk mengambil ikon berdasarkan nama kategori atau iconCode eksplisit
  static IconData getIcon(String categoryName, {int? iconCode}) {
    if (iconCode != null && iconCode != 0) {
      return IconData(iconCode, fontFamily: 'MaterialIcons');
    }

    final trimmed = categoryName.trim();
    final lower = trimmed.toLowerCase();

    // 1. Cek di registry kustom (hasil pilihan user di budget/kelola ikon)
    if (_customCategoryIcons.containsKey(lower)) {
      final code = _customCategoryIcons[lower]!;
      if (code != 0) {
        return IconData(code, fontFamily: 'MaterialIcons');
      }
    }

    // 2. Cek di iconMapping langsung (exact match)
    if (iconMapping.containsKey(trimmed)) {
      return iconMapping[trimmed]!;
    }

    // 3. Cek di iconMapping (case-insensitive)
    for (final entry in iconMapping.entries) {
      if (entry.key.toLowerCase() == lower) {
        return entry.value;
      }
    }

    // 4. Cek di availableIcons (case-insensitive)
    for (final entry in availableIcons.entries) {
      if (entry.key.toLowerCase() == lower) {
        return entry.value;
      }
    }

    // 5. Cek di groupedIcons (semua 90+ ikon)
    for (final group in groupedIcons.values) {
      for (final icon in group.entries) {
        if (icon.key.toLowerCase() == lower) {
          return icon.value;
        }
      }
    }

    // 6. Default fallback aman: gunakan Icons.category_rounded, bukan help_outline (?)
    return Icons.category_rounded;
  }
}

class AppColors {
  // Primary Colors (Strictly use these)
  static const Color primaryBlue = Color(0xFF007AFF); // Main Brand
  static const Color darkBlue = Color(0xFF00479E); // Headers/Accent
  
  // Background Colors
  static const Color neutralGrey = Color(0xFFD9D9D9); // Backgrounds/Inactive
  static const Color white = Color(0xFFFFFFFF); // Surface
  static const Color backgroundLight = Color(0xFFF5F7FA);
  
  // Status Colors
  static const Color expenseRed = Color(0xFFD40000); // Expense/Danger
  static const Color incomeGreen = Color(0xFF22CC00); // Income/Success
  static const Color warningYellow = Color(0xFFFFDD00); // Warning
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Legacy support (for existing code)
  static const Color primaryBlueDark = darkBlue;
  static const Color primaryBlueLight = primaryBlue;
  static const Color backgroundWhite = white;
  static const Color successGreen = incomeGreen;
  static const Color errorRed = expenseRed;
}

class AppDimensions {
  // Border Radius (Rounded corners for friendly feel)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0; // Updated to 20 for cards
  static const double radiusXLarge = 32.0;
  
  // Spacing (Golden Ratio based)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 40.0;
  static const double spacingXXL = 64.0;
  
  // Elevation/Shadows
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24.0);
}

class AppTextStyles {
  // Font families (Rounded/Friendly)
  static const String fontFamily = 'Poppins'; // Primary
  static const String fontFamilyAlt = 'Nunito'; // Alternative
}

