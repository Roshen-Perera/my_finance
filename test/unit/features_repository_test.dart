import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_finance/core/constants/app_constants.dart';
import 'package:my_finance/core/database/app_database.dart';
import 'package:my_finance/features/accounts/data/account_repository_impl.dart';
import 'package:my_finance/features/budgets/data/budget_repository_impl.dart';
import 'package:my_finance/features/debts/data/debt_repository_impl.dart';
import 'package:my_finance/features/recurring_transactions/data/recurring_repository_impl.dart';
import 'package:my_finance/features/savings_goals/data/savings_goal_repository_impl.dart';
import 'package:my_finance/features/transactions/data/transaction_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AccountRepositoryImpl accountRepo;
  late TransactionRepositoryImpl txRepo;
  late BudgetRepositoryImpl budgetRepo;
  late SavingsGoalRepositoryImpl savingsRepo;
  late DebtRepositoryImpl debtRepo;
  late RecurringRepositoryImpl recurringRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(db);
    txRepo = TransactionRepositoryImpl(db);
    budgetRepo = BudgetRepositoryImpl(db);
    savingsRepo = SavingsGoalRepositoryImpl(db);
    debtRepo = DebtRepositoryImpl(db);
    recurringRepo = RecurringRepositoryImpl(db, txRepo);
  });

  tearDown(() async {
    await db.close();
  });

  test('Budget tracks actual category expense consumption', () async {
    // 1. Create Account
    await accountRepo.createAccount(
      name: 'Cash',
      type: AccountType.cashWallet.name,
      institutionName: 'Cash',
      currency: 'LKR',
      openingBalanceCents: 5000000,
      openingDate: DateTime.now(),
      colorValue: 0xFF10B981,
      iconCode: 'account_balance_wallet',
    );
    final acc = (await accountRepo.getAllAccounts()).first;

    // 2. Create Budget for Food & Dining (exp_food) with limit 20,000 LKR (2,000,000 cents)
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    await budgetRepo.createBudget(
      name: 'Food Budget',
      amountCents: 2000000,
      period: 'monthly',
      startDate: start,
      endDate: end,
      warningThresholdPercent: 80,
      rollover: false,
      categoryIds: ['exp_food'],
    );

    // 3. Record Food Expense of 16,000 LKR (1,600,000 cents)
    await txRepo.createExpense(
      amountCents: 1600000,
      sourceAccountId: acc.id,
      categoryId: 'exp_food',
      transactionDate: now,
      description: 'Dinner',
    );

    final budgets = await budgetRepo.watchBudgets().first;
    expect(budgets.length, 1);
    final b = budgets.first;
    expect(b.spentCents, 1600000);
    expect(b.remainingCents, 400000);
    expect(b.percentageConsumed, 80.0);
    expect(b.isWarning, isTrue);
    expect(b.isOverBudget, isFalse);
  });

  test('Savings Goal tracks contributions and updates progress', () async {
    await savingsRepo.createGoal(
      name: 'Emergency Fund',
      targetAmountCents: 5000000, // 50,000 LKR
      targetDate: DateTime.now().add(const Duration(days: 180)),
      monthlyContributionTargetCents: 1000000,
    );

    final goalsBefore = await savingsRepo.watchGoals().first;
    expect(goalsBefore.first.goal.currentAmount, 0);

    // Add 20,000 LKR contribution
    await savingsRepo.addContribution(
      goalId: goalsBefore.first.goal.id,
      amountCents: 2000000,
      notes: 'Initial savings deposit',
    );

    final goalsAfter = await savingsRepo.watchGoals().first;
    final goal = goalsAfter.first;
    expect(goal.goal.currentAmount, 2000000);
    expect(goal.progressPercentage, 40.0);
    expect(goal.remainingCents, 3000000);
  });

  test('Debt Repayment reduces remaining balance and marks settled when paid', () async {
    // Lent 10,000 LKR to friend
    await debtRepo.createDebt(
      title: 'Loan to Amal',
      type: 'lent',
      counterpartyName: 'Amal',
      principalAmountCents: 1000000, // 10,000 LKR
      startDate: DateTime.now(),
    );

    final debts = await debtRepo.watchDebts().first;
    final debt = debts.first;
    expect(debt.debt.remainingAmount, 1000000);

    // Partial payment: 6,000 LKR
    await debtRepo.recordPayment(
      debtId: debt.debt.id,
      principalAmountCents: 600000,
    );

    var updatedDebts = await debtRepo.watchDebts().first;
    expect(updatedDebts.first.debt.remainingAmount, 400000);
    expect(updatedDebts.first.isSettled, isFalse);

    // Final payment: 4,000 LKR
    await debtRepo.recordPayment(
      debtId: debt.debt.id,
      principalAmountCents: 400000,
    );

    updatedDebts = await debtRepo.watchDebts().first;
    expect(updatedDebts.first.debt.remainingAmount, 0);
    expect(updatedDebts.first.isSettled, isTrue);
  });

  test('Recurring transaction auto-generation advances nextDueDate', () async {
    await accountRepo.createAccount(
      name: 'Savings',
      type: AccountType.savingsAccount.name,
      institutionName: 'Bank',
      currency: 'LKR',
      openingBalanceCents: 5000000,
      openingDate: DateTime.now(),
      colorValue: 0xFF3B82F6,
      iconCode: 'account_balance',
    );
    final acc = (await accountRepo.getAllAccounts()).first;

    // Past due recurring activity
    final pastDate = DateTime.now().subtract(const Duration(days: 2));
    await recurringRepo.createRecurring(
      title: 'Monthly Internet',
      type: TransactionType.expense.name,
      amountCents: 350000, // 3,500 LKR
      sourceAccountId: acc.id,
      categoryId: 'exp_utilities',
      frequency: RecurrenceFrequency.monthly.name,
      startDate: pastDate,
      nextDueDate: pastDate,
      isAutoGenerated: true,
    );

    // Process due
    await recurringRepo.processDueRecurring();

    final txList = await txRepo.getTransactions();
    // Transaction should be automatically generated
    expect(txList.any((t) => t.transaction.description.contains('Monthly Internet')), isTrue);

    // Recurring nextDueDate should have been advanced into the future
    final recurringList = await recurringRepo.watchRecurring().first;
    expect(recurringList.first.recurring.nextDueDate.isAfter(DateTime.now()), isTrue);
  });
}
