import 'transaction_entity.dart';
import '../../../core/domain/enums.dart';

abstract class TransactionsRepository {
  Stream<List<TransactionEntity>> watchTransactions();
  Future<List<TransactionEntity>> getTransactions();
  Future<int> addTransaction({
    required double amount,
    required TransactionType type,
    required int categoryId,
    required int accountId,
    String? note,
    required DateTime date,
  });
  Future<bool> updateTransaction({
    required int id,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required int accountId,
    String? note,
    required DateTime date,
  });
  Future<int> deleteTransaction(int id);
}
