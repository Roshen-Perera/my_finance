class CategorySpending {
  final String categoryId;
  final String categoryName;
  final int colorValue;
  final String iconCode;
  final int amountCents;
  final double percentage;

  CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.iconCode,
    required this.amountCents,
    required this.percentage,
  });
}

class MonthlyTrendPoint {
  final String monthLabel;
  final int incomeCents;
  final int expenseCents;
  final int netCents;

  MonthlyTrendPoint({
    required this.monthLabel,
    required this.incomeCents,
    required this.expenseCents,
    required this.netCents,
  });
}

class DailySpendingPoint {
  final DateTime date;
  final int amountCents;

  DailySpendingPoint({
    required this.date,
    required this.amountCents,
  });
}

class FinancialInsight {
  final String id;
  final String title;
  final String message;
  final String type; // 'positive', 'warning', 'info', 'alert'
  final String iconCode;

  FinancialInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.iconCode,
  });
}

class FinancialOverviewData {
  final int availableBalanceCents;
  final int cashInHandCents;
  final int bankBalancesCents;
  final int totalIncomeMonthCents;
  final int totalExpenseMonthCents;
  final int netCashFlowCents;
  final int totalSavingsCents;
  final int outstandingLiabilitiesCents;
  final int estimatedNetWorthCents;
  final double savingsRate;

  FinancialOverviewData({
    required this.availableBalanceCents,
    required this.cashInHandCents,
    required this.bankBalancesCents,
    required this.totalIncomeMonthCents,
    required this.totalExpenseMonthCents,
    required this.netCashFlowCents,
    required this.totalSavingsCents,
    required this.outstandingLiabilitiesCents,
    required this.estimatedNetWorthCents,
    required this.savingsRate,
  });
}
