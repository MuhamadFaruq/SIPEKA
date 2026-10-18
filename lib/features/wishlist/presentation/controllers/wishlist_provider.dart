import 'package:flutter/material.dart';

import '../../domain/entities/wishlist_entity.dart';
import '../../domain/entities/wishlist_history_entity.dart';
import '../../domain/usecases/add_wishlist.dart';
import '../../domain/usecases/add_savings.dart';
import '../../domain/usecases/delete_wishlist.dart';
import '../../domain/usecases/get_wishlist.dart';
import '../../domain/usecases/get_wishlist_history.dart';
import '../../data/repositories/wishlist_repository_impl.dart';

class WishlistProvider with ChangeNotifier {
  final GetWishlistUseCase getWishlistUseCase;
  final AddWishlistUseCase addWishlistUseCase;
  final AddSavingsUseCase addSavingsUseCase;
  final DeleteWishlistUseCase deleteWishlistUseCase;
  final GetWishlistHistoryUseCase getWishlistHistoryUseCase;

  List<WishlistEntity> _items = [];

  List<WishlistEntity> get items => _items;

  double get totalSaved => _items.fold(0, (sum, item) => sum + item.savedAmount);
  double get totalTarget => _items.fold(0, (sum, item) => sum + item.targetAmount);

  WishlistProvider({
    GetWishlistUseCase? getWishlistUseCase,
    AddWishlistUseCase? addWishlistUseCase,
    AddSavingsUseCase? addSavingsUseCase,
    DeleteWishlistUseCase? deleteWishlistUseCase,
    GetWishlistHistoryUseCase? getWishlistHistoryUseCase,
  })  : getWishlistUseCase = getWishlistUseCase ??
            GetWishlistUseCase(WishlistRepositoryImpl()),
        addWishlistUseCase = addWishlistUseCase ??
            AddWishlistUseCase(WishlistRepositoryImpl()),
        addSavingsUseCase = addSavingsUseCase ??
            AddSavingsUseCase(WishlistRepositoryImpl()),
        deleteWishlistUseCase = deleteWishlistUseCase ??
            DeleteWishlistUseCase(WishlistRepositoryImpl()),
        getWishlistHistoryUseCase = getWishlistHistoryUseCase ??
            GetWishlistHistoryUseCase(WishlistRepositoryImpl());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAndSetWishlist() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final dataList = await getWishlistUseCase();
      _items = List<WishlistEntity>.from(dataList);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    } finally {
      _isLoading = false;
    }
  }

  Future<void> addWishlist(WishlistEntity item) async {
    try {
      await addWishlistUseCase(item);
      debugPrint("WISHLIST_PROVIDER: Berhasil simpan wishlist '${item.title}'");
      await fetchAndSetWishlist(); // Refresh untuk dapat ID yang diassign Firestore
    } catch (e) {
      debugPrint("WISHLIST_PROVIDER: ERROR simpan wishlist '${item.title}': $e");
      rethrow;
    }
  }

  Future<void> addSavings(String id, double amount, {String? note}) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      double oldAmount = _items[index].savedAmount;
      double newAmount = oldAmount + amount;
      _items[index].savedAmount = newAmount;
      notifyListeners();

      try {
        await addSavingsUseCase(id, amount, notes: note);
      } catch (e) {
        debugPrint("Error adding savings: $e");
        // Rollback memory jika gagal
        _items[index].savedAmount = oldAmount;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> withdrawSavings(String id, double amount, {String? note}) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      double oldAmount = _items[index].savedAmount;
      
      // Validasi: jumlah penarikan tidak boleh melebihi tabungan
      if (amount > oldAmount) {
        throw Exception("Jumlah penarikan melebihi tabungan yang terkumpul");
      }
      
      double newAmount = oldAmount - amount;
      _items[index].savedAmount = newAmount;
      notifyListeners();

      try {
        // Gunakan addSavings dengan nilai negatif untuk mengurangi
        await addSavingsUseCase(id, -amount, notes: note);
      } catch (e) {
        debugPrint("Error withdrawing savings: $e");
        // Rollback memory jika gagal
        _items[index].savedAmount = oldAmount;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<List<WishlistHistoryEntity>> getHistoryForWishlist(String wishlistId) async {
    return await getWishlistHistoryUseCase(wishlistId: wishlistId);
  }

  Future<List<WishlistHistoryEntity>> getAllHistory() async {
    return await getWishlistHistoryUseCase();
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
    await WishlistRepositoryImpl().dataSource.clearWishlists();
  }
}
