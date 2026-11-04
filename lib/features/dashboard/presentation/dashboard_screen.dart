import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/add_transaction_sheet.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../analytics/domain/analytics_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(financialOverviewProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);
    final insightsAsync = ref.watch(financialInsightsProvider);
    final recentTxAsync = ref.watch(recentTransactionsProvider);
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final savingsAsync = ref.watch(savingsGoalsStreamProvider);
    final recurringAsync = ref.watch(recurringStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            tooltip: isVisible ? 'Hide Balances' : 'Show Balances',
            onPressed: () {
              ref.read(isBalanceVisibleProvider.notifier).toggle();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(financialOverviewProvider);
              ref.invalidate(financialInsightsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financialOverviewProvider);
          ref.invalidate(financialInsightsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Month Selector Bar
            _buildMonthSelector(context, ref, selectedMonth),
            const SizedBox(height: 16),

            // Hero Net Worth & Liquid Available Money Card
            overviewAsync.when(
              data: (data) => _buildHeroOverviewCard(context, theme, data, isVisible),
              loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading overview: $err'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Monthly Inflows vs Outflows Cards
            overviewAsync.when(
              data: (data) => _buildMonthlyCashFlowGrid(theme, data, isVisible),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // Financial Insights Carousel/Banner (Rule-based)
            insightsAsync.when(
              data: (insights) {
                if (insights.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Financial Insights', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...insights.take(2).map((ins) => _buildInsightCard(theme, ins)),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),

            // Budget Utilization Section
            budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) return const SizedBox();
                final budget = budgets.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget Utilization', style: theme.textTheme.titleMedium),
                        TextButton(
                          onPressed: () => context.push('/budgets'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(budget.budget.name, style: theme.textTheme.titleSmall),
                                Text(
                                  '${budget.percentageConsumed.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: budget.isOverBudget
                                        ? AppColors.expense
                                        : (budget.isWarning ? AppColors.warning : AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (budget.percentageConsumed / 100).clamp(0.0, 1.0),
                              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                              color: budget.isOverBudget
                                  ? AppColors.expense
                                  : (budget.isWarning ? AppColors.warning : AppColors.primary),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spent: ${isVisible ? CurrencyFormatter.formatCents(budget.spentCents) : '••••'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  'Limit: ${isVisible ? CurrencyFormatter.formatCents(budget.budget.amount) : '••••'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),

            // Savings Goals Progress Preview
            savingsAsync.when(
              data: (goals) {
                if (goals.isEmpty) return const SizedBox();
                final goal = goals.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Savings Goal Progress', style: theme.textTheme.titleMedium),
                        TextButton(
                          onPressed: () => context.push('/savings'),
                          child: const Text('Manage'),
                        ),
                      ],
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(goal.goal.name, style: theme.textTheme.titleSmall),
                                Text(
                                  '${goal.progressPercentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.savings),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (goal.progressPercentage / 100).clamp(0.0, 1.0),
                              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                              color: AppColors.savings,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saved: ${isVisible ? CurrencyFormatter.formatCents(goal.goal.currentAmount) : '••••'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  'Target: ${isVisible ? CurrencyFormatter.formatCents(goal.goal.targetAmount) : '••••'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),

            // Upcoming Recurring Payments Section
            recurringAsync.when(
              data: (recurringList) {
                final upcoming = recurringList.where((r) => r.recurring.isActive).take(2).toList();
                if (upcoming.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Upcoming Commitments', style: theme.textTheme.titleMedium),
                        TextButton(
                          onPressed: () => context.push('/recurring'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    for (final item in upcoming)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.repeat, color: AppColors.warning, size: 20),
                          ),
                          title: Text(item.recurring.title, style: theme.textTheme.titleSmall),
                          subtitle: Text('Due: ${DateFormatter.formatDate(item.recurring.nextDueDate)}'),
                          trailing: Text(
                            isVisible ? CurrencyFormatter.formatCents(item.recurring.amount) : '••••',
                            style: AppTypography.amountStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),

            // Recent Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('See All'),
                ),
              ],
            ),
            recentTxAsync.when(
              data: (txList) {
                if (txList.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions Yet',
                    description: 'Start managing your finances by recording your first transaction.',
                    actionLabel: 'Add Expense',
                    onAction: () => AddTransactionSheet.show(context),
                  );
                }
                return Column(
                  children: txList.take(6).map((item) {
                    final tx = item.transaction;
                    final isExpense = tx.type == TransactionType.expense.name;
                    final isIncome = tx.type == TransactionType.income.name;

                    final color = isIncome
                        ? AppColors.income
                        : (isExpense ? AppColors.expense : AppColors.transfer);

                    final icon = item.category?.iconCode ??
                        (isIncome ? 'work' : (isExpense ? 'restaurant' : 'swap_horiz'));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CategoryIcon(
                          iconCode: icon,
                          colorValue: color.toARGB32(),
                        ),
                        title: Text(tx.description, style: theme.textTheme.titleSmall),
                        subtitle: Text(
                          '${DateFormatter.formatDate(tx.transactionDate)} • ${item.sourceAccount?.name ?? item.destinationAccount?.name ?? ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          isVisible
                              ? CurrencyFormatter.formatCents(
                                  tx.amount,
                                  showSign: true,
                                  isExpense: isExpense,
                                )
                              : '••••',
                          style: AppTypography.amountStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading transactions: $err'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).setMonth(
                    DateTime(selectedMonth.year, selectedMonth.month - 1, 1));
              },
            ),
            Text(
              DateFormatter.formatMonthYear(selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(selectedMonthProvider.notifier).setMonth(
                    DateTime(selectedMonth.year, selectedMonth.month + 1, 1));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroOverviewCard(
    BuildContext context,
    ThemeData theme,
    FinancialOverviewData data,
    bool isVisible,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVAILABLE LIQUID FUNDS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Rate: ${data.savingsRate.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isVisible ? CurrencyFormatter.formatCents(data.availableBalanceCents) : '••••••••',
            style: AppTypography.amountStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash in Hand',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVisible ? CurrencyFormatter.formatCents(data.cashInHandCents) : '••••',
                    style: AppTypography.amountStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Balances',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVisible ? CurrencyFormatter.formatCents(data.bankBalancesCents) : '••••',
                    style: AppTypography.amountStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Est. Net Worth',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVisible ? CurrencyFormatter.formatCents(data.estimatedNetWorthCents) : '••••',
                    style: AppTypography.amountStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCashFlowGrid(ThemeData theme, FinancialOverviewData data, bool isVisible) {
    return Row(
      children: [
        // Income
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_downward, color: AppColors.income, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('Income', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isVisible ? CurrencyFormatter.formatCents(data.totalIncomeMonthCents) : '••••',
                    style: AppTypography.amountStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Expenses
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_upward, color: AppColors.expense, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('Expenses', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isVisible ? CurrencyFormatter.formatCents(data.totalExpenseMonthCents) : '••••',
                    style: AppTypography.amountStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(ThemeData theme, FinancialInsight ins) {
    final color = switch (ins.type) {
      'positive' => AppColors.income,
      'warning' => AppColors.warning,
      'alert' => AppColors.expense,
      _ => theme.colorScheme.primary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(CategoryIcon.getIcon(ins.iconCode), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ins.title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ins.message,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
