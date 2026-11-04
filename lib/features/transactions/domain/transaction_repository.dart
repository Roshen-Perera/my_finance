import '../../../core/database/app_database.dart';

class TransactionWithDetails {
  final Transaction transaction;
  final Account? sourceAccount;
  final Account? destinationAccount;
  final Category? category;
  final Category? subcategory;

  TransactionWithDetails({
    required this.transaction,
    this.sourceAccount,
    this.destinationAccount,
    this.category,
    this.subcategory,
  });
}

abstract class TransactionRepository {
  Stream<List<TransactionWithDetails>> watchTransactions({
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  Future<List<TransactionWithDetails>> getTransactions({
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  Future<TransactionWithDetails?> getTransactionById(String id);

  Future<void> createIncome({
    required int amountCents,
    required String destinationAccountId,
    required String categoryId,
    required DateTime transactionDate,
    required String description,
    String? notes,
    bool isRecurring = false,
  });

  Future<void> createExpense({
    required int amountCents,
    required String sourceAccountId,
    required String categoryId,
    String? subcategoryId,
    required DateTime transactionDate,
    required String description,
    String? notes,
    bool isRecurring = false,
  });

  Future<void> createTransfer({
    required int amountCents,
    required String sourceAccountId,
    required String destinationAccountId,
    int feeCents = 0,
    required DateTime transactionDate,
    required String description,
    String? notes,
  });

  Future<void> deleteTransaction(String id);
}
