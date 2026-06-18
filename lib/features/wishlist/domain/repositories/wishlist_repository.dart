import '../entities/wishlist_entity.dart';

abstract class WishlistRepository {
  Future<List<WishlistEntity>> getWishlist();
  Future<void> addWishlist(WishlistEntity item);
  Future<void> addSavings(String id, double amount);
  Future<void> deleteWishlist(String id);
  Future<void> clearWishlists();
}
