import '../../domain/entities/wishlist_entity.dart';
import '../../domain/entities/wishlist_history_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_firestore_datasource.dart';
import '../models/wishlist_model.dart';
import '../models/wishlist_history_model.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistDataSource dataSource;

  WishlistRepositoryImpl({
    WishlistDataSource? dataSource,
  }) : dataSource = dataSource ?? WishlistFirestoreDataSource();

  @override
  Future<List<WishlistEntity>> getWishlist() async {
    return await dataSource.getWishlist();
  }

  @override
  Future<void> addWishlist(WishlistEntity item) async {
    await dataSource.insertWishlist(WishlistModel.fromEntity(item));
  }

  @override
  Future<void> addSavings(String id, double amount, {String? notes}) async {
    final items = await dataSource.getWishlist();
    final matches = items.where((element) => element.id == id);
    if (matches.isEmpty) return;
    final item = matches.first;
    final newCollected = item.savedAmount + amount;
    await dataSource.updateSavings(id, newCollected);

    // Rekam riwayat mutasi
    final history = WishlistHistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      wishlistId: id,
      wishlistTitle: item.title,
      type: amount >= 0 ? WishlistHistoryType.deposit : WishlistHistoryType.withdraw,
      amount: amount.abs(),
      date: DateTime.now(),
      notes: notes,
    );
    await dataSource.insertWishlistHistory(history);
  }

  @override
  Future<void> deleteWishlist(String id) async {
    await dataSource.deleteWishlist(id);
  }

  @override
  Future<void> clearWishlists() async {
    await dataSource.clearWishlists();
  }

  @override
  Future<List<WishlistHistoryEntity>> getHistoryByWishlistId(String wishlistId) async {
    return await dataSource.getHistoryByWishlistId(wishlistId);
  }

  @override
  Future<List<WishlistHistoryEntity>> getAllWishlistHistory() async {
    return await dataSource.getAllWishlistHistory();
  }
}
