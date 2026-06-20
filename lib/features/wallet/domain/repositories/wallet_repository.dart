import '../entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<List<WalletEntity>> getWallets();
  Future<bool> addWallet(WalletEntity wallet);
  Future<bool> updateWallet(WalletEntity wallet);
  Future<bool> deleteWallet(String id);
  Future<void> clearWallets();
}
