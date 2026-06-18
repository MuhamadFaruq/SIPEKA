import '../../domain/entities/wishlist_entity.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_local_datasource.dart';
import '../datasources/wishlist_remote_datasource.dart';
import '../models/wishlist_model.dart';

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
  Future<void> addSavings(String id, double amount) async {
    final items = await localDataSource.getWishlist();
    final item = items.firstWhere((element) => element.id == id);
    final newCollected = item.savedAmount + amount;
    await localDataSource.updateSavings(int.parse(id), newCollected);
  }

  @override
  Future<void> deleteWishlist(String id) async {
    await localDataSource.deleteWishlist(int.parse(id));
  }

  @override
  Future<void> clearWishlists() async {
    await localDataSource.clearWishlists();
  }
}
