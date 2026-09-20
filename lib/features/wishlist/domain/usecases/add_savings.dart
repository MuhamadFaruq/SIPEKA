import '../repositories/wishlist_repository.dart';

class AddSavingsUseCase {
  final WishlistRepository repository;

  AddSavingsUseCase(this.repository);

  Future<void> call(String id, double amount, {String? notes}) {
    return repository.addSavings(id, amount, notes: notes);
  }
}
