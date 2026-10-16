import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_firestore_datasource.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletDataSource dataSource;

  WalletRepositoryImpl({
    WalletDataSource? dataSource,
  }) : dataSource = dataSource ?? WalletFirestoreDataSource();

  @override
  Future<List<WalletEntity>> getWallets() async {
    return await dataSource.getWallets();
  }

  @override
  Future<bool> addWallet(WalletEntity wallet) async {
    try {
      await dataSource.insertWallet(WalletModel.fromEntity(wallet));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateWallet(WalletEntity wallet) async {
    try {
      await dataSource.updateWallet(WalletModel.fromEntity(wallet));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteWallet(String id) async {
    try {
      await dataSource.deleteWallet(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearWallets() async {
    await dataSource.clearWallets();
  }
}
