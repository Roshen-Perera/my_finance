import '../../../core/database/app_database.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchAllCategories({String? type});
  Stream<List<Category>> watchParentCategories({String? type});
  Stream<List<Category>> watchSubcategories(String parentId);
  Future<List<Category>> getAllCategories({String? type});
  Future<Category?> getCategoryById(String id);
  Future<void> addCategory({
    required String name,
    required String type,
    String? parentCategoryId,
    required String iconCode,
    required int colorValue,
  });
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
}
