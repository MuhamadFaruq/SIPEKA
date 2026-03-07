
class Budget {
  final String id;
  final String category;
  final int iconCode; // Simpan kode ikon di sini
  double limit;
  double usedAmount;

  Budget({
    required this.id,
    required this.category,
    required this.iconCode, // Tambahkan baris ini
    required this.limit,
    this.usedAmount = 0.0,
  });

  // Helper untuk menghitung persentase (0.0 sampai 1.0)
  double get percentage => (usedAmount / limit).clamp(0.0, 1.0);
}