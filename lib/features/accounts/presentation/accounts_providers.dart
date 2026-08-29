import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/di/injection.dart';
import '../domain/accounts_repository.dart';
import '../domain/account_entity.dart';

part 'accounts_providers.g.dart';

@riverpod
AccountsRepository accountsRepository(AccountsRepositoryRef ref) {
  return getIt<AccountsRepository>();
}

@riverpod
Stream<List<AccountEntity>> watchAccounts(WatchAccountsRef ref) {
  return ref.watch(accountsRepositoryProvider).watchAccountsWithBalance();
}
