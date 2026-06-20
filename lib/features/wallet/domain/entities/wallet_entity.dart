class WalletEntity {
  final String id;
  final String name;
  final double initialBalance;
  final int iconCode;
  final String colorHex;
  final String? inviteCode;
  final String? ownerId;
  final bool isShared;

  const WalletEntity({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.iconCode,
    required this.colorHex,
    this.inviteCode,
    this.ownerId,
    this.isShared = false,
  });
}
