import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../domain/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CategoryRepositoryImpl(this._db);

  @override
  Stream<List<Category>> watchAllCategories({String? type}) {
    final query = _db.select(_db.categories);
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  @override
  Stream<List<Category>> watchParentCategories({String? type}) {
    final query = _db.select(_db.categories)..where((tbl) => tbl.parentCategoryId.isNull());
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  @override
  Stream<List<Category>> watchSubcategories(String parentId) {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.parentCategoryId.equals(parentId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  @override
  Future<List<Category>> getAllCategories({String? type}) {
    final query = _db.select(_db.categories);
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.get();
  }

  @override
  Future<Category?> getCategoryById(String id) {
    return (_db.select(_db.categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<void> addCategory({
    required String name,
    required String type,
    String? parentCategoryId,
    required String iconCode,
    required int colorValue,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        id: _uuid.v4(),
        name: name,
        type: type,
        parentCategoryId: Value(parentCategoryId),
        iconCode: Value(iconCode),
        colorValue: Value(colorValue),
        isDefault: const Value(false),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> updateCategory(Category category) async {
    final now = DateTime.now();
    await (_db.update(_db.categories)..where((tbl) => tbl.id.equals(category.id))).write(
      CategoriesCompanion(
        name: Value(category.name),
        iconCode: Value(category.iconCode),
        colorValue: Value(category.colorValue),
        parentCategoryId: Value(category.parentCategoryId),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    // Only delete non-default categories
    await (_db.delete(_db.categories)
          ..where((tbl) => tbl.id.equals(id) & tbl.isDefault.equals(false)))
        .go();
  }
}
