import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../core/database/app_database.dart';
import '../../../core/domain/enums.dart';
import '../domain/account_entity.dart';

@injectable
class AccountsDataSource {
  final AppDatabase _db;

  AccountsDataSource(this._db);

  Stream<List<Account>> watchAccounts() {
    return _db.select(_db.accounts).watch();
  }

  Future<List<Account>> getAccounts() {
    return _db.select(_db.accounts).get();
  }

  Future<int> addAccount(String name, AccountType type, double startingBalance) {
    return _db.into(_db.accounts).insert(AccountsCompanion.insert(
      name: name,
      type: type,
      startingBalance: startingBalance,
    ));
  }

  Future<bool> updateAccount(int id, String name, AccountType type, double startingBalance) {
    return _db.update(_db.accounts).replace(Account(
      id: id,
      name: name,
      type: type,
      startingBalance: startingBalance,
    ));
  }

  Future<int> deleteAccount(int id) {
    return (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
  }
  
  Stream<List<AccountEntity>> watchAccountsWithBalance() {
    final query = _db.customSelect(
      '''
      SELECT a.id, a.name, a.type, a.starting_balance,
             a.starting_balance + COALESCE(SUM(CASE WHEN t.type = 0 THEN t.amount ELSE -t.amount END), 0) AS current_balance
      FROM accounts a
      LEFT JOIN transactions t ON t.account_id = a.id
      GROUP BY a.id
      ''',
      readsFrom: {
        _db.accounts,
        _db.transactions,
      },
    );

    return query.watch().map((rows) {
      return rows.map((row) {
        return AccountEntity(
          id: row.read<int>('id'),
          name: row.read<String>('name'),
          type: AccountType.values[row.read<int>('type')],
          startingBalance: row.read<double>('starting_balance'),
          currentBalance: row.read<double>('current_balance'),
        );
      }).toList();
    });
  }
}
