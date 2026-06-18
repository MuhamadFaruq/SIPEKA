import '../entities/wishlist_entity.dart';
import '../repositories/wishlist_repository.dart';

class AddWishlistUseCase {
  final WishlistRepository repository;

  AddWishlistUseCase(this.repository);

  Future<void> call(WishlistEntity item) {
    return repository.addWishlist(item);
  }
}
