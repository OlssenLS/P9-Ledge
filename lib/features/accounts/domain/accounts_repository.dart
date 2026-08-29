import 'account_entity.dart';
import '../../../core/domain/enums.dart';

abstract class AccountsRepository {
  Stream<List<AccountEntity>> watchAccountsWithBalance();
  Future<List<AccountEntity>> getAccounts();
  Future<int> addAccount(String name, AccountType type, double startingBalance);
  Future<bool> updateAccount(int id, String name, AccountType type, double startingBalance);
  Future<int> deleteAccount(int id);
}
