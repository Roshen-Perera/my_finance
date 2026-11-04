import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/theme_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/security/security_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sync_service.dart';

import '../../features/accounts/data/account_repository_impl.dart';
import '../../features/accounts/domain/account_repository.dart';

import '../../features/categories/data/category_repository_impl.dart';
import '../../features/categories/domain/category_repository.dart';

import '../../features/transactions/data/transaction_repository_impl.dart';
import '../../features/transactions/domain/transaction_repository.dart';

import '../../features/budgets/data/budget_repository_impl.dart';
import '../../features/budgets/domain/budget_repository.dart';

import '../../features/savings_goals/data/savings_goal_repository_impl.dart';
import '../../features/savings_goals/domain/savings_goal_repository.dart';

import '../../features/debts/data/debt_repository_impl.dart';
import '../../features/debts/domain/debt_repository.dart';

import '../../features/recurring_transactions/data/recurring_repository_impl.dart';
import '../../features/recurring_transactions/domain/recurring_repository.dart';

import '../../features/analytics/data/analytics_repository.dart';
import '../../features/analytics/domain/analytics_models.dart';

import '../../features/reports/data/reports_repository.dart';

// --- Repositories & Services ---

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountRepositoryImpl(db);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepositoryImpl(db);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(db);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(db);
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SavingsGoalRepositoryImpl(db);
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DebtRepositoryImpl(db);
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);
  return RecurringRepositoryImpl(db, txRepo);
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AnalyticsRepository(db);
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ReportsRepository(db);
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SecurityService(prefs);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncService(db, prefs);
});

// --- State Streams & Futures ---

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAllAccounts();
});

final recentTransactionsProvider = StreamProvider<List<TransactionWithDetails>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactions(limit: 15);
});

final allTransactionsProvider = StreamProvider<List<TransactionWithDetails>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactions();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAllCategories();
});

final budgetsStreamProvider = StreamProvider<List<BudgetWithSpending>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watchBudgets();
});

final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoalWithDetails>>((ref) {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  return repo.watchGoals();
});

final debtsStreamProvider = StreamProvider<List<DebtWithDetails>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchDebts();
});

final recurringStreamProvider = StreamProvider<List<RecurringWithDetails>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watchRecurring();
});

// Selected Dashboard Reference Month
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setMonth(DateTime month) => state = month;
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

// Balance Visibility Toggle
class BalanceVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final isBalanceVisibleProvider = NotifierProvider<BalanceVisibleNotifier, bool>(BalanceVisibleNotifier.new);

// Financial Overview
final financialOverviewProvider = FutureProvider<FinancialOverviewData>((ref) async {
  final analyticsRepo = ref.watch(analyticsRepositoryProvider);
  final monthDate = ref.watch(selectedMonthProvider);
  // Re-run whenever accounts or transactions change
  ref.watch(accountsStreamProvider);
  ref.watch(recentTransactionsProvider);
  return analyticsRepo.getFinancialOverview(monthDate);
});

// Financial Insights
final financialInsightsProvider = FutureProvider<List<FinancialInsight>>((ref) async {
  final analyticsRepo = ref.watch(analyticsRepositoryProvider);
  final monthDate = ref.watch(selectedMonthProvider);
  ref.watch(recentTransactionsProvider);
  return analyticsRepo.generateInsights(monthDate);
});
