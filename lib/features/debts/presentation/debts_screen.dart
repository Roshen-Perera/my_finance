import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../domain/debt_repository.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDebtDialog(BuildContext context, String initialType) {
    final titleController = TextEditingController();
    final personController = TextEditingController();
    final amountController = TextEditingController();
    final interestController = TextEditingController(text: '0');
    DateTime startDate = DateTime.now();
    DateTime? dueDate;
    String debtType = initialType;

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
                    Text(
                      debtType == 'lent' ? 'Record Money Lent (Asset)' : 'Record Loan Borrowed (Liability)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title / Purpose', hintText: 'e.g. Car Loan, Personal advance'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: personController,
                      decoration: InputDecoration(
                        labelText: debtType == 'lent' ? 'Borrower Name' : 'Lender / Institution Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. ', labelText: 'Principal Amount'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(suffixText: '%', labelText: 'Annual Interest Rate (Optional)'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(dueDate != null ? 'Due: ${DateFormatter.formatDate(dueDate!)}' : 'Set Due Date (Optional)'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final person = personController.text.trim();
                        final amountCents = CurrencyFormatter.parseToCents(amountController.text);
                        final interest = double.tryParse(interestController.text) ?? 0.0;

                        if (title.isEmpty || person.isEmpty || amountCents == null || amountCents <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please complete all required fields')),
                          );
                          return;
                        }

                        await ref.read(debtRepositoryProvider).createDebt(
                          title: title,
                          type: debtType,
                          counterpartyName: person,
                          principalAmountCents: amountCents,
                          interestRate: interest,
                          startDate: startDate,
                          dueDate: dueDate,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Record'),
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

  void _showRepayDialog(BuildContext context, DebtWithDetails item) {
    final principalController = TextEditingController(
      text: CurrencyFormatter.centsToDouble(item.debt.remainingAmount).toStringAsFixed(2),
    );
    final interestController = TextEditingController(text: '0');
    final accounts = ref.read(accountsStreamProvider).value ?? [];
    String? accountId = accounts.isNotEmpty ? accounts.first.id : null;

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
                    Text('Record Payment for ${item.debt.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: principalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. ', labelText: 'Principal Amount Paid'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixText: 'Rs. ', labelText: 'Interest Paid (Optional)'),
                    ),
                    const SizedBox(height: 12),
                    if (accounts.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: accountId,
                        decoration: InputDecoration(
                          labelText: item.debt.type == 'borrowed' ? 'Pay From Account' : 'Receive Into Account',
                        ),
                        items: accounts.map((a) {
                          return DropdownMenuItem(value: a.id, child: Text('${a.name} (${CurrencyFormatter.formatCents(a.currentBalance)})'));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => accountId = val),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final pCents = CurrencyFormatter.parseToCents(principalController.text) ?? 0;
                        final iCents = CurrencyFormatter.parseToCents(interestController.text) ?? 0;

                        if (pCents <= 0 && iCents <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter a payment amount')),
                          );
                          return;
                        }

                        await ref.read(debtRepositoryProvider).recordPayment(
                          debtId: item.debt.id,
                          principalAmountCents: pCents,
                          interestAmountCents: iCents,
                          accountId: accountId,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Record Payment'),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(debtsStreamProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts & Loans', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Borrowed (Payable)'),
            Tab(text: 'Lent (Receivable)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Debt/Loan',
            onPressed: () {
              final type = _tabController.index == 0 ? 'borrowed' : 'lent';
              _showAddDebtDialog(context, type);
            },
          ),
        ],
      ),
      body: debtsAsync.when(
        data: (allDebts) {
          final borrowed = allDebts.where((d) => d.debt.type == 'borrowed').toList();
          final lent = allDebts.where((d) => d.debt.type == 'lent').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDebtList(borrowed, 'borrowed', theme, isVisible),
              _buildDebtList(lent, 'lent', theme, isVisible),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDebtList(List<DebtWithDetails> list, String type, ThemeData theme, bool isVisible) {
    if (list.isEmpty) {
      return EmptyStateView(
        icon: Icons.account_balance_outlined,
        title: type == 'borrowed' ? 'No Borrowed Loans' : 'No Lent Records',
        description: type == 'borrowed'
            ? 'Track bank loans, family borrowings, or leases.'
            : 'Track money you have lent to others.',
        actionLabel: 'Add Record',
        onAction: () => _showAddDebtDialog(context, type),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final debt = item.debt;

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
                          Text(debt.title, style: theme.textTheme.titleMedium),
                          Text(
                            '${debt.type == 'borrowed' ? 'Lender' : 'Borrower'}: ${debt.counterpartyName}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isSettled
                            ? AppColors.income.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.isSettled ? 'SETTLED' : 'ACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.isSettled ? AppColors.income : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Remaining Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          isVisible ? CurrencyFormatter.formatCents(debt.remainingAmount) : '••••',
                          style: AppTypography.amountStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: debt.type == 'borrowed' ? AppColors.expense : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Principal Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          isVisible ? CurrencyFormatter.formatCents(debt.principalAmount) : '••••',
                          style: AppTypography.amountStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!item.isSettled) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (debt.dueDate != null)
                        Text(
                          'Due: ${DateFormatter.formatDate(debt.dueDate!)}',
                          style: theme.textTheme.labelSmall,
                        )
                      else
                        const SizedBox(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _showRepayDialog(context, item),
                        icon: const Icon(Icons.payments, size: 16),
                        label: const Text('Record Payment', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
