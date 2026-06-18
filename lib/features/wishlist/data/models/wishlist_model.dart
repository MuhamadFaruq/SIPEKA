import '../../domain/entities/wishlist_entity.dart';

class WishlistModel extends WishlistEntity {
  WishlistModel({
    required super.id,
    required super.title,
    required super.targetAmount,
    required super.savedAmount,
  });

  // --- DATABASE MAPPING ---
  factory WishlistModel.fromMap(Map<String, dynamic> map) {
    return WishlistModel(
      id: map['id'].toString(),
      title: map['title'] as String,
      targetAmount: (map['target'] as num).toDouble(),
      savedAmount: (map['collected'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'target': targetAmount,
      'collected': savedAmount,
      'icon_code': 58419, // Default icon
    };
  }

  // --- JSON/CLOUD MAPPING ---
  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
    };
  }

  factory WishlistModel.fromEntity(WishlistEntity entity) {
    return WishlistModel(
      id: entity.id,
      title: entity.title,
      targetAmount: entity.targetAmount,
      savedAmount: entity.savedAmount,
    );
  }
}
