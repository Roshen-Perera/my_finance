import '../../../core/database/app_database.dart';

abstract class AccountRepository {
  Stream<List<Account>> watchAllAccounts({bool includeArchived = false});
  Future<List<Account>> getAllAccounts({bool includeArchived = false});
  Future<Account?> getAccountById(String id);
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
  });
  Future<void> updateAccount(Account account);
  Future<void> archiveAccount(String id, bool archive);
  Future<void> reconcileBalance(String id, int actualBalanceCents);
}
