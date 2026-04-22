import '../repositories/wallet_repository.dart';

class GetTransactionsStreamUseCase {
  final WalletRepository repository;

  GetTransactionsStreamUseCase(this.repository);

  Stream<List<dynamic>> call(String userId) {
    return repository.getTransactionsStream(userId);
  }
}
