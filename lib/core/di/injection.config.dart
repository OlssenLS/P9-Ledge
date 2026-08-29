// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/accounts/data/accounts_data_source.dart' as _i169;
import '../../features/accounts/data/accounts_repository_impl.dart' as _i196;
import '../../features/accounts/domain/accounts_repository.dart' as _i516;
import '../../features/categories/data/categories_data_source.dart' as _i645;
import '../../features/categories/data/categories_repository_impl.dart'
    as _i799;
import '../../features/categories/domain/categories_repository.dart' as _i61;
import '../../features/transactions/data/transactions_data_source.dart'
    as _i326;
import '../../features/transactions/data/transactions_repository_impl.dart'
    as _i42;
import '../../features/transactions/domain/transactions_repository.dart'
    as _i939;
import '../database/app_database.dart' as _i982;
import 'database_module.dart' as _i384;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final databaseModule = _$DatabaseModule();
  gh.singleton<_i982.AppDatabase>(() => databaseModule.appDatabase);
  gh.factory<_i169.AccountsDataSource>(
    () => _i169.AccountsDataSource(gh<_i982.AppDatabase>()),
  );
  gh.factory<_i645.CategoriesDataSource>(
    () => _i645.CategoriesDataSource(gh<_i982.AppDatabase>()),
  );
  gh.factory<_i326.TransactionsDataSource>(
    () => _i326.TransactionsDataSource(gh<_i982.AppDatabase>()),
  );
  gh.factory<_i939.TransactionsRepository>(
    () => _i42.TransactionsRepositoryImpl(
      gh<_i326.TransactionsDataSource>(),
      gh<_i982.AppDatabase>(),
    ),
  );
  gh.factory<_i61.CategoriesRepository>(
    () => _i799.CategoriesRepositoryImpl(gh<_i645.CategoriesDataSource>()),
  );
  gh.factory<_i516.AccountsRepository>(
    () => _i196.AccountsRepositoryImpl(gh<_i169.AccountsDataSource>()),
  );
  return getIt;
}

class _$DatabaseModule extends _i384.DatabaseModule {}
