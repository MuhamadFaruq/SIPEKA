import 'package:sipeka/core/database/database_helper.dart';
import '../models/wishlist_model.dart';
import '../models/wishlist_history_model.dart';

abstract class WishlistLocalDataSource {
  Future<List<WishlistModel>> getWishlist();
  Future<void> insertWishlist(WishlistModel item);
  Future<void> updateSavings(int id, double newAmount);
  Future<void> deleteWishlist(int id);
  Future<void> clearWishlists();
  Future<void> insertWishlistHistory(WishlistHistoryModel history);
  Future<List<WishlistHistoryModel>> getHistoryByWishlistId(String wishlistId);
  Future<List<WishlistHistoryModel>> getAllWishlistHistory();
}

class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  final DatabaseHelper dbHelper;

  WishlistLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<WishlistModel>> getWishlist() async {
    final maps = await dbHelper.getAllWishlist();
    return maps.map((map) => WishlistModel.fromMap(map)).toList();
  }

  @override
  Future<void> insertWishlist(WishlistModel item) async {
    await dbHelper.insertWishlist(item.toMap());
  }

  @override
  Future<void> updateSavings(int id, double newAmount) async {
    await dbHelper.updateWishlist(id, {
      'collected': newAmount,
    });
  }

  @override
  Future<void> deleteWishlist(int id) async {
    await dbHelper.deleteWishlist(id);
  }

  @override
  Future<void> clearWishlists() async {
    await dbHelper.clearWishlistTable();
  }

  @override
  Future<void> insertWishlistHistory(WishlistHistoryModel history) async {
    await dbHelper.insertWishlistHistory(history.toMap());
  }

  @override
  Future<List<WishlistHistoryModel>> getHistoryByWishlistId(String wishlistId) async {
    final maps = await dbHelper.getWishlistHistoryByWishlistId(wishlistId);
    return maps.map((map) => WishlistHistoryModel.fromMap(map)).toList();
  }

  @override
  Future<List<WishlistHistoryModel>> getAllWishlistHistory() async {
    final maps = await dbHelper.getAllWishlistHistory();
    return maps.map((map) => WishlistHistoryModel.fromMap(map)).toList();
  }
}
