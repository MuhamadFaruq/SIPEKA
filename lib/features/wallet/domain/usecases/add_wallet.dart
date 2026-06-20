import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class AddWalletUseCase {
  final WalletRepository repository;

  AddWalletUseCase(this.repository);

  Future<bool> call(WalletEntity wallet) async {
    return await repository.addWallet(wallet);
  }
}
