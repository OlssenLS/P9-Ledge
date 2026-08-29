import 'package:injectable/injectable.dart';
import '../domain/categories_repository.dart';
import '../domain/category_entity.dart';
import 'categories_data_source.dart';

@Injectable(as: CategoriesRepository)
class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesDataSource _dataSource;

  CategoriesRepositoryImpl(this._dataSource);

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return _dataSource.watchCategories().map(
      (list) => list.map((c) => CategoryEntity(
        id: c.id,
        name: c.name,
        icon: c.icon,
        color: c.color,
      )).toList(),
    );
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final list = await _dataSource.getCategories();
    return list.map((c) => CategoryEntity(
      id: c.id,
      name: c.name,
      icon: c.icon,
      color: c.color,
    )).toList();
  }

  @override
  Future<int> addCategory(String name, String icon, int color) {
    return _dataSource.addCategory(name, icon, color);
  }

  @override
  Future<bool> updateCategory(int id, String name, String icon, int color) {
    return _dataSource.updateCategory(id, name, icon, color);
  }

  @override
  Future<int> deleteCategory(int id) {
    return _dataSource.deleteCategory(id);
  }
}
