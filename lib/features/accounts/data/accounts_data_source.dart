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
             a.starting_balance 
             + COALESCE((SELECT SUM(CASE WHEN type = 0 THEN amount WHEN type = 2 THEN -amount ELSE -amount END) FROM transactions WHERE account_id = a.id), 0)
             + COALESCE((SELECT SUM(amount) FROM transactions WHERE type = 2 AND to_account_id = a.id), 0) AS current_balance
      FROM accounts a
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
