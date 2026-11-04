import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/financial_calculator.dart';
import '../domain/analytics_models.dart';

class AnalyticsRepository {
  final AppDatabase _db;

  AnalyticsRepository(this._db);

  /// Computes real financial overview figures for dashboard & analytics
  Future<FinancialOverviewData> getFinancialOverview(DateTime referenceDate) async {
    // 1. Get Accounts
    final accounts = await (_db.select(_db.accounts)..where((tbl) => tbl.isArchived.equals(false))).get();
    final accountTuples = accounts.map((a) => (type: a.type, balance: a.currentBalance)).toList();

    final availableBalance = FinancialCalculator.calculateAvailableBalance(accountTuples);
    final cashInHand = FinancialCalculator.calculateCashInHand(accountTuples);
    final bankBalances = FinancialCalculator.calculateBankBalances(accountTuples);

    // 2. Debts
    final activeDebts = await (_db.select(_db.debts)..where((tbl) => tbl.status.equals('active'))).get();
    int lentTotal = 0;
    int borrowedTotal = 0;
    for (final d in activeDebts) {
      if (d.type == 'lent') {
        lentTotal += d.remainingAmount;
      } else {
        borrowedTotal += d.remainingAmount;
      }
    }

    final liabilities = FinancialCalculator.calculateTotalLiabilities(
      accounts: accountTuples,
      borrowedDebtsTotal: borrowedTotal,
    );

    final netWorth = FinancialCalculator.calculateNetWorth(
      accounts: accountTuples,
      lentDebtsTotal: lentTotal,
      borrowedDebtsTotal: borrowedTotal,
    );

    // 3. Savings Goals
    final goals = await _db.select(_db.savingsGoals).get();
    int totalSavings = 0;
    for (final g in goals) {
      totalSavings += g.currentAmount;
    }

    // 4. Month's Income & Expense
    final monthRange = DateFormatter.getMonthRange(referenceDate);
    final monthTransactions = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.status.equals('completed') &
              tbl.transactionDate.isBiggerOrEqualValue(monthRange.start) &
              tbl.transactionDate.isSmallerOrEqualValue(monthRange.end)))
        .get();

    int totalIncome = 0;
    int totalExpense = 0;
    for (final tx in monthTransactions) {
      if (tx.type == TransactionType.income.name) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense.name) {
        totalExpense += tx.amount;
      }
    }

    final netCashFlow = FinancialCalculator.calculateNetCashFlow(
      totalIncomeCents: totalIncome,
      totalExpensesCents: totalExpense,
    );

    final savingsRate = FinancialCalculator.calculateSavingsRate(
      totalIncomeCents: totalIncome,
      totalExpensesCents: totalExpense,
    );

    return FinancialOverviewData(
      availableBalanceCents: availableBalance,
      cashInHandCents: cashInHand,
      bankBalancesCents: bankBalances,
      totalIncomeMonthCents: totalIncome,
      totalExpenseMonthCents: totalExpense,
      netCashFlowCents: netCashFlow,
      totalSavingsCents: totalSavings,
      outstandingLiabilitiesCents: liabilities,
      estimatedNetWorthCents: netWorth,
      savingsRate: savingsRate,
    );
  }

  /// Calculates real category spending breakdown with percentages
  Future<List<CategorySpending>> getCategorySpendingBreakdown(
    DateTime start,
    DateTime end, {
    String type = 'expense',
  }) async {
    final transactions = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.type.equals(type) &
              tbl.status.equals('completed') &
              tbl.transactionDate.isBiggerOrEqualValue(start) &
              tbl.transactionDate.isSmallerOrEqualValue(end)))
        .get();

    final allCategories = await _db.select(_db.categories).get();
    final categoryMap = {for (final c in allCategories) c.id: c};

    final Map<String, int> spendingByCategory = {};
    int totalSpent = 0;

    for (final tx in transactions) {
      // Attribute to parent category if available, otherwise direct category
      String? targetCatId = tx.categoryId;
      if (targetCatId != null && categoryMap.containsKey(targetCatId)) {
        final cat = categoryMap[targetCatId]!;
        if (cat.parentCategoryId != null) {
          targetCatId = cat.parentCategoryId!;
        }
      }

      final key = targetCatId ?? 'unknown';
      spendingByCategory[key] = (spendingByCategory[key] ?? 0) + tx.amount;
      totalSpent += tx.amount;
    }

    final List<CategorySpending> result = [];
    spendingByCategory.forEach((catId, amount) {
      final category = categoryMap[catId];
      final name = category?.name ?? 'Other';
      final color = category?.colorValue ?? 0xFF94A3B8;
      final icon = category?.iconCode ?? 'category';
      final pct = totalSpent > 0 ? (amount / totalSpent) * 100 : 0.0;

      result.add(CategorySpending(
        categoryId: catId,
        categoryName: name,
        colorValue: color,
        iconCode: icon,
        amountCents: amount,
        percentage: pct,
      ));
    });

    result.sort((a, b) => b.amountCents.compareTo(a.amountCents));
    return result;
  }

  /// Generates real monthly income and expense trend points for charts
  Future<List<MonthlyTrendPoint>> getMonthlyTrend({int monthsBack = 6}) async {
    final now = DateTime.now();
    final List<MonthlyTrendPoint> points = [];

    for (int i = monthsBack - 1; i >= 0; i--) {
      final refDate = DateTime(now.year, now.month - i, 1);
      final range = DateFormatter.getMonthRange(refDate);

      final txList = await (_db.select(_db.transactions)
            ..where((tbl) =>
                tbl.status.equals('completed') &
                tbl.transactionDate.isBiggerOrEqualValue(range.start) &
                tbl.transactionDate.isSmallerOrEqualValue(range.end)))
          .get();

      int inc = 0;
      int exp = 0;
      for (final tx in txList) {
        if (tx.type == TransactionType.income.name) {
          inc += tx.amount;
        } else if (tx.type == TransactionType.expense.name) {
          exp += tx.amount;
        }
      }

      final label = DateFormat('MMM').format(refDate);
      points.add(MonthlyTrendPoint(
        monthLabel: label,
        incomeCents: inc,
        expenseCents: exp,
        netCents: inc - exp,
      ));
    }

    return points;
  }

  /// Generates daily spending trend points for the current date range
  Future<List<DailySpendingPoint>> getDailySpendingTrend(DateTime start, DateTime end) async {
    final txList = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.type.equals(TransactionType.expense.name) &
              tbl.status.equals('completed') &
              tbl.transactionDate.isBiggerOrEqualValue(start) &
              tbl.transactionDate.isSmallerOrEqualValue(end)))
        .get();

    final Map<String, int> dailyMap = {};
    for (final tx in txList) {
      final key = DateFormat('yyyy-MM-dd').format(tx.transactionDate);
      dailyMap[key] = (dailyMap[key] ?? 0) + tx.amount;
    }

    final List<DailySpendingPoint> points = [];
    var cur = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!cur.isAfter(last)) {
      final key = DateFormat('yyyy-MM-dd').format(cur);
      points.add(DailySpendingPoint(
        date: cur,
        amountCents: dailyMap[key] ?? 0,
      ));
      cur = cur.add(const Duration(days: 1));
    }

    return points;
  }

  /// Rule-based Financial Insights derived from real database data (Section 16)
  Future<List<FinancialInsight>> generateInsights(DateTime referenceDate) async {
    final List<FinancialInsight> insights = [];

    // Current month and previous month
    final thisMonthRange = DateFormatter.getMonthRange(referenceDate);
    final lastMonthRef = DateTime(referenceDate.year, referenceDate.month - 1, 1);
    final lastMonthRange = DateFormatter.getMonthRange(lastMonthRef);

    // This month spending & income
    final thisMonthTx = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.status.equals('completed') &
              tbl.transactionDate.isBiggerOrEqualValue(thisMonthRange.start) &
              tbl.transactionDate.isSmallerOrEqualValue(thisMonthRange.end)))
        .get();

    int thisMonthExp = 0;
    int thisMonthInc = 0;
    for (final tx in thisMonthTx) {
      if (tx.type == TransactionType.expense.name) thisMonthExp += tx.amount;
      if (tx.type == TransactionType.income.name) thisMonthInc += tx.amount;
    }

    // Last month spending
    final lastMonthTx = await (_db.select(_db.transactions)
          ..where((tbl) =>
              tbl.type.equals(TransactionType.expense.name) &
              tbl.status.equals('completed') &
              tbl.transactionDate.isBiggerOrEqualValue(lastMonthRange.start) &
              tbl.transactionDate.isSmallerOrEqualValue(lastMonthRange.end)))
        .get();

    int lastMonthExp = 0;
    for (final tx in lastMonthTx) {
      lastMonthExp += tx.amount;
    }

    // Insight 1: Spending comparison with last month
    if (lastMonthExp > 0 && thisMonthExp > 0) {
      final diff = thisMonthExp - lastMonthExp;
      final pct = ((diff.abs() / lastMonthExp) * 100).toStringAsFixed(1);
      if (diff > 0) {
        insights.add(FinancialInsight(
          id: 'ins_spending_increase',
          title: 'Spending Increased',
          message: 'Your spending increased by $pct% compared with last month (${CurrencyFormatter.formatCents(diff)} higher).',
          type: 'warning',
          iconCode: 'trending_up',
        ));
      } else if (diff < 0) {
        insights.add(FinancialInsight(
          id: 'ins_spending_decrease',
          title: 'Great Spending Control',
          message: 'Your spending is down by $pct% compared with last month (${CurrencyFormatter.formatCents(diff.abs())} saved)!',
          type: 'positive',
          iconCode: 'trending_down',
        ));
      }
    }

    // Insight 2: Deficit warning
    if (thisMonthInc > 0 && thisMonthExp > thisMonthInc) {
      final deficit = thisMonthExp - thisMonthInc;
      insights.add(FinancialInsight(
        id: 'ins_deficit',
        title: 'Negative Cash Flow',
        message: 'You are spending more than you earn this month by ${CurrencyFormatter.formatCents(deficit)}.',
        type: 'alert',
        iconCode: 'warning_amber',
      ));
    } else if (thisMonthInc > 0 && thisMonthExp <= thisMonthInc) {
      final savingsRate = FinancialCalculator.calculateSavingsRate(
        totalIncomeCents: thisMonthInc,
        totalExpensesCents: thisMonthExp,
      );
      if (savingsRate >= 20.0) {
        insights.add(FinancialInsight(
          id: 'ins_healthy_savings',
          title: 'Healthy Savings Rate',
          message: 'You are saving ${savingsRate.toStringAsFixed(1)}% of your income this month. Keep it up!',
          type: 'positive',
          iconCode: 'savings',
        ));
      }
    }

    // Insight 3: Top spending category
    final breakdown = await getCategorySpendingBreakdown(thisMonthRange.start, thisMonthRange.end);
    if (breakdown.isNotEmpty && breakdown.first.percentage > 25.0) {
      final top = breakdown.first;
      insights.add(FinancialInsight(
        id: 'ins_top_category',
        title: 'Top Expense Category',
        message: '${top.categoryName} accounts for ${top.percentage.toStringAsFixed(1)}% of your monthly expenses (${CurrencyFormatter.formatCents(top.amountCents)}).',
        type: 'info',
        iconCode: top.iconCode,
      ));
    }

    // Insight 4: Upcoming recurring payments
    final now = DateTime.now();
    final upcomingRecurring = await (_db.select(_db.recurringTransactions)
          ..where((tbl) =>
              tbl.isActive.equals(true) &
              tbl.nextDueDate.isBiggerOrEqualValue(now) &
              tbl.nextDueDate.isSmallerOrEqualValue(now.add(const Duration(days: 7)))))
        .get();

    for (final rec in upcomingRecurring) {
      insights.add(FinancialInsight(
        id: 'ins_recurring_${rec.id}',
        title: 'Upcoming Bill Due Soon',
        message: '${rec.title} of ${CurrencyFormatter.formatCents(rec.amount)} is due on ${DateFormatter.formatDate(rec.nextDueDate)}.',
        type: 'warning',
        iconCode: 'notifications_active',
      ));
    }

    return insights;
  }
}
