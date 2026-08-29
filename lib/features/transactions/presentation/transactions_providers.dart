import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/di/injection.dart';
import '../domain/transactions_repository.dart';
import '../domain/transaction_entity.dart';

part 'transactions_providers.g.dart';

@riverpod
TransactionsRepository transactionsRepository(Ref ref) {
  return getIt<TransactionsRepository>();
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

@riverpod
Stream<List<TransactionEntity>> watchTransactions(Ref ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final stream = ref.watch(transactionsRepositoryProvider).watchTransactions();
  
  if (query.isEmpty) return stream;
  
  return stream.map((list) {
    return list.where((t) {
      final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
      final categoryMatch = t.category?.name.toLowerCase().contains(query) ?? false;
      final accountMatch = t.account?.name.toLowerCase().contains(query) ?? false;
      return noteMatch || categoryMatch || accountMatch;
    }).toList();
  });
}
