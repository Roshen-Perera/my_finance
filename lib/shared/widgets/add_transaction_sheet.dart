import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../providers/app_providers.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final String? defaultAccountId;

  const AddTransactionSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.defaultAccountId,
  });

  static Future<void> show(BuildContext context, {TransactionType initialType = TransactionType.expense, String? defaultAccountId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddTransactionSheet(
        initialType: initialType,
        defaultAccountId: defaultAccountId,
      ),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSourceAccountId;
  String? _selectedDestAccountId;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = switch (widget.initialType) {
      TransactionType.expense => 0,
      TransactionType.income => 1,
      TransactionType.transfer => 2,
      _ => 0,
    };
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategoryId = null;
          _selectedSubcategoryId = null;
        });
      }
    });
    _selectedSourceAccountId = widget.defaultAccountId;
    _selectedDestAccountId = widget.defaultAccountId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TransactionType get _currentType {
    switch (_tabController.index) {
      case 0:
        return TransactionType.expense;
      case 1:
        return TransactionType.income;
      case 2:
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  Future<void> _submit() async {
    final amountCents = CurrencyFormatter.parseToCents(_amountController.text);
    if (amountCents == null || amountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    final desc = _descriptionController.text.trim().isEmpty
        ? _currentType.displayName
        : _descriptionController.text.trim();

    setState(() => _isLoading = true);
    final txRepo = ref.read(transactionRepositoryProvider);

    try {
      if (_currentType == TransactionType.expense) {
        if (_selectedSourceAccountId == null) {
          throw 'Please select a payment account';
        }
        if (_selectedCategoryId == null) {
          throw 'Please select an expense category';
        }

        await txRepo.createExpense(
          amountCents: amountCents,
          sourceAccountId: _selectedSourceAccountId!,
          categoryId: _selectedCategoryId!,
          subcategoryId: _selectedSubcategoryId,
          transactionDate: _selectedDate,
          description: desc,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else if (_currentType == TransactionType.income) {
        if (_selectedDestAccountId == null) {
          throw 'Please select a destination account';
        }
        if (_selectedCategoryId == null) {
          throw 'Please select an income category';
        }

        await txRepo.createIncome(
          amountCents: amountCents,
          destinationAccountId: _selectedDestAccountId!,
          categoryId: _selectedCategoryId!,
          transactionDate: _selectedDate,
          description: desc,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else if (_currentType == TransactionType.transfer) {
        if (_selectedSourceAccountId == null || _selectedDestAccountId == null) {
          throw 'Please select both source and destination accounts';
        }
        if (_selectedSourceAccountId == _selectedDestAccountId) {
          throw 'Source and destination accounts must be different';
        }

        final feeCents = CurrencyFormatter.parseToCents(_feeController.text) ?? 0;

        await txRepo.createTransfer(
          amountCents: amountCents,
          sourceAccountId: _selectedSourceAccountId!,
          destinationAccountId: _selectedDestAccountId!,
          feeCents: feeCents,
          transactionDate: _selectedDate,
          description: desc,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentType.displayName} recorded successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                  Tab(text: 'Transfer'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
              decoration: const InputDecoration(
                prefixText: 'Rs. ',
                hintText: '0.00',
                labelText: 'Amount (LKR)',
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection (For Income & Expense)
            if (_currentType != TransactionType.transfer) ...[
              categoriesAsync.when(
                data: (categories) {
                  final filtered = categories
                      .where((c) =>
                          c.type == (_currentType == TransactionType.expense ? 'expense' : 'income') &&
                          c.parentCategoryId == null)
                      .toList();

                  if (filtered.isNotEmpty && _selectedCategoryId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedCategoryId == null) {
                        setState(() => _selectedCategoryId = filtered.first.id);
                      }
                    });
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: filtered.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                        _selectedSubcategoryId = null;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox(),
              ),
              const SizedBox(height: 16),
            ],

            // Accounts Selection
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text('No accounts available. Create an account first.');
                }

                if (_selectedSourceAccountId == null && accounts.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedSourceAccountId == null) {
                      setState(() {
                        _selectedSourceAccountId = accounts.first.id;
                        if (accounts.length > 1) {
                          _selectedDestAccountId = accounts[1].id;
                        } else {
                          _selectedDestAccountId = accounts.first.id;
                        }
                      });
                    }
                  });
                }

                if (_currentType == TransactionType.expense) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedSourceAccountId,
                    decoration: const InputDecoration(labelText: 'Paid From Account'),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text('${acc.name} (${CurrencyFormatter.formatCents(acc.currentBalance)})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSourceAccountId = val),
                  );
                } else if (_currentType == TransactionType.income) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedDestAccountId,
                    decoration: const InputDecoration(labelText: 'Deposit To Account'),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc.id,
                        child: Text('${acc.name} (${CurrencyFormatter.formatCents(acc.currentBalance)})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDestAccountId = val),
                  );
                } else {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSourceAccountId,
                        decoration: const InputDecoration(labelText: 'From Account'),
                        items: accounts.map((acc) {
                          return DropdownMenuItem<String>(
                            value: acc.id,
                            child: Text('${acc.name} (${CurrencyFormatter.formatCents(acc.currentBalance)})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSourceAccountId = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDestAccountId,
                        decoration: const InputDecoration(labelText: 'To Account'),
                        items: accounts.map((acc) {
                          return DropdownMenuItem<String>(
                            value: acc.id,
                            child: Text('${acc.name} (${CurrencyFormatter.formatCents(acc.currentBalance)})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDestAccountId = val),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _feeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          prefixText: 'Rs. ',
                          hintText: '0.00',
                          labelText: 'Transfer Fee (Optional)',
                        ),
                      ),
                    ],
                  );
                }
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Date Picker Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormatter.formatDate(_selectedDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description / Payee',
                hintText: 'e.g. Keells Super, Salary, Fuel',
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Additional details or memo...',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save ${_currentType.displayName}'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
