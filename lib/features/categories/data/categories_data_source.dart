import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../core/database/app_database.dart';

@injectable
class CategoriesDataSource {
  final AppDatabase _db;

  CategoriesDataSource(this._db);

  Stream<List<Category>> watchCategories() {
    return _db.select(_db.categories).watch();
  }

  Future<List<Category>> getCategories() {
    return _db.select(_db.categories).get();
  }

  Future<int> addCategory(String name, String icon, int color) {
    return _db.into(_db.categories).insert(CategoriesCompanion.insert(
      name: name,
      icon: icon,
      color: color,
    ));
  }

  Future<bool> updateCategory(int id, String name, String icon, int color) {
    return _db.update(_db.categories).replace(Category(
      id: id,
      name: name,
      icon: icon,
      color: color,
    ));
  }

  Future<int> deleteCategory(int id) {
    return (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }
}
