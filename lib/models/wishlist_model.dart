/// Model Item Wishlist — Sumber Kebenaran Tunggal (Single Source of Truth)
class WishlistItem {
  final String id;
  final String title;
  final double targetAmount;
  double savedAmount;

  WishlistItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
  });

  /// Persentase tabungan (0.0 sampai 1.0)
  double get progress {
    if (targetAmount == 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => savedAmount >= targetAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
    };
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'].toString(),
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num).toDouble(),
    );
  }

  WishlistItem copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
    );
  }
}