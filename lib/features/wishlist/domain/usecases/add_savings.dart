import '../repositories/wishlist_repository.dart';

class AddSavingsUseCase {
  final WishlistRepository repository;

  AddSavingsUseCase(this.repository);

  Future<void> call(String id, double amount) {
    return repository.addSavings(id, amount);
  }
}
