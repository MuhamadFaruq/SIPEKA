import 'package:sipeka/core/database/database_helper.dart';
import '../models/wallet_model.dart';

abstract class WalletLocalDataSource {
  Future<List<WalletModel>> getWallets();
  Future<void> insertWallet(WalletModel wallet);
  Future<void> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String id);
  Future<void> clearWallets();
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  final DatabaseHelper dbHelper;

  WalletLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<WalletModel>> getWallets() async {
    final maps = await dbHelper.getAllWallets();
    return maps.map((map) => WalletModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertWallet(WalletModel wallet) async {
    await dbHelper.insertWallet(wallet.toMap());
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    await dbHelper.updateWallet(wallet.id, wallet.toMap());
  }

  @override
  Future<void> deleteWallet(String id) async {
    await dbHelper.deleteWallet(id);
  }

  @override
  Future<void> clearWallets() async {
    await dbHelper.clearWalletTable();
  }
}
