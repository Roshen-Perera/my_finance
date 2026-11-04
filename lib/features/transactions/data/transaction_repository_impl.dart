import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TransactionRepositoryImpl(this._db);

  @override
  Stream<List<TransactionWithDetails>> watchTransactions({
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    final query = _buildTransactionsQuery(
      accountId: accountId,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );

    return query.watch().asyncMap((rows) async {
      final List<TransactionWithDetails> result = [];
      for (final tx in rows) {
        Account? sourceAcc;
        Account? destAcc;
        Category? cat;
        Category? subcat;

        if (tx.sourceAccountId != null) {
          sourceAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.sourceAccountId!))).getSingleOrNull();
        }
        if (tx.destinationAccountId != null) {
          destAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.destinationAccountId!))).getSingleOrNull();
        }
        if (tx.categoryId != null) {
          cat = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(tx.categoryId!))).getSingleOrNull();
        }
        if (tx.subcategoryId != null) {
          subcat = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(tx.subcategoryId!))).getSingleOrNull();
        }

        result.add(TransactionWithDetails(
          transaction: tx,
          sourceAccount: sourceAcc,
          destinationAccount: destAcc,
          category: cat,
          subcategory: subcat,
        ));
      }
      return result;
    });
  }

  @override
  Future<List<TransactionWithDetails>> getTransactions({
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final query = _buildTransactionsQuery(
      accountId: accountId,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );

    final rows = await query.get();
    final List<TransactionWithDetails> result = [];
    for (final tx in rows) {
      Account? sourceAcc;
      Account? destAcc;
      Category? cat;
      Category? subcat;

      if (tx.sourceAccountId != null) {
        sourceAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.sourceAccountId!))).getSingleOrNull();
      }
      if (tx.destinationAccountId != null) {
        destAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.destinationAccountId!))).getSingleOrNull();
      }
      if (tx.categoryId != null) {
        cat = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(tx.categoryId!))).getSingleOrNull();
      }
      if (tx.subcategoryId != null) {
        subcat = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(tx.subcategoryId!))).getSingleOrNull();
      }

      result.add(TransactionWithDetails(
        transaction: tx,
        sourceAccount: sourceAcc,
        destinationAccount: destAcc,
        category: cat,
        subcategory: subcat,
      ));
    }
    return result;
  }

  SimpleSelectStatement<$TransactionsTable, Transaction> _buildTransactionsQuery({
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) {
    final query = _db.select(_db.transactions)
      ..where((tbl) => tbl.status.equals('completed'));

    if (accountId != null) {
      query.where((tbl) => tbl.sourceAccountId.equals(accountId) | tbl.destinationAccountId.equals(accountId));
    }
    if (categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(categoryId) | tbl.subcategoryId.equals(categoryId));
    }
    if (startDate != null) {
      query.where((tbl) => tbl.transactionDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.transactionDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(tbl) => OrderingTerm.desc(tbl.transactionDate)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query;
  }

  @override
  Future<TransactionWithDetails?> getTransactionById(String id) async {
    final tx = await (_db.select(_db.transactions)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (tx == null) return null;

    Account? sourceAcc;
    Account? destAcc;
    Category? cat;
    Category? subcat;

    if (tx.sourceAccountId != null) {
      sourceAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.sourceAccountId!))).getSingleOrNull();
    }
    if (tx.destinationAccountId != null) {
      destAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.destinationAccountId!))).getSingleOrNull();
    }
    if (tx.categoryId != null) {
      cat = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(tx.categoryId!))).getSingleOrNull();
    }
    if (tx.subcategoryId != null) {
      subcat = await (_db.select(_db.categories)..where((tbl) => tbl.id.equals(tx.subcategoryId!))).getSingleOrNull();
    }

    return TransactionWithDetails(
      transaction: tx,
      sourceAccount: sourceAcc,
      destinationAccount: destAcc,
      category: cat,
      subcategory: subcat,
    );
  }

  @override
  Future<void> createIncome({
    required int amountCents,
    required String destinationAccountId,
    required String categoryId,
    required DateTime transactionDate,
    required String description,
    String? notes,
    bool isRecurring = false,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final now = DateTime.now();
    final txId = _uuid.v4();

    await _db.transaction(() async {
      // 1. Insert Transaction
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          id: txId,
          type: TransactionType.income.name,
          amount: amountCents,
          destinationAccountId: Value(destinationAccountId),
          categoryId: Value(categoryId),
          transactionDate: transactionDate,
          description: description,
          notes: Value(notes),
          isRecurring: Value(isRecurring),
          status: const Value('completed'),
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('pending'),
        ),
      );

      // 2. Ledger Entries (Double-Entry)
      // Debit Receiving Account
      await _db.into(_db.ledgerEntries).insert(
        LedgerEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          accountId: Value(destinationAccountId),
          categoryOrEntityId: Value(categoryId),
          entryType: 'debit',
          amount: amountCents,
          entryDate: transactionDate,
          description: 'Income to account: $description',
          createdAt: now,
        ),
      );
      // Credit Income Category
      await _db.into(_db.ledgerEntries).insert(
        LedgerEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          categoryOrEntityId: Value(categoryId),
          entryType: 'credit',
          amount: amountCents,
          entryDate: transactionDate,
          description: 'Income category credit: $description',
          createdAt: now,
        ),
      );

      // 3. Update Account Balance
      final account = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(destinationAccountId))).getSingle();
      await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(destinationAccountId))).write(
        AccountsCompanion(
          currentBalance: Value(account.currentBalance + amountCents),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> createExpense({
    required int amountCents,
    required String sourceAccountId,
    required String categoryId,
    String? subcategoryId,
    required DateTime transactionDate,
    required String description,
    String? notes,
    bool isRecurring = false,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    final now = DateTime.now();
    final txId = _uuid.v4();

    await _db.transaction(() async {
      // 1. Insert Transaction
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          id: txId,
          type: TransactionType.expense.name,
          amount: amountCents,
          sourceAccountId: Value(sourceAccountId),
          categoryId: Value(categoryId),
          subcategoryId: Value(subcategoryId),
          transactionDate: transactionDate,
          description: description,
          notes: Value(notes),
          isRecurring: Value(isRecurring),
          status: const Value('completed'),
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('pending'),
        ),
      );

      // 2. Ledger Entries (Double-Entry)
      // Credit Paying Account
      await _db.into(_db.ledgerEntries).insert(
        LedgerEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          accountId: Value(sourceAccountId),
          categoryOrEntityId: Value(subcategoryId ?? categoryId),
          entryType: 'credit',
          amount: amountCents,
          entryDate: transactionDate,
          description: 'Expense payment: $description',
          createdAt: now,
        ),
      );
      // Debit Expense Category
      await _db.into(_db.ledgerEntries).insert(
        LedgerEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          categoryOrEntityId: Value(subcategoryId ?? categoryId),
          entryType: 'debit',
          amount: amountCents,
          entryDate: transactionDate,
          description: 'Expense category debit: $description',
          createdAt: now,
        ),
      );

      // 3. Update Account Balance
      final account = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(sourceAccountId))).getSingle();
      await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(sourceAccountId))).write(
        AccountsCompanion(
          currentBalance: Value(account.currentBalance - amountCents),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> createTransfer({
    required int amountCents,
    required String sourceAccountId,
    required String destinationAccountId,
    int feeCents = 0,
    required DateTime transactionDate,
    required String description,
    String? notes,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (sourceAccountId == destinationAccountId) {
      throw ArgumentError('Source and destination accounts must be different');
    }

    final now = DateTime.now();
    final txId = _uuid.v4();

    await _db.transaction(() async {
      // 1. Insert Transaction
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          id: txId,
          type: TransactionType.transfer.name,
          amount: amountCents,
          sourceAccountId: Value(sourceAccountId),
          destinationAccountId: Value(destinationAccountId),
          feeAmount: Value(feeCents),
          transactionDate: transactionDate,
          description: description,
          notes: Value(notes),
          status: const Value('completed'),
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('pending'),
        ),
      );

      // 2. Ledger Entries (Double-Entry)
      // Credit Source Account (Outflow)
      await _db.into(_db.ledgerEntries).insert(
        LedgerEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          accountId: Value(sourceAccountId),
          categoryOrEntityId: Value(destinationAccountId),
          entryType: 'credit',
          amount: amountCents,
          entryDate: transactionDate,
          description: 'Transfer out: $description',
          createdAt: now,
        ),
      );
      // Debit Destination Account (Inflow)
      await _db.into(_db.ledgerEntries).insert(
        LedgerEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          accountId: Value(destinationAccountId),
          categoryOrEntityId: Value(sourceAccountId),
          entryType: 'debit',
          amount: amountCents,
          entryDate: transactionDate,
          description: 'Transfer in: $description',
          createdAt: now,
        ),
      );

      // Optional Fee
      if (feeCents > 0) {
        await _db.into(_db.ledgerEntries).insert(
          LedgerEntriesCompanion.insert(
            id: _uuid.v4(),
            transactionId: txId,
            accountId: Value(sourceAccountId),
            categoryOrEntityId: const Value('exp_financial'),
            entryType: 'credit',
            amount: feeCents,
            entryDate: transactionDate,
            description: 'Transfer fee: $description',
            createdAt: now,
          ),
        );
      }

      // 3. Update Account Balances
      final srcAccount = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(sourceAccountId))).getSingle();
      final destAccount = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(destinationAccountId))).getSingle();

      await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(sourceAccountId))).write(
        AccountsCompanion(
          currentBalance: Value(srcAccount.currentBalance - (amountCents + feeCents)),
          updatedAt: Value(now),
        ),
      );

      await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(destinationAccountId))).write(
        AccountsCompanion(
          currentBalance: Value(destAccount.currentBalance + amountCents),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final tx = await (_db.select(_db.transactions)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (tx == null || tx.status == 'cancelled') return;

    final now = DateTime.now();

    await _db.transaction(() async {
      // Reverse balances based on transaction type
      if (tx.type == TransactionType.income.name && tx.destinationAccountId != null) {
        final acc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.destinationAccountId!))).getSingle();
        await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(tx.destinationAccountId!))).write(
          AccountsCompanion(
            currentBalance: Value(acc.currentBalance - tx.amount),
            updatedAt: Value(now),
          ),
        );
      } else if (tx.type == TransactionType.expense.name && tx.sourceAccountId != null) {
        final acc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.sourceAccountId!))).getSingle();
        await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(tx.sourceAccountId!))).write(
          AccountsCompanion(
            currentBalance: Value(acc.currentBalance + tx.amount),
            updatedAt: Value(now),
          ),
        );
      } else if (tx.type == TransactionType.transfer.name) {
        if (tx.sourceAccountId != null) {
          final src = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.sourceAccountId!))).getSingle();
          await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(tx.sourceAccountId!))).write(
            AccountsCompanion(
              currentBalance: Value(src.currentBalance + tx.amount + tx.feeAmount),
              updatedAt: Value(now),
            ),
          );
        }
        if (tx.destinationAccountId != null) {
          final dest = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(tx.destinationAccountId!))).getSingle();
          await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(tx.destinationAccountId!))).write(
            AccountsCompanion(
              currentBalance: Value(dest.currentBalance - tx.amount),
              updatedAt: Value(now),
            ),
          );
        }
      }

      // Mark transaction as cancelled
      await (_db.update(_db.transactions)..where((tbl) => tbl.id.equals(id))).write(
        TransactionsCompanion(
          status: const Value('cancelled'),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      // Clean up ledger entries for this cancelled transaction
      await (_db.delete(_db.ledgerEntries)..where((tbl) => tbl.transactionId.equals(id))).go();
    });
  }
}
