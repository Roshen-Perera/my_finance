import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/empty_state_view.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  void _showAddRecurringDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType type = TransactionType.expense;
    RecurrenceFrequency freq = RecurrenceFrequency.monthly;
    DateTime nextDueDate = DateTime.now().add(const Duration(days: 30));
    bool isAuto = false;

    final accounts = ref.read(accountsStreamProvider).value ?? [];
    String? accountId = accounts.isNotEmpty ? accounts.first.id : null;
    final categories = ref.read(categoriesStreamProvider).value ?? [];
    final filteredCategories = categories.where((c) => c.type == 'expense' && c.parentCategoryId == null).toList();
    String? categoryId = filteredCategories.isNotEmpty ? filteredCategories.first.id : null;

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
                    const Text('New Recurring Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Netflix, Rent, Internet Bill'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. ', labelText: 'Amount'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RecurrenceFrequency>(
                      initialValue: freq,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: RecurrenceFrequency.values.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f.displayName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => freq = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (accounts.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: accountId,
                        decoration: const InputDecoration(labelText: 'Account'),
                        items: accounts.map((a) {
                          return DropdownMenuItem(value: a.id, child: Text(a.name));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => accountId = val),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: nextDueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => nextDueDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event, size: 16),
                      label: Text('Next Due: ${DateFormatter.formatDate(nextDueDate)}'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Auto-create transaction on due date'),
                      subtitle: const Text('If off, sends a reminder to confirm manually'),
                      value: isAuto,
                      onChanged: (val) => setDialogState(() => isAuto = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final amountCents = CurrencyFormatter.parseToCents(amountController.text);
                        if (title.isEmpty || amountCents == null || amountCents <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please complete all required fields')),
                          );
                          return;
                        }

                        await ref.read(recurringRepositoryProvider).createRecurring(
                          title: title,
                          type: type.name,
                          amountCents: amountCents,
                          sourceAccountId: accountId,
                          categoryId: categoryId,
                          frequency: freq.name,
                          startDate: DateTime.now(),
                          nextDueDate: nextDueDate,
                          isAutoGenerated: isAuto,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Recurring Schedule'),
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
    final recurringAsync = ref.watch(recurringStreamProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Activities', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Process Due Now',
            onPressed: () async {
              await ref.read(recurringRepositoryProvider).processDueRecurring();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Due recurring transactions processed')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Schedule',
            onPressed: () => _showAddRecurringDialog(context, ref),
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return EmptyStateView(
              icon: Icons.repeat,
              title: 'No Recurring Schedules',
              description: 'Schedule your monthly salary, utilities, subscriptions, or rent.',
              actionLabel: 'Add Recurring',
              onAction: () => _showAddRecurringDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final rec = item.recurring;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (rec.isActive ? AppColors.primary : Colors.grey).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.repeat,
                          color: rec.isActive ? AppColors.primary : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec.title, style: theme.textTheme.titleMedium),
                            Text(
                              '${rec.frequency.toUpperCase()} • Due: ${DateFormatter.formatDate(rec.nextDueDate)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (rec.isAutoGenerated)
                              const Text('Auto-generates transaction', style: TextStyle(color: Colors.teal, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isVisible ? CurrencyFormatter.formatCents(rec.amount) : '••••',
                            style: AppTypography.amountStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Switch(
                            value: rec.isActive,
                            onChanged: (val) {
                              ref.read(recurringRepositoryProvider).toggleActive(rec.id, val);
                            },
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
