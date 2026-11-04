import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../constants/default_categories.dart';
import 'tables/schema_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Accounts,
  Categories,
  Transactions,
  LedgerEntries,
  Budgets,
  BudgetCategories,
  SavingsGoals,
  SavingsContributions,
  Debts,
  DebtPayments,
  RecurringTransactions,
  Attachments,
  Tags,
  TransactionTags,
  AppSettings,
  SyncMetadata,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // If categories are empty (e.g. fresh DB), seed them
      final categoryCount = await categories.count().getSingle();
      if (categoryCount == 0) {
        await _seedDefaultCategories();
      }
    },
  );

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now();

    await transaction(() async {
      // Income categories
      for (final item in DefaultCategories.incomeCategories) {
        await into(categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: item.id,
            name: item.name,
            type: item.type,
            iconCode: Value(item.iconCode),
            colorValue: Value(item.colorValue),
            isDefault: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      // Expense categories + subcategories
      for (final item in DefaultCategories.expenseCategories) {
        await into(categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: item.id,
            name: item.name,
            type: item.type,
            iconCode: Value(item.iconCode),
            colorValue: Value(item.colorValue),
            isDefault: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

        for (final sub in item.subcategories) {
          final subId = '${item.id}_${sub.toLowerCase().replaceAll(' ', '_')}';
          await into(categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: subId,
              name: sub,
              type: 'expense',
              parentCategoryId: Value(item.id),
              iconCode: Value(item.iconCode),
              colorValue: Value(item.colorValue),
              isDefault: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'my_finance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
