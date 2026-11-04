import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/add_transaction_sheet.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state_view.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final institutionController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final maskedAccountController = TextEditingController();
    AccountType selectedType = AccountType.savingsAccount;
    Color selectedColor = AppColors.accountPalette.first;

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
                    const Text('Create New Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Account Name', hintText: 'e.g. Daily Savings, BOC Salary'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AccountType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Account Type'),
                      items: AccountType.values.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.displayName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: institutionController,
                      decoration: const InputDecoration(labelText: 'Institution / Bank', hintText: 'e.g. Commercial Bank, Cash'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: 'Rs. ',
                        labelText: 'Opening Balance (LKR)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maskedAccountController,
                      decoration: const InputDecoration(labelText: 'Masked Number (Optional)', hintText: 'e.g. •••• 1234'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Account Color Badge', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppColors.accountPalette.map((color) {
                        final isChosen = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 16,
                            child: isChosen ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final institution = institutionController.text.trim();
                        final balCents = CurrencyFormatter.parseToCents(balanceController.text) ?? 0;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter an account name')),
                          );
                          return;
                        }

                        await ref.read(accountRepositoryProvider).createAccount(
                          name: name,
                          type: selectedType.name,
                          institutionName: institution.isEmpty ? name : institution,
                          currency: AppConstants.defaultCurrencyCode,
                          openingBalanceCents: balCents,
                          openingDate: DateTime.now(),
                          colorValue: selectedColor.toARGB32(),
                          iconCode: selectedType == AccountType.cashWallet ? 'account_balance_wallet' : 'account_balance',
                          maskedAccountNumber: maskedAccountController.text.trim().isEmpty ? null : maskedAccountController.text.trim(),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Create Account'),
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

  void _showReconcileDialog(BuildContext context, WidgetRef ref, Account account) {
    final balanceController = TextEditingController(
      text: CurrencyFormatter.centsToDouble(account.currentBalance).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reconcile ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the actual verified balance from your physical cash count or bank statement.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: 'Rs. ',
                labelText: 'Actual Balance',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCents = CurrencyFormatter.parseToCents(balanceController.text);
              if (newCents != null) {
                await ref.read(accountRepositoryProvider).reconcileBalance(account.id, newCents);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Reconciliation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Account',
            onPressed: () => _showAddAccountDialog(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Accounts Configured',
              description: 'Create a cash wallet or bank account to begin tracking your finances.',
              actionLabel: 'Add Account',
              onAction: () => _showAddAccountDialog(context, ref),
            );
          }

          int totalLiquid = 0;
          for (final a in accounts) {
            if (a.type != AccountType.creditCard.name) {
              totalLiquid += a.currentBalance;
            }
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Liquid Total Banner
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Combined Balance', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            isVisible ? CurrencyFormatter.formatCents(totalLiquid) : '••••••••',
                            style: AppTypography.amountStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          AddTransactionSheet.show(context, initialType: TransactionType.transfer);
                        },
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Transfer'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Accounts List
              ...accounts.map((acc) {
                final isLiability = acc.type == AccountType.creditCard.name;
                final badgeColor = Color(acc.colorValue);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                CategoryIcon.getIcon(acc.iconCode),
                                color: badgeColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.name,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    acc.institutionName,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isVisible ? CurrencyFormatter.formatCents(acc.currentBalance) : '••••',
                                  style: AppTypography.amountStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isLiability ? AppColors.expense : null,
                                  ),
                                ),
                                if (acc.maskedAccountNumber != null)
                                  Text(
                                    acc.maskedAccountNumber!,
                                    style: theme.textTheme.labelSmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showReconcileDialog(context, ref, acc),
                              icon: const Icon(Icons.tune, size: 16),
                              label: const Text('Reconcile'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                AddTransactionSheet.show(
                                  context,
                                  initialType: TransactionType.expense,
                                  defaultAccountId: acc.id,
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Expense'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
