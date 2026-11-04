import '../../../core/database/app_database.dart';

class DebtWithDetails {
  final Debt debt;
  final Account? linkedAccount;
  final List<DebtPayment> payments;

  DebtWithDetails({
    required this.debt,
    this.linkedAccount,
    this.payments = const [],
  });

  bool get isSettled => debt.status == 'settled' || debt.remainingAmount <= 0;
  double get repaymentProgress => debt.principalAmount > 0
      ? (((debt.principalAmount - debt.remainingAmount) / debt.principalAmount) * 100).clamp(0.0, 100.0)
      : 100.0;
}

abstract class DebtRepository {
  Stream<List<DebtWithDetails>> watchDebts({String? type});
  Future<void> createDebt({
    required String title,
    required String type, // 'lent' or 'borrowed'
    required String counterpartyName,
    required int principalAmountCents,
    double interestRate = 0.0,
    required DateTime startDate,
    DateTime? dueDate,
    String? linkedAccountId,
    String? notes,
  });
  Future<void> recordPayment({
    required String debtId,
    required int principalAmountCents,
    int interestAmountCents = 0,
    String? accountId,
    String? notes,
  });
  Future<void> deleteDebt(String id);
}
