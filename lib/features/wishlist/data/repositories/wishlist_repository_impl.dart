import '../../domain/entities/wishlist_entity.dart';
import '../../domain/entities/wishlist_history_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_local_datasource.dart';
import '../datasources/wishlist_remote_datasource.dart';
import '../models/wishlist_model.dart';
import '../models/wishlist_history_model.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistLocalDataSource localDataSource;
  final WishlistRemoteDataSource remoteDataSource;

  WishlistRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<WishlistEntity>> getWishlist() async {
    return await localDataSource.getWishlist();
  }

  @override
  Future<void> addWishlist(WishlistEntity item) async {
    await localDataSource.insertWishlist(WishlistModel.fromEntity(item));
  }

  @override
  Future<void> addSavings(String id, double amount, {String? notes}) async {
    final items = await localDataSource.getWishlist();
    final matches = items.where((element) => element.id == id);
    if (matches.isEmpty) return;
    final item = matches.first;
    final newCollected = item.savedAmount + amount;
    await localDataSource.updateSavings(int.parse(id), newCollected);

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
    await localDataSource.insertWishlistHistory(history);
  }

  @override
  Future<void> deleteWishlist(String id) async {
    await localDataSource.deleteWishlist(int.parse(id));
  }

  @override
  Future<void> clearWishlists() async {
    await localDataSource.clearWishlists();
  }

  @override
  Future<List<WishlistHistoryEntity>> getHistoryByWishlistId(String wishlistId) async {
    return await localDataSource.getHistoryByWishlistId(wishlistId);
  }

  @override
  Future<List<WishlistHistoryEntity>> getAllWishlistHistory() async {
    return await localDataSource.getAllWishlistHistory();
  }
}
