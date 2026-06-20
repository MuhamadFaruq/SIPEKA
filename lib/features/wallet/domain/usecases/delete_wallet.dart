import '../repositories/wallet_repository.dart';

class DeleteWalletUseCase {
  final WalletRepository repository;

  DeleteWalletUseCase(this.repository);

  Future<bool> call(String id) async {
    return await repository.deleteWallet(id);
  }
}
