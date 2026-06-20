import '../../domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.name,
    required super.initialBalance,
    required super.iconCode,
    required super.colorHex,
    super.inviteCode,
    super.ownerId,
    super.isShared = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_balance': initialBalance,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'invite_code': inviteCode,
      'owner_id': ownerId,
      'is_shared': isShared ? 1 : 0,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
      iconCode: map['icon_code'] ?? 0,
      colorHex: map['color_hex'] ?? '#007AFF',
      inviteCode: map['invite_code'],
      ownerId: map['owner_id'],
      isShared: (map['is_shared'] ?? 0) == 1,
    );
  }

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      name: entity.name,
      initialBalance: entity.initialBalance,
      iconCode: entity.iconCode,
      colorHex: entity.colorHex,
      inviteCode: entity.inviteCode,
      ownerId: entity.ownerId,
      isShared: entity.isShared,
    );
  }
}
