import 'package:flutter_test/flutter_test.dart';
import 'package:my_finance/core/constants/app_constants.dart';
import 'package:my_finance/core/utils/currency_formatter.dart';
import 'package:my_finance/core/utils/date_formatter.dart';
import 'package:my_finance/core/utils/financial_calculator.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('converts minor units (cents) to formatted LKR string', () {
      expect(CurrencyFormatter.formatCents(150050), 'Rs. 1,500.50');
      expect(CurrencyFormatter.formatCents(0), 'Rs. 0.00');
      expect(CurrencyFormatter.formatCents(-50000), '- Rs. 500.00');
    });

    test('parses formatted input string into minor units (cents)', () {
      expect(CurrencyFormatter.parseToCents('1,500.50'), 150050);
      expect(CurrencyFormatter.parseToCents('25000'), 2500000);
      expect(CurrencyFormatter.parseToCents('0.75'), 75);
      expect(CurrencyFormatter.parseToCents(''), isNull);
      expect(CurrencyFormatter.parseToCents('abc'), isNull);
    });

    test('cents to double and double to cents conversion', () {
      expect(CurrencyFormatter.centsToDouble(12500), 125.0);
      expect(CurrencyFormatter.doubleToCents(125.0), 12500);
      expect(CurrencyFormatter.doubleToCents(99.99), 9999);
    });

    test('compact currency formatting', () {
      expect(CurrencyFormatter.formatCompactCents(150000000), 'Rs. 1.5 M');
      expect(CurrencyFormatter.formatCompactCents(4500000), 'Rs. 45.0 k');
    });
  });

  group('FinancialCalculator Tests', () {
    test('calculateAvailableBalance includes liquid accounts and excludes liabilities', () {
      final accounts = [
        (type: AccountType.cashWallet.name, balance: 1000000), // 10,000 LKR
        (type: AccountType.savingsAccount.name, balance: 5000000), // 50,000 LKR
        (type: AccountType.currentAccount.name, balance: 2500000), // 25,000 LKR
        (type: AccountType.creditCard.name, balance: -1500000), // Credit card debt (-15,000 LKR)
      ];

      final available = FinancialCalculator.calculateAvailableBalance(accounts);
      expect(available, 8500000); // 10k + 50k + 25k = 85k LKR
    });

    test('calculateCashInHand calculates only cash wallet balances', () {
      final accounts = [
        (type: AccountType.cashWallet.name, balance: 1200000),
        (type: AccountType.savingsAccount.name, balance: 4000000),
      ];

      final cash = FinancialCalculator.calculateCashInHand(accounts);
      expect(cash, 1200000);
    });

    test('calculateBankBalances sums savings, current, and fixed deposits', () {
      final accounts = [
        (type: AccountType.cashWallet.name, balance: 1000000),
        (type: AccountType.savingsAccount.name, balance: 2000000),
        (type: AccountType.currentAccount.name, balance: 3000000),
        (type: AccountType.fixedDeposit.name, balance: 5000000),
      ];

      final bankTotal = FinancialCalculator.calculateBankBalances(accounts);
      expect(bankTotal, 10000000); // 20k + 30k + 50k = 100k LKR
    });

    test('calculateNetWorth correctly nets assets against liabilities', () {
      final accounts = [
        (type: AccountType.cashWallet.name, balance: 1000000), // 10k LKR
        (type: AccountType.savingsAccount.name, balance: 9000000), // 90k LKR
        (type: AccountType.creditCard.name, balance: -2000000), // 20k debt
      ];

      // Lent to a friend: 15,000 LKR (receivable asset)
      // Borrowed from bank: 30,000 LKR (payable liability)
      final netWorth = FinancialCalculator.calculateNetWorth(
        accounts: accounts,
        lentDebtsTotal: 1500000,
        borrowedDebtsTotal: 3000000,
      );

      // Total Assets: 10k (cash) + 90k (bank) + 15k (lent) = 115k LKR (11,500,000 cents)
      // Total Liabilities: 20k (card) + 30k (borrowed) = 50k LKR (5,000,000 cents)
      // Net Worth: 115k - 50k = 65k LKR (6,500,000 cents)
      expect(netWorth, 6500000);
    });

    test('calculateNetCashFlow and savingsRate', () {
      final net = FinancialCalculator.calculateNetCashFlow(
        totalIncomeCents: 15000000, // 150k LKR
        totalExpensesCents: 9000000, // 90k LKR
      );
      expect(net, 6000000); // 60k LKR

      final rate = FinancialCalculator.calculateSavingsRate(
        totalIncomeCents: 15000000,
        totalExpensesCents: 9000000,
      );
      expect(rate, 40.0); // 40%
    });

    test('calculateBudgetProgress', () {
      final progress = FinancialCalculator.calculateBudgetProgress(
        budgetedAmountCents: 5000000, // 50,000 LKR
        spentAmountCents: 4000000, // 40,000 LKR
      );
      expect(progress.remainingCents, 1000000);
      expect(progress.percentConsumed, 80.0);
      expect(progress.isOverBudget, isFalse);

      final overProgress = FinancialCalculator.calculateBudgetProgress(
        budgetedAmountCents: 5000000,
        spentAmountCents: 6000000,
      );
      expect(overProgress.remainingCents, -1000000);
      expect(overProgress.isOverBudget, isTrue);
    });

    test('calculateMonthlyGoalContribution', () {
      final now = DateTime(2026, 1, 1);
      final targetDate = DateTime(2026, 7, 1); // 6 months away
      final monthly = FinancialCalculator.calculateMonthlyGoalContribution(
        targetAmountCents: 6000000, // 60,000 LKR
        currentAmountCents: 0,
        targetDate: targetDate,
        fromDate: now,
      );
      expect(monthly, 1000000); // 10,000 LKR per month
    });
  });

  group('DateFormatter Tests', () {
    test('getMonthRange starts on day 1 or financial start day', () {
      final refDate = DateTime(2026, 5, 15);
      final standardRange = DateFormatter.getMonthRange(refDate, startDay: 1);
      expect(standardRange.start, DateTime(2026, 5, 1));
      expect(standardRange.end.month, 5);

      final financialRange = DateFormatter.getMonthRange(refDate, startDay: 25);
      // Since 15 < 25, start is April 25
      expect(financialRange.start, DateTime(2026, 4, 25));
    });
  });
}
