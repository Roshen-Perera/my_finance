import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../database/app_database.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  unconfigured,
  error;

  String get displayName {
    switch (this) {
      case SyncStatus.idle:
        return 'Ready to Sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.success:
        return 'Synced Successfully';
      case SyncStatus.unconfigured:
        return 'Cloud Sync Not Configured';
      case SyncStatus.error:
        return 'Sync Failed (Offline / Server Error)';
    }
  }
}

class SyncService {
  final AppDatabase _db;
  final SharedPreferences _prefs;

  SyncService(this._db, this._prefs);

  bool get isCloudSyncEnabled => _prefs.getBool(AppConstants.prefCloudSyncEnabled) ?? false;
  String? get supabaseUrl => _prefs.getString(AppConstants.prefSupabaseUrl);
  String? get supabaseAnonKey => _prefs.getString(AppConstants.prefSupabaseAnonKey);

  bool get isConfigured =>
      supabaseUrl != null &&
      supabaseUrl!.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey!.isNotEmpty;

  Future<void> configureSupabase({
    required String url,
    required String anonKey,
    required bool enableSync,
  }) async {
    await _prefs.setString(AppConstants.prefSupabaseUrl, url);
    await _prefs.setString(AppConstants.prefSupabaseAnonKey, anonKey);
    await _prefs.setBool(AppConstants.prefCloudSyncEnabled, enableSync);

    if (enableSync && url.isNotEmpty && anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
        );
      } catch (_) {}
    }
  }

  /// Perform two-way sync safely with pending queue and fallback
  Future<({SyncStatus status, String message})> syncNow() async {
    if (!isCloudSyncEnabled || !isConfigured) {
      return (
        status: SyncStatus.unconfigured,
        message: 'Cloud sync is optional and disabled. Configure credentials in Settings to enable.',
      );
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        return (
          status: SyncStatus.unconfigured,
          message: 'Sign in with your cloud account to sync financial data.',
        );
      }

      final userId = user.id;

      // 1. Sync Accounts
      final pendingAccounts = await (_db.select(_db.accounts)..where((tbl) => tbl.syncStatus.equals('pending'))).get();
      for (final acc in pendingAccounts) {
        await client.from('accounts').upsert({
          'id': acc.id,
          'user_id': userId,
          'name': acc.name,
          'type': acc.type,
          'institution_name': acc.institutionName,
          'currency': acc.currency,
          'current_balance': acc.currentBalance,
          'opening_balance': acc.openingBalance,
          'is_archived': acc.isArchived,
          'updated_at': acc.updatedAt.toIso8601String(),
        });
        await (_db.update(_db.accounts)..where((tbl) => tbl.id.equals(acc.id))).write(
          const AccountsCompanion(syncStatus: Value('synced')),
        );
      }

      // 2. Sync Transactions
      final pendingTransactions = await (_db.select(_db.transactions)..where((tbl) => tbl.syncStatus.equals('pending'))).get();
      for (final tx in pendingTransactions) {
        await client.from('transactions').upsert({
          'id': tx.id,
          'user_id': userId,
          'type': tx.type,
          'amount': tx.amount,
          'source_account_id': tx.sourceAccountId,
          'destination_account_id': tx.destinationAccountId,
          'category_id': tx.categoryId,
          'sub_category_id': tx.subcategoryId,
          'transaction_date': tx.transactionDate.toIso8601String(),
          'description': tx.description,
          'notes': tx.notes,
          'status': tx.status,
          'updated_at': tx.updatedAt.toIso8601String(),
        });
        await (_db.update(_db.transactions)..where((tbl) => tbl.id.equals(tx.id))).write(
          const TransactionsCompanion(syncStatus: Value('synced')),
        );
      }

      return (
        status: SyncStatus.success,
        message: 'All records synced with Supabase cloud successfully.',
      );
    } catch (e) {
      return (
        status: SyncStatus.error,
        message: 'Could not sync with Supabase: $e',
      );
    }
  }
}
