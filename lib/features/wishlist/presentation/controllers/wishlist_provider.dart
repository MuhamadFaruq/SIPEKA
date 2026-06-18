import 'package:flutter/material.dart';
import 'package:sipeka/core/database/database_helper.dart';
import 'package:sipeka/core/services/sync_service.dart';

import '../../domain/entities/wishlist_entity.dart';
import '../../domain/usecases/add_wishlist.dart';
import '../../domain/usecases/add_savings.dart';
import '../../domain/usecases/delete_wishlist.dart';
import '../../domain/usecases/get_wishlist.dart';
import '../../data/repositories/wishlist_repository_impl.dart';
import '../../data/datasources/wishlist_local_datasource.dart';
import '../../data/datasources/wishlist_remote_datasource.dart';

class WishlistProvider with ChangeNotifier {
  final GetWishlistUseCase getWishlistUseCase;
  final AddWishlistUseCase addWishlistUseCase;
  final AddSavingsUseCase addSavingsUseCase;
  final DeleteWishlistUseCase deleteWishlistUseCase;

  List<WishlistEntity> _items = [];

  List<WishlistEntity> get items => _items;

  double get totalSaved => _items.fold(0, (sum, item) => sum + item.savedAmount);
  double get totalTarget => _items.fold(0, (sum, item) => sum + item.targetAmount);

  WishlistProvider({
    GetWishlistUseCase? getWishlistUseCase,
    AddWishlistUseCase? addWishlistUseCase,
    AddSavingsUseCase? addSavingsUseCase,
    DeleteWishlistUseCase? deleteWishlistUseCase,
  })  : getWishlistUseCase = getWishlistUseCase ??
            GetWishlistUseCase(
              WishlistRepositoryImpl(
                localDataSource: WishlistLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: WishlistRemoteDataSourceImpl(SyncService()),
              ),
            ),
        addWishlistUseCase = addWishlistUseCase ??
            AddWishlistUseCase(
              WishlistRepositoryImpl(
                localDataSource: WishlistLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: WishlistRemoteDataSourceImpl(SyncService()),
              ),
            ),
        addSavingsUseCase = addSavingsUseCase ??
            AddSavingsUseCase(
              WishlistRepositoryImpl(
                localDataSource: WishlistLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: WishlistRemoteDataSourceImpl(SyncService()),
              ),
            ),
        deleteWishlistUseCase = deleteWishlistUseCase ??
            DeleteWishlistUseCase(
              WishlistRepositoryImpl(
                localDataSource: WishlistLocalDataSourceImpl(DatabaseHelper.instance),
                remoteDataSource: WishlistRemoteDataSourceImpl(SyncService()),
              ),
            );

  Future<void> fetchAndSetWishlist() async {
    try {
      final dataList = await getWishlistUseCase();
      _items = dataList;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    }
  }

  Future<void> addWishlist(WishlistEntity item) async {
    try {
      await addWishlistUseCase(item);
      await fetchAndSetWishlist();
    } catch (e) {
      debugPrint("Error adding wishlist: $e");
    }
  }

  Future<void> addSavings(String id, double amount) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      double newAmount = _items[index].savedAmount + amount;
      _items[index].savedAmount = newAmount;
      notifyListeners();

      try {
        await addSavingsUseCase(id, amount);
      } catch (e) {
        debugPrint("Error adding savings: $e");
      }
    }
  }

  Future<void> deleteWishlist(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();

    try {
      await deleteWishlistUseCase(id);
    } catch (e) {
      debugPrint("Error deleting wishlist: $e");
    }
  }

  Future<void> clearAllData() async {
    _items = [];
    notifyListeners();
    await DatabaseHelper.instance.clearWishlistTable();
  }
}
