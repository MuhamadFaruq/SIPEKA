enum WishlistHistoryType {
  deposit,
  withdraw,
}

class WishlistHistoryEntity {
  final String id;
  final String wishlistId;
  final String wishlistTitle;
  final WishlistHistoryType type;
  final double amount;
  final DateTime date;
  final String? notes;

  WishlistHistoryEntity({
    required this.id,
    required this.wishlistId,
    required this.wishlistTitle,
    required this.type,
    required this.amount,
    required this.date,
    this.notes,
  });

  bool get isDeposit => type == WishlistHistoryType.deposit;
  bool get isWithdraw => type == WishlistHistoryType.withdraw;
}
