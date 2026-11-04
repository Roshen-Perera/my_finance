import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  AccountRepositoryImpl(this._db);

  @override
  Stream<List<Account>> watchAllAccounts({bool includeArchived = false}) {
    final query = _db.select(_db.accounts);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  @override
  Future<List<Account>> getAllAccounts({bool includeArchived = false}) {
    final query = _db.select(_db.accounts);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.get();
  }

  @override
  Future<Account?> getAccountById(String id) {
    return (_db.select(_db.accounts)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<void> createAccount({
    required String name,
    required String type,
    required String institutionName,
    required String currency,
    required int openingBalanceCents,
    required DateTime openingDate,
    required int colorValue,
    required String iconCode,
    String? maskedAccountNumber,
  }) async {
    final accountId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.accounts).insert(
        AccountsCompanion.insert(
          id: accountId,
          name: name,
          type: type,
          institutionName: institutionName,
          currency: Value(currency),
          openingBalance: Value(openingBalanceCents),
          currentBalance: Value(openingBalanceCents),
          openingDate: openingDate,
          colorValue: Value(colorValue),
          iconCode: Value(iconCode),
          maskedAccountNumber: Value(maskedAccountNumber),
          isArchived: const Value(false),
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('pending'),
        ),
      );

      // If opening balance != 0, record an opening balance ledger entry
      if (openingBalanceCents != 0) {
        final txId = _uuid.v4();
        await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: txId,
            type: TransactionType.adjustment.name,
            amount: openingBalanceCents.abs(),
            destinationAccountId: openingBalanceCents > 0 ? Value(accountId) : const Value.absent(),
            sourceAccountId: openingBalanceCents < 0 ? Value(accountId) : const Value.absent(),
            transactionDate: openingDate,
            description: 'Opening Balance for $name',
            status: const Value('completed'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await _db.into(_db.ledgerEntries).insert(
          LedgerEntriesCompanion.insert(
            id: _uuid.v4(),
            transactionId: txId,
            accountId: Value(accountId),
            entryType: openingBalanceCents > 0 ? 'debit' : 'credit',
            amount: openingBalanceCents.abs(),
            entryDate: openingDate,
            description: 'Opening Balance',
            createdAt: now,
          ),
        );
      }
    });
  }

  @override
  Future<void> updateAccount(Account account) async {
    final now = DateTime.now();
    await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(account.id))).write(
      AccountsCompanion(
        name: Value(account.name),
        type: Value(account.type),
        institutionName: Value(account.institutionName),
        colorValue: Value(account.colorValue),
        iconCode: Value(account.iconCode),
        maskedAccountNumber: Value(account.maskedAccountNumber),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> archiveAccount(String id, bool archive) async {
    final now = DateTime.now();
    await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(id))).write(
      AccountsCompanion(
        isArchived: Value(archive),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> reconcileBalance(String id, int actualBalanceCents) async {
    final account = await getAccountById(id);
    if (account == null) return;

    final diff = actualBalanceCents - account.currentBalance;
    if (diff == 0) return;

    final now = DateTime.now();
    final txId = _uuid.v4();

    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          id: txId,
          type: TransactionType.adjustment.name,
          amount: diff.abs(),
          destinationAccountId: diff > 0 ? Value(id) : const Value.absent(),
          sourceAccountId: diff < 0 ? Value(id) : const Value.absent(),
          transactionDate: now,
          description: 'Balance Reconciliation',
          notes: Value('Reconciled from ${account.currentBalance} to $actualBalanceCents'),
          status: const Value('completed'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _db.into(_db.ledgerEntries).insert(
        LedgerEntriesCompanion.insert(
          id: _uuid.v4(),
          transactionId: txId,
          accountId: Value(id),
          entryType: diff > 0 ? 'debit' : 'credit',
          amount: diff.abs(),
          entryDate: now,
          description: 'Reconciliation adjustment',
          createdAt: now,
        ),
      );

      await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(id))).write(
        AccountsCompanion(
          currentBalance: Value(actualBalanceCents),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );
    });
  }
}
