class WishlistItem {
  final String id;
  final String title;
  final double targetAmount;
  double savedAmount; // Tidak final karena bisa bertambah

  WishlistItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
  });

  // Getter untuk menghitung persentase (0.0 sampai 1.0)
  double get progress {
    if (targetAmount == 0) return 0;
    return savedAmount / targetAmount;
  }
}