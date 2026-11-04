import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/debt_repository.dart';

class DebtRepositoryImpl implements DebtRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DebtRepositoryImpl(this._db);

  @override
  Stream<List<DebtWithDetails>> watchDebts({String? type}) {
    final query = _db.select(_db.debts);
    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    query.orderBy([(tbl) => OrderingTerm.desc(tbl.startDate)]);

    return query.watch().asyncMap((debts) async {
      final List<DebtWithDetails> result = [];

      for (final debt in debts) {
        Account? linkedAcc;
        if (debt.linkedAccountId != null) {
          linkedAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(debt.linkedAccountId!))).getSingleOrNull();
        }

        final payments = await (_db.select(_db.debtPayments)
              ..where((tbl) => tbl.debtId.equals(debt.id))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.paymentDate)]))
            .get();

        result.add(DebtWithDetails(
          debt: debt,
          linkedAccount: linkedAcc,
          payments: payments,
        ));
      }

      return result;
    });
  }

  @override
  Future<void> createDebt({
    required String title,
    required String type,
    required String counterpartyName,
    required int principalAmountCents,
    double interestRate = 0.0,
    required DateTime startDate,
    DateTime? dueDate,
    String? linkedAccountId,
    String? notes,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.debts).insert(
      DebtsCompanion.insert(
        id: _uuid.v4(),
        title: title,
        type: type,
        counterpartyName: counterpartyName,
        principalAmount: principalAmountCents,
        remainingAmount: principalAmountCents,
        interestRate: Value(interestRate),
        startDate: startDate,
        dueDate: Value(dueDate),
        linkedAccountId: Value(linkedAccountId),
        status: const Value('active'),
        notes: Value(notes),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> recordPayment({
    required String debtId,
    required int principalAmountCents,
    int interestAmountCents = 0,
    String? accountId,
    String? notes,
  }) async {
    final debt = await (_db.select(_db.debts)..where((tbl) => tbl.id.equals(debtId))).getSingle();
    final now = DateTime.now();
    final totalPaymentCents = principalAmountCents + interestAmountCents;

    await _db.transaction(() async {
      String? txId;

      if (accountId != null && totalPaymentCents > 0) {
        txId = _uuid.v4();
        final acc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(accountId))).getSingle();

        if (debt.type == 'borrowed') {
          // Paying off debt we borrowed: Money leaves account (expense/outflow)
          await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: txId,
              type: TransactionType.expense.name,
              amount: totalPaymentCents,
              sourceAccountId: Value(accountId),
              transactionDate: now,
              description: 'Debt repayment: ${debt.title}',
              notes: Value(notes),
              status: const Value('completed'),
              createdAt: now,
              updatedAt: now,
            ),
          );

          await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(accountId))).write(
            AccountsCompanion(
              currentBalance: Value(acc.currentBalance - totalPaymentCents),
              updatedAt: Value(now),
            ),
          );
        } else {
          // Receiving repayment for debt we lent: Money enters account (income/inflow)
          await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: txId,
              type: TransactionType.income.name,
              amount: totalPaymentCents,
              destinationAccountId: Value(accountId),
              transactionDate: now,
              description: 'Debt repayment received: ${debt.title}',
              notes: Value(notes),
              status: const Value('completed'),
              createdAt: now,
              updatedAt: now,
            ),
          );

          await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(accountId))).write(
            AccountsCompanion(
              currentBalance: Value(acc.currentBalance + totalPaymentCents),
              updatedAt: Value(now),
            ),
          );
        }
      }

      // Record DebtPayment
      await _db.into(_db.debtPayments).insert(
        DebtPaymentsCompanion.insert(
          id: _uuid.v4(),
          debtId: debtId,
          transactionId: Value(txId),
          principalAmountPaid: Value(principalAmountCents),
          interestAmountPaid: Value(interestAmountCents),
          paymentDate: now,
          notes: Value(notes),
        ),
      );

      // Update remaining debt balance
      final updatedRemaining = debt.remainingAmount - principalAmountCents;
      final isSettled = updatedRemaining <= 0;

      await (_db.update(_db.debts)..where((tbl) => tbl.id.equals(debtId))).write(
        DebtsCompanion(
          remainingAmount: Value(updatedRemaining < 0 ? 0 : updatedRemaining),
          status: Value(isSettled ? 'settled' : 'active'),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.debtPayments)..where((tbl) => tbl.debtId.equals(id))).go();
      await (_db.delete(_db.debts)..where((tbl) => tbl.id.equals(id))).go();
    });
  }
}
