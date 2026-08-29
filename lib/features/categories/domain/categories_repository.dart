import 'category_entity.dart';

abstract class CategoriesRepository {
  Stream<List<CategoryEntity>> watchCategories();
  Future<List<CategoryEntity>> getCategories();
  Future<int> addCategory(String name, String icon, int color);
  Future<bool> updateCategory(int id, String name, String icon, int color);
  Future<int> deleteCategory(int id);
}
