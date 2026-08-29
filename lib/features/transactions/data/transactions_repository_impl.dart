import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../domain/transactions_repository.dart';
import '../domain/transaction_entity.dart';
import 'transactions_data_source.dart';
import '../../../core/domain/enums.dart';
import '../../categories/domain/category_entity.dart';
import '../../accounts/domain/account_entity.dart';
import '../../../core/database/app_database.dart';

@Injectable(as: TransactionsRepository)
class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsDataSource _dataSource;
  final AppDatabase _db;

  TransactionsRepositoryImpl(this._dataSource, this._db);

  TransactionEntity _mapResult(TypedResult row) {
    final t = row.readTable(_db.transactions);
    final c = row.readTableOrNull(_db.categories);
    final a = row.readTableOrNull(_db.accounts);

    return TransactionEntity(
      id: t.id,
      amount: t.amount,
      type: t.type,
      categoryId: t.categoryId,
      accountId: t.accountId,
      note: t.note,
      date: t.date,
      category: c != null ? CategoryEntity(
        id: c.id,
        name: c.name,
        icon: c.icon,
        color: c.color,
      ) : null,
      account: a != null ? AccountEntity(
        id: a.id,
        name: a.name,
        type: a.type,
        startingBalance: a.startingBalance,
        currentBalance: a.startingBalance, // UI doesn't need running balance for transaction list
      ) : null,
    );
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    return _dataSource.watchTransactionsWithRelations().map(
      (list) => list.map(_mapResult).toList(),
    );
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final list = await _dataSource.getTransactionsWithRelations();
    return list.map(_mapResult).toList();
  }

  @override
  Future<int> addTransaction({
    required double amount,
    required TransactionType type,
    required int categoryId,
    required int accountId,
    String? note,
    required DateTime date,
  }) {
    return _dataSource.addTransaction(
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
      date: date,
    );
  }

  @override
  Future<bool> updateTransaction({
    required int id,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required int accountId,
    String? note,
    required DateTime date,
  }) {
    return _dataSource.updateTransaction(
      id: id,
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
      date: date,
    );
  }

  @override
  Future<int> deleteTransaction(int id) {
    return _dataSource.deleteTransaction(id);
  }
}
