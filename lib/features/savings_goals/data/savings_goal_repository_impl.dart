import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/savings_goal_repository.dart';

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  SavingsGoalRepositoryImpl(this._db);

  @override
  Stream<List<SavingsGoalWithDetails>> watchGoals() {
    return _db.select(_db.savingsGoals).watch().asyncMap((goals) async {
      final List<SavingsGoalWithDetails> result = [];

      for (final goal in goals) {
        Account? linkedAcc;
        if (goal.linkedAccountId != null) {
          linkedAcc = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(goal.linkedAccountId!))).getSingleOrNull();
        }

        final contributions = await (_db.select(_db.savingsContributions)
              ..where((tbl) => tbl.goalId.equals(goal.id))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.contributionDate)]))
            .get();

        result.add(SavingsGoalWithDetails(
          goal: goal,
          linkedAccount: linkedAcc,
          contributions: contributions,
        ));
      }

      return result;
    });
  }

  @override
  Future<void> createGoal({
    required String name,
    required int targetAmountCents,
    required DateTime targetDate,
    required int monthlyContributionTargetCents,
    String? linkedAccountId,
    String? description,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.savingsGoals).insert(
      SavingsGoalsCompanion.insert(
        id: _uuid.v4(),
        name: name,
        targetAmount: targetAmountCents,
        currentAmount: const Value(0),
        targetDate: targetDate,
        monthlyContributionTarget: Value(monthlyContributionTargetCents),
        linkedAccountId: Value(linkedAccountId),
        description: Value(description),
        status: const Value('active'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> addContribution({
    required String goalId,
    required int amountCents,
    String? sourceAccountId,
    String? notes,
  }) async {
    final goal = await (_db.select(_db.savingsGoals)..where((tbl) => tbl.id.equals(goalId))).getSingle();
    final now = DateTime.now();
    final contributionId = _uuid.v4();

    await _db.transaction(() async {
      String? txId;

      // If source account specified, debit/credit ledger and deduct balance from account
      if (sourceAccountId != null) {
        txId = _uuid.v4();
        await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: txId,
            type: TransactionType.transfer.name,
            amount: amountCents,
            sourceAccountId: Value(sourceAccountId),
            destinationAccountId: Value(goal.linkedAccountId),
            transactionDate: now,
            description: 'Contribution to savings goal: ${goal.name}',
            notes: Value(notes),
            status: const Value('completed'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        final src = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(sourceAccountId))).getSingle();
        await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(sourceAccountId))).write(
          AccountsCompanion(
            currentBalance: Value(src.currentBalance - amountCents),
            updatedAt: Value(now),
          ),
        );

        if (goal.linkedAccountId != null && goal.linkedAccountId != sourceAccountId) {
          final dest = await (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(goal.linkedAccountId!))).getSingle();
          await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(goal.linkedAccountId!))).write(
            AccountsCompanion(
              currentBalance: Value(dest.currentBalance + amountCents),
              updatedAt: Value(now),
            ),
          );
        }
      }

      // Record contribution
      await _db.into(_db.savingsContributions).insert(
        SavingsContributionsCompanion.insert(
          id: contributionId,
          goalId: goalId,
          transactionId: Value(txId),
          amount: amountCents,
          contributionDate: now,
          notes: Value(notes),
        ),
      );

      // Update goal current amount
      final updatedAmount = goal.currentAmount + amountCents;
      final isCompleted = updatedAmount >= goal.targetAmount;

      await (_db.update(_db.savingsGoals)..where((tbl) => tbl.id.equals(goalId))).write(
        SavingsGoalsCompanion(
          currentAmount: Value(updatedAmount),
          status: Value(isCompleted ? 'completed' : 'active'),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.savingsContributions)..where((tbl) => tbl.goalId.equals(id))).go();
      await (_db.delete(_db.savingsGoals)..where((tbl) => tbl.id.equals(id))).go();
    });
  }
}
