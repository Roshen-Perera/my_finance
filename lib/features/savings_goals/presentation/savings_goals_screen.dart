import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/financial_calculator.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../domain/savings_goal_repository.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetAmountController = TextEditingController(text: '100,000');
    DateTime targetDate = DateTime.now().add(const Duration(days: 180));
    String? selectedLinkedAccountId;
    final accounts = ref.read(accountsStreamProvider).value ?? [];

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
                    const Text('Create Savings Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Goal Name', hintText: 'e.g. Emergency Fund, Laptop, Vacation'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. ', labelText: 'Target Amount (LKR)'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: targetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() => targetDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('Target Date: ${DateFormatter.formatDate(targetDate)}'),
                    ),
                    const SizedBox(height: 12),
                    if (accounts.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedLinkedAccountId,
                        decoration: const InputDecoration(labelText: 'Linked Account (Optional)'),
                        items: accounts.map((a) {
                          return DropdownMenuItem(value: a.id, child: Text(a.name));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedLinkedAccountId = val),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final targetCents = CurrencyFormatter.parseToCents(targetAmountController.text);
                        if (name.isEmpty || targetCents == null || targetCents <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter valid goal details')),
                          );
                          return;
                        }

                        final monthlyTarget = FinancialCalculator.calculateMonthlyGoalContribution(
                          targetAmountCents: targetCents,
                          currentAmountCents: 0,
                          targetDate: targetDate,
                        );

                        await ref.read(savingsGoalRepositoryProvider).createGoal(
                          name: name,
                          targetAmountCents: targetCents,
                          targetDate: targetDate,
                          monthlyContributionTargetCents: monthlyTarget,
                          linkedAccountId: selectedLinkedAccountId,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Goal'),
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

  void _showAddContributionDialog(BuildContext context, WidgetRef ref, SavingsGoalWithDetails item) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? sourceAccId;
    final accounts = ref.read(accountsStreamProvider).value ?? [];

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
                    Text('Add Contribution to ${item.goal.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. ', labelText: 'Contribution Amount'),
                    ),
                    const SizedBox(height: 12),
                    if (accounts.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: sourceAccId,
                        decoration: const InputDecoration(labelText: 'Deduct From Account (Optional)'),
                        items: accounts.map((a) {
                          return DropdownMenuItem(value: a.id, child: Text('${a.name} (${CurrencyFormatter.formatCents(a.currentBalance)})'));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => sourceAccId = val),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final amountCents = CurrencyFormatter.parseToCents(amountController.text);
                        if (amountCents == null || amountCents <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount')),
                          );
                          return;
                        }

                        await ref.read(savingsGoalRepositoryProvider).addContribution(
                          goalId: item.goal.id,
                          amountCents: amountCents,
                          sourceAccountId: sourceAccId,
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Add Contribution'),
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
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Goal',
            onPressed: () => _showCreateGoalDialog(context, ref),
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyStateView(
              icon: Icons.savings_outlined,
              title: 'No Savings Goals',
              description: 'Create a savings target to prepare for emergencies or future purchases.',
              actionLabel: 'Create Goal',
              onAction: () => _showCreateGoalDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final item = goals[index];
              final goal = item.goal;
              final pct = item.progressPercentage;

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
                                Text(goal.name, style: theme.textTheme.titleMedium),
                                Text(
                                  'Target: ${DateFormatter.formatDate(goal.targetDate)} • Monthly Need: ${CurrencyFormatter.formatCents(goal.monthlyContributionTarget)}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                            onPressed: () async {
                              await ref.read(savingsGoalRepositoryProvider).deleteGoal(goal.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved: ${isVisible ? CurrencyFormatter.formatCents(goal.currentAmount) : '••••'}',
                            style: AppTypography.amountStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.savings),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                        color: AppColors.savings,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining: ${isVisible ? CurrencyFormatter.formatCents(item.remainingCents) : '••••'}',
                            style: theme.textTheme.bodySmall,
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _showAddContributionDialog(context, ref, item),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Contribute', style: TextStyle(fontSize: 12)),
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
