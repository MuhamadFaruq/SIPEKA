import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletLocalDataSource localDataSource;

  WalletRepositoryImpl({required this.localDataSource});

  @override
  Future<List<WalletEntity>> getWallets() async {
    return await localDataSource.getWallets();
  }

  @override
  Future<bool> addWallet(WalletEntity wallet) async {
    try {
      await localDataSource.insertWallet(WalletModel.fromEntity(wallet));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateWallet(WalletEntity wallet) async {
    try {
      await localDataSource.updateWallet(WalletModel.fromEntity(wallet));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteWallet(String id) async {
    try {
      await localDataSource.deleteWallet(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearWallets() async {
    await localDataSource.clearWallets();
  }
}
