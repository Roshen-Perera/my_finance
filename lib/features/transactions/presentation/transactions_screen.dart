import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/add_transaction_sheet.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../domain/transaction_repository.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, expense, income, transfer

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTransactionDetails(BuildContext context, TransactionWithDetails item) {
    final theme = Theme.of(context);
    final tx = item.transaction;
    final isExpense = tx.type == TransactionType.expense.name;
    final isIncome = tx.type == TransactionType.income.name;
    final color = isIncome ? AppColors.income : (isExpense ? AppColors.expense : AppColors.transfer);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    tx.type.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    CurrencyFormatter.formatCents(tx.amount, showSign: true, isExpense: isExpense),
                    style: AppTypography.amountStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildDetailRow('Description', tx.description),
                _buildDetailRow('Date', DateFormatter.formatFullDate(tx.transactionDate)),
                if (item.category != null)
                  _buildDetailRow('Category', item.category!.name),
                if (item.subcategory != null)
                  _buildDetailRow('Subcategory', item.subcategory!.name),
                if (item.sourceAccount != null)
                  _buildDetailRow('From Account', item.sourceAccount!.name),
                if (item.destinationAccount != null)
                  _buildDetailRow('To Account', item.destinationAccount!.name),
                if (tx.feeAmount > 0)
                  _buildDetailRow('Fee Paid', CurrencyFormatter.formatCents(tx.feeAmount)),
                if (tx.notes != null && tx.notes!.isNotEmpty)
                  _buildDetailRow('Notes', tx.notes!),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Transaction?'),
                        content: const Text(
                          'This will safely reverse this transaction and recalculate the affected account balances.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete & Reverse'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction reversed successfully')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                  label: const Text('Delete & Reverse Transaction', style: TextStyle(color: AppColors.expense)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTxAsync = ref.watch(allTransactionsProvider);
    final isVisible = ref.watch(isBalanceVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Transaction',
            onPressed: () => AddTransactionSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by description or notes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Expenses', 'expense'),
                const SizedBox(width: 8),
                _buildFilterChip('Income', 'income'),
                const SizedBox(width: 8),
                _buildFilterChip('Transfers', 'transfer'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transactions List
          Expanded(
            child: allTxAsync.when(
              data: (txList) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = txList.where((item) {
                  final tx = item.transaction;
                  if (_selectedFilter != 'all' && tx.type != _selectedFilter) {
                    return false;
                  }
                  if (query.isNotEmpty) {
                    final descMatch = tx.description.toLowerCase().contains(query);
                    final noteMatch = tx.notes?.toLowerCase().contains(query) ?? false;
                    final catMatch = item.category?.name.toLowerCase().contains(query) ?? false;
                    if (!descMatch && !noteMatch && !catMatch) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions Found',
                    description: query.isNotEmpty
                        ? 'No transactions matched your search query.'
                        : 'Record an income or expense to see it here.',
                    actionLabel: query.isEmpty ? 'Record Transaction' : null,
                    onAction: () => AddTransactionSheet.show(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showTransactionDetails(context, item),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CategoryIcon(
                                iconCode: icon,
                                colorValue: color.toARGB32(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description,
                                      style: theme.textTheme.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormatter.formatDate(tx.transactionDate)} • ${item.sourceAccount?.name ?? item.destinationAccount?.name ?? ''}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                isVisible
                                    ? CurrencyFormatter.formatCents(
                                        tx.amount,
                                        showSign: true,
                                        isExpense: isExpense,
                                      )
                                    : '••••',
                                style: AppTypography.amountStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
    );
  }
}
