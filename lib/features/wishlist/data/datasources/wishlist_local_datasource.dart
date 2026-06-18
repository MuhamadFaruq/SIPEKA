import 'package:sipeka/core/database/database_helper.dart';
import '../models/wishlist_model.dart';

abstract class WishlistLocalDataSource {
  Future<List<WishlistModel>> getWishlist();
  Future<void> insertWishlist(WishlistModel item);
  Future<void> updateSavings(int id, double newAmount);
  Future<void> deleteWishlist(int id);
  Future<void> clearWishlists();
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
}
