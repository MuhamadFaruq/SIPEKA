import '../repositories/wishlist_repository.dart';

class DeleteWishlistUseCase {
  final WishlistRepository repository;

  DeleteWishlistUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteWishlist(id);
  }
}
