import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../core/database/app_database.dart';
import '../../../core/domain/enums.dart';

@injectable
class TransactionsDataSource {
  final AppDatabase _db;

  TransactionsDataSource(this._db);

  Stream<List<TypedResult>> watchTransactionsWithRelations() {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
      leftOuterJoin(_db.accounts, _db.accounts.id.equalsExp(_db.transactions.accountId)),
    ]);
    query.orderBy([OrderingTerm.desc(_db.transactions.date)]);
    return query.watch();
  }

  Future<List<TypedResult>> getTransactionsWithRelations() {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
      leftOuterJoin(_db.accounts, _db.accounts.id.equalsExp(_db.transactions.accountId)),
    ]);
    query.orderBy([OrderingTerm.desc(_db.transactions.date)]);
    return query.get();
  }

  Future<int> addTransaction({
    required double amount,
    required TransactionType type,
    required int categoryId,
    required int accountId,
    String? note,
    required DateTime date,
  }) {
    return _db.into(_db.transactions).insert(TransactionsCompanion.insert(
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      note: Value(note),
      date: date,
    ));
  }

  Future<bool> updateTransaction({
    required int id,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required int accountId,
    String? note,
    required DateTime date,
  }) {
    return _db.update(_db.transactions).replace(Transaction(
      id: id,
      amount: amount,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
      date: date,
    ));
  }

  Future<int> deleteTransaction(int id) {
    return (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }
}
