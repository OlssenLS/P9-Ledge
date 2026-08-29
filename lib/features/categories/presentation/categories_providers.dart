import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/di/injection.dart';
import '../domain/categories_repository.dart';
import '../domain/category_entity.dart';

part 'categories_providers.g.dart';

@riverpod
CategoriesRepository categoriesRepository(CategoriesRepositoryRef ref) {
  return getIt<CategoriesRepository>();
}

@riverpod
Stream<List<CategoryEntity>> watchCategories(WatchCategoriesRef ref) {
  return ref.watch(categoriesRepositoryProvider).watchCategories();
}
