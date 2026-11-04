import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/empty_state_view.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _showCreateBudgetDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: 'Monthly Budget');
    final amountController = TextEditingController(text: '50,000');
    int threshold = 80;
    String period = 'monthly';
    final categoriesAsync = ref.read(categoriesStreamProvider).value ?? [];
    final expenseCategories = categoriesAsync.where((c) => c.type == 'expense' && c.parentCategoryId == null).toList();
    final List<String> selectedCatIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Create New Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Budget Name', hintText: 'e.g. Food & Dining, Overall Monthly'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. ', labelText: 'Budget Limit (LKR)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: period,
                      decoration: const InputDecoration(labelText: 'Budget Period'),
                      items: const [
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => period = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Warning Alert Threshold: $threshold%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Slider(
                      value: threshold.toDouble(),
                      min: 50,
                      max: 100,
                      divisions: 10,
                      label: '$threshold%',
                      onChanged: (val) => setDialogState(() => threshold = val.round()),
                    ),
                    const SizedBox(height: 12),
                    const Text('Assign Categories (Optional, leave empty for all)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: expenseCategories.map((cat) {
                        final isSelected = selectedCatIds.contains(cat.id);
                        return FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedCatIds.add(cat.id);
                              } else {
                                selectedCatIds.remove(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final amountCents = CurrencyFormatter.parseToCents(amountController.text);
                        if (name.isEmpty || amountCents == null || amountCents <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter valid budget details')),
                          );
                          return;
                        }

                        final now = DateTime.now();
                        final range = period == 'weekly'
                            ? DateFormatter.getWeekRange(now)
                            : DateFormatter.getMonthRange(now);

                        await ref.read(budgetRepositoryProvider).createBudget(
                          name: name,
                          amountCents: amountCents,
                          period: period,
                          startDate: range.start,
                          endDate: range.end,
                          warningThresholdPercent: threshold,
                          rollover: false,
                          categoryIds: selectedCatIds,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Budget'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Limits', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Budget',
            onPressed: () => _showCreateBudgetDialog(context, ref),
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyStateView(
              icon: Icons.track_changes,
              title: 'No Budgets Configured',
              description: 'Create spending limits to keep your expenses under control.',
              actionLabel: 'Create Budget',
              onAction: () => _showCreateBudgetDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final item = budgets[index];
              final budget = item.budget;
              final pct = item.percentageConsumed;

              final Color statusColor;
              if (item.isOverBudget) {
                statusColor = AppColors.expense;
              } else if (item.isWarning) {
                statusColor = AppColors.warning;
              } else {
                statusColor = AppColors.primary;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(budget.name, style: theme.textTheme.titleMedium),
                                Text(
                                  '${budget.period.toUpperCase()} • ${DateFormatter.formatDate(budget.startDate)} - ${DateFormatter.formatDate(budget.endDate)}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                            onPressed: () async {
                              await ref.read(budgetRepositoryProvider).deleteBudget(budget.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Spent: ${isVisible ? CurrencyFormatter.formatCents(item.spentCents) : '••••'}',
                            style: AppTypography.amountStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(fontWeight: FontWeight.w700, color: statusColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                        color: statusColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining: ${isVisible ? CurrencyFormatter.formatCents(item.remainingCents) : '••••'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: item.remainingCents < 0 ? AppColors.expense : null,
                            ),
                          ),
                          Text(
                            'Limit: ${isVisible ? CurrencyFormatter.formatCents(budget.amount) : '••••'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
