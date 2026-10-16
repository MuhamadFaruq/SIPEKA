import '../../domain/entities/wishlist_history_entity.dart';

class WishlistHistoryModel extends WishlistHistoryEntity {
  WishlistHistoryModel({
    required super.id,
    required super.wishlistId,
    required super.wishlistTitle,
    required super.type,
    required super.amount,
    required super.date,
    super.notes,
  });

  factory WishlistHistoryModel.fromMap(Map<String, dynamic> map) {
    return WishlistHistoryModel(
      id: (map['id'] ?? '').toString(),
      wishlistId: (map['wishlist_id'] ?? map['wishlistId'] ?? '').toString(),
      wishlistTitle: (map['wishlist_title'] ?? map['wishlistTitle'] ?? '').toString(),
      type: (map['type']?.toString()) == 'withdraw'
          ? WishlistHistoryType.withdraw
          : WishlistHistoryType.deposit,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wishlist_id': wishlistId,
      'wishlist_title': wishlistTitle,
      'type': type == WishlistHistoryType.withdraw ? 'withdraw' : 'deposit',
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory WishlistHistoryModel.fromEntity(WishlistHistoryEntity entity) {
    return WishlistHistoryModel(
      id: entity.id,
      wishlistId: entity.wishlistId,
      wishlistTitle: entity.wishlistTitle,
      type: entity.type,
      amount: entity.amount,
      date: entity.date,
      notes: entity.notes,
    );
  }
}
