import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cashWallet, savingsAccount, currentAccount, etc.
  TextColumn get institutionName => text()();
  TextColumn get currency => text().withDefault(const Constant('LKR'))();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))(); // Cents
  IntColumn get currentBalance => integer().withDefault(const Constant(0))(); // Cents
  DateTimeColumn get openingDate => dateTime()();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF0D9488))();
  TextColumn get iconCode => text().withDefault(const Constant('account_balance_wallet'))();
  TextColumn get maskedAccountNumber => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get parentCategoryId => text().nullable()();
  TextColumn get iconCode => text().withDefault(const Constant('category'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF10B981))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // income, expense, transfer, refund, adjustment
  IntColumn get amount => integer()(); // in cents, positive
  TextColumn get sourceAccountId => text().nullable()();
  TextColumn get destinationAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get subcategoryId => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get description => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get feeAmount => integer().withDefault(const Constant(0))(); // in cents
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringTransactionId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('completed'))(); // completed, reversed, cancelled
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get categoryOrEntityId => text().nullable()();
  TextColumn get entryType => text()(); // 'debit' or 'credit'
  IntColumn get amount => integer()(); // in cents
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amount => integer()(); // in cents
  TextColumn get period => text().withDefault(const Constant('monthly'))(); // monthly, weekly, custom
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get warningThresholdPercent => integer().withDefault(const Constant(80))();
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class BudgetCategories extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text()();
  TextColumn get categoryId => text()();
  IntColumn get allocatedAmount => integer().nullable()(); // optional specific allocation in cents

  @override
  Set<Column> get primaryKey => {id};
}

class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get targetAmount => integer()(); // in cents
  IntColumn get currentAmount => integer().withDefault(const Constant(0))(); // in cents
  DateTimeColumn get targetDate => dateTime()();
  IntColumn get monthlyContributionTarget => integer().withDefault(const Constant(0))(); // in cents
  TextColumn get linkedAccountId => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, completed, cancelled
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SavingsContributions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text()();
  TextColumn get transactionId => text().nullable()();
  IntColumn get amount => integer()(); // in cents, positive for deposit, negative for withdrawal
  DateTimeColumn get contributionDate => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()(); // 'lent' or 'borrowed'
  TextColumn get counterpartyName => text()();
  IntColumn get principalAmount => integer()(); // in cents
  IntColumn get remainingAmount => integer()(); // in cents
  RealColumn get interestRate => real().withDefault(const Constant(0.0))(); // % annual
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get linkedAccountId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active, settled, defaulted
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DebtPayments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text()();
  TextColumn get transactionId => text().nullable()();
  IntColumn get principalAmountPaid => integer().withDefault(const Constant(0))(); // in cents
  IntColumn get interestAmountPaid => integer().withDefault(const Constant(0))(); // in cents
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()(); // income, expense, transfer
  IntColumn get amount => integer()(); // in cents
  TextColumn get sourceAccountId => text().nullable()();
  TextColumn get destinationAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get frequency => text()(); // daily, weekly, monthly, yearly
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isAutoGenerated => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFF0D9488))();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionTags extends Table {
  TextColumn get transactionId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class SyncMetadata extends Table {
  TextColumn get entityTable => text()();
  TextColumn get recordId => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get syncAction => text().withDefault(const Constant('upsert'))(); // upsert, delete
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending, synced, conflict, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {entityTable, recordId};
}
