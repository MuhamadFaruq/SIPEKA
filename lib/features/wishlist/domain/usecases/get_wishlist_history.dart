import '../entities/wishlist_history_entity.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlistHistoryUseCase {
  final WishlistRepository repository;

  GetWishlistHistoryUseCase(this.repository);

  Future<List<WishlistHistoryEntity>> call({String? wishlistId}) {
    if (wishlistId != null) {
      return repository.getHistoryByWishlistId(wishlistId);
    }
    return repository.getAllWishlistHistory();
  }
}
