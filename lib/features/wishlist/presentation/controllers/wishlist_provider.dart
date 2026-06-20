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
      _items = List<WishlistEntity>.from(dataList);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    }
  }

  Future<void> addWishlist(WishlistEntity item) async {
    try {
      await addWishlistUseCase(item);
      debugPrint("WISHLIST_PROVIDER: Berhasil simpan wishlist '${item.title}'");
      await fetchAndSetWishlist(); // Refresh untuk dapat ID yang diassign DB
    } catch (e) {
      debugPrint("WISHLIST_PROVIDER: ERROR simpan wishlist '${item.title}': $e");
      rethrow;
    }
  }

  Future<void> addSavings(String id, double amount) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      double oldAmount = _items[index].savedAmount;
      double newAmount = oldAmount + amount;
      _items[index].savedAmount = newAmount;
      notifyListeners();

      try {
        await addSavingsUseCase(id, amount);
      } catch (e) {
        debugPrint("Error adding savings: $e");
        // Rollback memory jika gagal
        _items[index].savedAmount = oldAmount;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> deleteWishlist(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldItem = _items[index];
      _items.removeAt(index);
      notifyListeners();

      try {
        await deleteWishlistUseCase(id);
      } catch (e) {
        debugPrint("Error deleting wishlist: $e");
        // Rollback memory jika gagal
        _items.insert(index, oldItem);
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> clearAllData() async {
    _items = [];
    notifyListeners();
    await DatabaseHelper.instance.clearWishlistTable();
  }
}
