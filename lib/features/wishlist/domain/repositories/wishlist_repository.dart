import '../entities/wishlist_entity.dart';
import '../entities/wishlist_history_entity.dart';

abstract class WishlistRepository {
  Future<List<WishlistEntity>> getWishlist();
  Future<void> addWishlist(WishlistEntity item);
  Future<void> addSavings(String id, double amount, {String? notes});
  Future<void> deleteWishlist(String id);
  Future<void> clearWishlists();
  Future<List<WishlistHistoryEntity>> getHistoryByWishlistId(String wishlistId);
  Future<List<WishlistHistoryEntity>> getAllWishlistHistory();
}
