class WishlistEntity {
  final String id;
  final String title;
  final double targetAmount;
  double savedAmount;

  WishlistEntity({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
  });

  double get progress {
    if (targetAmount == 0) return 0.0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => savedAmount >= targetAmount;
}

typedef WishlistItem = WishlistEntity;
