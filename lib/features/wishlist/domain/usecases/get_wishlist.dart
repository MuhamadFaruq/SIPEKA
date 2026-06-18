import '../entities/wishlist_entity.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlistUseCase {
  final WishlistRepository repository;

  GetWishlistUseCase(this.repository);

  Future<List<WishlistEntity>> call() {
    return repository.getWishlist();
  }
}
