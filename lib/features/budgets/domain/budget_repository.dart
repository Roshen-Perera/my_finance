import '../../../core/database/app_database.dart';

class BudgetWithSpending {
  final Budget budget;
  final List<Category> categories;
  final int spentCents;

  BudgetWithSpending({
    required this.budget,
    required this.categories,
    required this.spentCents,
  });

  int get remainingCents => budget.amount - spentCents;
  double get percentageConsumed => budget.amount > 0 ? (spentCents / budget.amount) * 100 : 0.0;
  bool get isOverBudget => spentCents > budget.amount;
  bool get isWarning => percentageConsumed >= budget.warningThresholdPercent;
}

abstract class BudgetRepository {
  Stream<List<BudgetWithSpending>> watchBudgets();
  Future<void> createBudget({
    required String name,
    required int amountCents,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required int warningThresholdPercent,
    required bool rollover,
    required List<String> categoryIds,
  });
  Future<void> deleteBudget(String id);
}
