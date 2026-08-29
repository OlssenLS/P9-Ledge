import 'package:injectable/injectable.dart';
import '../domain/accounts_repository.dart';
import '../domain/account_entity.dart';
import 'accounts_data_source.dart';
import '../../../core/domain/enums.dart';

@Injectable(as: AccountsRepository)
class AccountsRepositoryImpl implements AccountsRepository {
  final AccountsDataSource _dataSource;

  AccountsRepositoryImpl(this._dataSource);

  @override
  Stream<List<AccountEntity>> watchAccountsWithBalance() {
    return _dataSource.watchAccountsWithBalance();
  }

  @override
  Future<List<AccountEntity>> getAccounts() async {
    final accounts = await _dataSource.getAccounts();
    return accounts.map((a) => AccountEntity(
      id: a.id,
      name: a.name,
      type: a.type,
      startingBalance: a.startingBalance,
      currentBalance: a.startingBalance,
    )).toList();
  }

  @override
  Future<int> addAccount(String name, AccountType type, double startingBalance) {
    return _dataSource.addAccount(name, type, startingBalance);
  }

  @override
  Future<bool> updateAccount(int id, String name, AccountType type, double startingBalance) {
    return _dataSource.updateAccount(id, name, type, startingBalance);
  }

  @override
  Future<int> deleteAccount(int id) {
    return _dataSource.deleteAccount(id);
  }
}
