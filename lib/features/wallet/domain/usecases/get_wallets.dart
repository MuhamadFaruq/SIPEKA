import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletsUseCase {
  final WalletRepository repository;

  GetWalletsUseCase(this.repository);

  Future<List<WalletEntity>> call() async {
    return await repository.getWallets();
  }
}
