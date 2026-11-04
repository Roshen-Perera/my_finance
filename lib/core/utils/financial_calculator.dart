import '../constants/app_constants.dart';

class FinancialCalculator {
  /// Calculate total available liquid balance (excludes liabilities like credit cards and illiquid assets)
  static int calculateAvailableBalance(List<({String type, int balance})> accounts) {
    int total = 0;
    for (final acc in accounts) {
      final accType = _parseAccountType(acc.type);
      // Cash, savings, current, digital wallets are liquid available money
      if (accType == AccountType.cashWallet ||
          accType == AccountType.savingsAccount ||
          accType == AccountType.currentAccount ||
          accType == AccountType.digitalWallet) {
        total += acc.balance;
      }
    }
    return total;
  }

  /// Calculate total physical cash in hand
  static int calculateCashInHand(List<({String type, int balance})> accounts) {
    int total = 0;
    for (final acc in accounts) {
      if (_parseAccountType(acc.type) == AccountType.cashWallet) {
        total += acc.balance;
      }
    }
    return total;
  }

  /// Calculate combined bank balances (savings, current, fixed deposit)
  static int calculateBankBalances(List<({String type, int balance})> accounts) {
    int total = 0;
    for (final acc in accounts) {
      final accType = _parseAccountType(acc.type);
      if (accType == AccountType.savingsAccount ||
          accType == AccountType.currentAccount ||
          accType == AccountType.fixedDeposit) {
        total += acc.balance;
      }
    }
    return total;
  }

  /// Calculate total assets
  static int calculateTotalAssets({
    required List<({String type, int balance})> accounts,
    required int lentDebtsTotal, // Money lent to others that is still owed to us
  }) {
    int assets = 0;
    for (final acc in accounts) {
      final accType = _parseAccountType(acc.type);
      if (!accType.isLiability) {
        // Positive balances of asset accounts
        if (acc.balance > 0) {
          assets += acc.balance;
        }
      }
    }
    return assets + (lentDebtsTotal > 0 ? lentDebtsTotal : 0);
  }

  /// Calculate total outstanding liabilities (credit cards + borrowed debts)
  static int calculateTotalLiabilities({
    required List<({String type, int balance})> accounts,
    required int borrowedDebtsTotal, // Money borrowed from others
  }) {
    int liabilities = 0;
    for (final acc in accounts) {
      final accType = _parseAccountType(acc.type);
      if (accType.isLiability) {
        // For credit cards, if balance is negative, that's debt owed
        if (acc.balance < 0) {
          liabilities += acc.balance.abs();
        } else if (acc.balance > 0) {
          // If balance is recorded as positive debt
          liabilities += acc.balance;
        }
      }
    }
    return liabilities + (borrowedDebtsTotal > 0 ? borrowedDebtsTotal : 0);
  }

  /// Calculate estimated net worth = Assets - Liabilities
  static int calculateNetWorth({
    required List<({String type, int balance})> accounts,
    required int lentDebtsTotal,
    required int borrowedDebtsTotal,
  }) {
    final assets = calculateTotalAssets(accounts: accounts, lentDebtsTotal: lentDebtsTotal);
    final liabilities = calculateTotalLiabilities(accounts: accounts, borrowedDebtsTotal: borrowedDebtsTotal);
    return assets - liabilities;
  }

  /// Calculate net cash flow = Income - Expenses
  static int calculateNetCashFlow({
    required int totalIncomeCents,
    required int totalExpensesCents,
  }) {
    return totalIncomeCents - totalExpensesCents;
  }

  /// Calculate savings rate percentage: (Net Cash Flow / Total Income) * 100
  static double calculateSavingsRate({
    required int totalIncomeCents,
    required int totalExpensesCents,
  }) {
    if (totalIncomeCents <= 0) return 0.0;
    final net = totalIncomeCents - totalExpensesCents;
    if (net <= 0) return 0.0;
    final rate = (net / totalIncomeCents) * 100;
    return rate.clamp(0.0, 100.0);
  }

  /// Calculate budget progress
  static ({
    int remainingCents,
    double percentConsumed,
    bool isOverBudget,
  }) calculateBudgetProgress({
    required int budgetedAmountCents,
    required int spentAmountCents,
  }) {
    final remaining = budgetedAmountCents - spentAmountCents;
    final percent = budgetedAmountCents > 0
        ? (spentAmountCents / budgetedAmountCents) * 100
        : 0.0;
    return (
      remainingCents: remaining,
      percentConsumed: percent,
      isOverBudget: spentAmountCents > budgetedAmountCents,
    );
  }

  /// Calculate required monthly contribution for a savings goal
  static int calculateMonthlyGoalContribution({
    required int targetAmountCents,
    required int currentAmountCents,
    required DateTime targetDate,
    DateTime? fromDate,
  }) {
    final start = fromDate ?? DateTime.now();
    final remainingCents = targetAmountCents - currentAmountCents;
    if (remainingCents <= 0) return 0;

    int months = (targetDate.year - start.year) * 12 + targetDate.month - start.month;
    if (targetDate.day > start.day) months += 1;
    if (months <= 0) months = 1;

    return (remainingCents / months).ceil();
  }

  static AccountType _parseAccountType(String typeStr) {
    for (final type in AccountType.values) {
      if (type.name == typeStr) return type;
    }
    return AccountType.savingsAccount;
  }
}
