import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class UpdateWalletUseCase {
  final WalletRepository repository;

  UpdateWalletUseCase(this.repository);

  Future<bool> call(WalletEntity wallet) async {
    return await repository.updateWallet(wallet);
  }
}
