import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  BudgetRepositoryImpl(this._db);

  @override
  Stream<List<BudgetWithSpending>> watchBudgets() {
    return _db.select(_db.budgets).watch().asyncMap((budgetList) async {
      final List<BudgetWithSpending> result = [];

      for (final budget in budgetList) {
        // Fetch categories linked to this budget
        final budgetCatRows = await (_db.select(_db.budgetCategories)..where((tbl) => tbl.budgetId.equals(budget.id))).get();
        final catIds = budgetCatRows.map((e) => e.categoryId).toList();

        final List<Category> categories = [];
        if (catIds.isNotEmpty) {
          final cats = await (_db.select(_db.categories)..where((tbl) => tbl.id.isIn(catIds))).get();
          categories.addAll(cats);
        }

        // Calculate spent amount in this budget period
        final query = _db.select(_db.transactions)
          ..where((tbl) =>
              tbl.type.equals(TransactionType.expense.name) &
              tbl.status.equals('completed') &
              tbl.transactionDate.isBiggerOrEqualValue(budget.startDate) &
              tbl.transactionDate.isSmallerOrEqualValue(budget.endDate));

        if (catIds.isNotEmpty) {
          query.where((tbl) => tbl.categoryId.isIn(catIds) | tbl.subcategoryId.isIn(catIds));
        }

        final txRows = await query.get();
        int spent = 0;
        for (final tx in txRows) {
          spent += tx.amount;
        }

        result.add(BudgetWithSpending(
          budget: budget,
          categories: categories,
          spentCents: spent,
        ));
      }

      return result;
    });
  }

  @override
  Future<void> createBudget({
    required String name,
    required int amountCents,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required int warningThresholdPercent,
    required bool rollover,
    required List<String> categoryIds,
  }) async {
    final budgetId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.budgets).insert(
        BudgetsCompanion.insert(
          id: budgetId,
          name: name,
          amount: amountCents,
          period: Value(period),
          startDate: startDate,
          endDate: endDate,
          warningThresholdPercent: Value(warningThresholdPercent),
          rollover: Value(rollover),
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (final catId in categoryIds) {
        await _db.into(_db.budgetCategories).insert(
          BudgetCategoriesCompanion.insert(
            id: _uuid.v4(),
            budgetId: budgetId,
            categoryId: catId,
          ),
        );
      }
    });
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.budgetCategories)..where((tbl) => tbl.budgetId.equals(id))).go();
      await (_db.delete(_db.budgets)..where((tbl) => tbl.id.equals(id))).go();
    });
  }
}
