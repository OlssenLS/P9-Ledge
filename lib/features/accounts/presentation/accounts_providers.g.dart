// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountsRepository)
final accountsRepositoryProvider = AccountsRepositoryProvider._();

final class AccountsRepositoryProvider
    extends
        $FunctionalProvider<
          AccountsRepository,
          AccountsRepository,
          AccountsRepository
        >
    with $Provider<AccountsRepository> {
  AccountsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountsRepository create(Ref ref) {
    return accountsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountsRepository>(value),
    );
  }
}

String _$accountsRepositoryHash() =>
    r'052a60e9d28b45f2388ed2cfb5849240f9a2649d';

@ProviderFor(watchAccounts)
final watchAccountsProvider = WatchAccountsProvider._();

final class WatchAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AccountEntity>>,
          List<AccountEntity>,
          Stream<List<AccountEntity>>
        >
    with
        $FutureModifier<List<AccountEntity>>,
        $StreamProvider<List<AccountEntity>> {
  WatchAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchAccountsHash();

  @$internal
  @override
  $StreamProviderElement<List<AccountEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AccountEntity>> create(Ref ref) {
    return watchAccounts(ref);
  }
}

String _$watchAccountsHash() => r'53188dd8805e207cba8862945553202b60af70fd';
