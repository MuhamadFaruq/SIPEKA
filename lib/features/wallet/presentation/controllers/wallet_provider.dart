import 'package:flutter/material.dart';
import 'package:sipeka/core/database/database_helper.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/usecases/add_wallet.dart';
import '../../domain/usecases/delete_wallet.dart';
import '../../domain/usecases/get_wallets.dart';
import '../../domain/usecases/update_wallet.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../data/datasources/wallet_local_datasource.dart';

class WalletProvider with ChangeNotifier {
  final GetWalletsUseCase getWalletsUseCase;
  final AddWalletUseCase addWalletUseCase;
  final UpdateWalletUseCase updateWalletUseCase;
  final DeleteWalletUseCase deleteWalletUseCase;

  List<WalletEntity> _wallets = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<WalletEntity> get wallets => _wallets;

  WalletProvider({
    GetWalletsUseCase? getWalletsUseCase,
    AddWalletUseCase? addWalletUseCase,
    UpdateWalletUseCase? updateWalletUseCase,
    DeleteWalletUseCase? deleteWalletUseCase,
  })  : getWalletsUseCase = getWalletsUseCase ??
            GetWalletsUseCase(
              WalletRepositoryImpl(
                localDataSource: WalletLocalDataSourceImpl(DatabaseHelper.instance),
              ),
            ),
        addWalletUseCase = addWalletUseCase ??
            AddWalletUseCase(
              WalletRepositoryImpl(
                localDataSource: WalletLocalDataSourceImpl(DatabaseHelper.instance),
              ),
            ),
        updateWalletUseCase = updateWalletUseCase ??
            UpdateWalletUseCase(
              WalletRepositoryImpl(
                localDataSource: WalletLocalDataSourceImpl(DatabaseHelper.instance),
              ),
            ),
        deleteWalletUseCase = deleteWalletUseCase ??
            DeleteWalletUseCase(
              WalletRepositoryImpl(
                localDataSource: WalletLocalDataSourceImpl(DatabaseHelper.instance),
              ),
            );

  Future<void> fetchAndSetWallets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final dataList = await getWalletsUseCase();
      _wallets = List<WalletEntity>.from(dataList);
    } catch (e) {
      debugPrint("Error fetching wallets: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWallets() async {
    await fetchAndSetWallets();
  }

  Future<bool> addWallet(WalletEntity wallet) async {
    // Optimistic update
    _wallets = [..._wallets, wallet];
    notifyListeners();

    try {
      final success = await addWalletUseCase(wallet);
      if (!success) {
        _wallets = _wallets.where((w) => w.id != wallet.id).toList();
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _wallets = _wallets.where((w) => w.id != wallet.id).toList();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWallet(WalletEntity wallet) async {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index == -1) return false;

    final oldWallet = _wallets[index];
    final updatedList = List<WalletEntity>.from(_wallets);
    updatedList[index] = wallet;
    _wallets = updatedList;
    notifyListeners();

    try {
      final success = await updateWalletUseCase(wallet);
      if (!success) {
        final rollbackList = List<WalletEntity>.from(_wallets);
        final rollbackIndex = rollbackList.indexWhere((w) => w.id == wallet.id);
        if (rollbackIndex != -1) {
          rollbackList[rollbackIndex] = oldWallet;
          _wallets = rollbackList;
          notifyListeners();
        }
        return false;
      }
      return true;
    } catch (e) {
      final rollbackList = List<WalletEntity>.from(_wallets);
      final rollbackIndex = rollbackList.indexWhere((w) => w.id == wallet.id);
      if (rollbackIndex != -1) {
        rollbackList[rollbackIndex] = oldWallet;
        _wallets = rollbackList;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> deleteWallet(String id) async {
    final index = _wallets.indexWhere((w) => w.id == id);
    if (index == -1) return false;

    final oldWallet = _wallets[index];
    _wallets = _wallets.where((w) => w.id != id).toList();
    notifyListeners();

    try {
      final success = await deleteWalletUseCase(id);
      if (!success) {
        final rollbackList = List<WalletEntity>.from(_wallets);
        if (index <= rollbackList.length) {
          rollbackList.insert(index, oldWallet);
        } else {
          rollbackList.add(oldWallet);
        }
        _wallets = rollbackList;
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      final rollbackList = List<WalletEntity>.from(_wallets);
      if (index <= rollbackList.length) {
        rollbackList.insert(index, oldWallet);
      } else {
        rollbackList.add(oldWallet);
      }
      _wallets = rollbackList;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearAllData() async {
    _wallets = [];
    notifyListeners();
    await DatabaseHelper.instance.clearWalletTable();
  }
}
