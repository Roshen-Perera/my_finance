import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_finance/core/constants/app_constants.dart';
import 'package:my_finance/core/database/app_database.dart';
import 'package:my_finance/features/accounts/data/account_repository_impl.dart';
import 'package:my_finance/features/transactions/data/transaction_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AccountRepositoryImpl accountRepo;
  late TransactionRepositoryImpl txRepo;

  setUp(() async {
    // In-memory sqlite database for testing
    db = AppDatabase(NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(db);
    txRepo = TransactionRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Creating Account establishes initial balance and ledger record', () async {
    await accountRepo.createAccount(
      name: 'BOC Savings',
      type: AccountType.savingsAccount.name,
      institutionName: 'Bank of Ceylon',
      currency: 'LKR',
      openingBalanceCents: 5000000, // 50,000 LKR
      openingDate: DateTime.now(),
      colorValue: 0xFF3B82F6,
      iconCode: 'account_balance',
    );

    final accounts = await accountRepo.getAllAccounts();
    expect(accounts.length, 1);
    expect(accounts.first.currentBalance, 5000000);

    final ledger = await db.select(db.ledgerEntries).get();
    expect(ledger.length, 1);
    expect(ledger.first.amount, 5000000);
    expect(ledger.first.entryType, 'debit');
  });

  test('Double-entry Income creates debit and credit ledger entries and increases balance', () async {
    await accountRepo.createAccount(
      name: 'Cash Wallet',
      type: AccountType.cashWallet.name,
      institutionName: 'Cash',
      currency: 'LKR',
      openingBalanceCents: 1000000, // 10,000 LKR
      openingDate: DateTime.now(),
      colorValue: 0xFF10B981,
      iconCode: 'account_balance_wallet',
    );

    final accounts = await accountRepo.getAllAccounts();
    final cashAcc = accounts.first;

    // Record 25,000 LKR Salary Income
    await txRepo.createIncome(
      amountCents: 2500000,
      destinationAccountId: cashAcc.id,
      categoryId: 'inc_salary',
      transactionDate: DateTime.now(),
      description: 'Monthly Salary',
    );

    final updatedAccount = await accountRepo.getAccountById(cashAcc.id);
    expect(updatedAccount!.currentBalance, 3500000); // 10k + 25k = 35k LKR

    final ledger = await (db.select(db.ledgerEntries)
          ..where((tbl) => tbl.amount.equals(2500000)))
        .get();
    expect(ledger.length, 2);
    // Balanced accounting: 1 Debit (to receiving account), 1 Credit (to income category)
    expect(ledger.any((l) => l.entryType == 'debit' && l.accountId == cashAcc.id), isTrue);
    expect(ledger.any((l) => l.entryType == 'credit' && l.categoryOrEntityId == 'inc_salary'), isTrue);
  });

  test('Double-entry Expense creates credit and debit entries and reduces balance', () async {
    await accountRepo.createAccount(
      name: 'Cash Wallet',
      type: AccountType.cashWallet.name,
      institutionName: 'Cash',
      currency: 'LKR',
      openingBalanceCents: 1000000, // 10,000 LKR
      openingDate: DateTime.now(),
      colorValue: 0xFF10B981,
      iconCode: 'account_balance_wallet',
    );

    final accounts = await accountRepo.getAllAccounts();
    final cashAcc = accounts.first;

    // Record 3,000 LKR Grocery Expense
    await txRepo.createExpense(
      amountCents: 300000,
      sourceAccountId: cashAcc.id,
      categoryId: 'exp_food',
      transactionDate: DateTime.now(),
      description: 'Supermarket Groceries',
    );

    final updatedAccount = await accountRepo.getAccountById(cashAcc.id);
    expect(updatedAccount!.currentBalance, 700000); // 10k - 3k = 7k LKR

    final ledger = await (db.select(db.ledgerEntries)
          ..where((tbl) => tbl.amount.equals(300000)))
        .get();
    expect(ledger.length, 2);
    // 1 Credit (to payment account), 1 Debit (to expense category)
    expect(ledger.any((l) => l.entryType == 'credit' && l.accountId == cashAcc.id), isTrue);
    expect(ledger.any((l) => l.entryType == 'debit' && l.categoryOrEntityId == 'exp_food'), isTrue);
  });

  test('Internal Transfer moves money between accounts without altering total wealth', () async {
    // Account A: Bank with 50,000 LKR
    await accountRepo.createAccount(
      name: 'Bank',
      type: AccountType.savingsAccount.name,
      institutionName: 'Bank',
      currency: 'LKR',
      openingBalanceCents: 5000000,
      openingDate: DateTime.now(),
      colorValue: 0xFF3B82F6,
      iconCode: 'account_balance',
    );
    // Account B: Cash with 5,000 LKR
    await accountRepo.createAccount(
      name: 'Cash',
      type: AccountType.cashWallet.name,
      institutionName: 'Cash',
      currency: 'LKR',
      openingBalanceCents: 500000,
      openingDate: DateTime.now(),
      colorValue: 0xFF10B981,
      iconCode: 'account_balance_wallet',
    );

    final accounts = await accountRepo.getAllAccounts();
    final bankAcc = accounts.firstWhere((a) => a.name == 'Bank');
    final cashAcc = accounts.firstWhere((a) => a.name == 'Cash');

    // Transfer 10,000 LKR from Bank to Cash with 50 LKR ATM fee
    await txRepo.createTransfer(
      amountCents: 1000000,
      sourceAccountId: bankAcc.id,
      destinationAccountId: cashAcc.id,
      feeCents: 5000,
      transactionDate: DateTime.now(),
      description: 'ATM Cash Withdrawal',
    );

    final updatedBank = await accountRepo.getAccountById(bankAcc.id);
    final updatedCash = await accountRepo.getAccountById(cashAcc.id);

    // Bank: 50k - (10k + 50 fee) = 39,950 LKR (3,995,000 cents)
    expect(updatedBank!.currentBalance, 3995000);
    // Cash: 5k + 10k = 15,000 LKR (1,500,000 cents)
    expect(updatedCash!.currentBalance, 1500000);
  });

  test('Deleting a transaction reverses balances and restores historical accuracy', () async {
    await accountRepo.createAccount(
      name: 'Cash',
      type: AccountType.cashWallet.name,
      institutionName: 'Cash',
      currency: 'LKR',
      openingBalanceCents: 1000000, // 10,000 LKR
      openingDate: DateTime.now(),
      colorValue: 0xFF10B981,
      iconCode: 'account_balance_wallet',
    );

    final accounts = await accountRepo.getAllAccounts();
    final cashAcc = accounts.first;

    await txRepo.createExpense(
      amountCents: 200000, // 2,000 LKR
      sourceAccountId: cashAcc.id,
      categoryId: 'exp_food',
      transactionDate: DateTime.now(),
      description: 'Lunch',
    );

    var currentAcc = await accountRepo.getAccountById(cashAcc.id);
    expect(currentAcc!.currentBalance, 800000); // 8,000 LKR

    final txList = await txRepo.getTransactions();
    final expenseTx = txList.firstWhere((t) => t.transaction.type == TransactionType.expense.name).transaction;

    // Delete and reverse
    await txRepo.deleteTransaction(expenseTx.id);

    currentAcc = await accountRepo.getAccountById(cashAcc.id);
    // Reversal should restore the balance back to 10,000 LKR
    expect(currentAcc!.currentBalance, 1000000);
  });
}
