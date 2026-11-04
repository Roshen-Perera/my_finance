class AppConstants {
  static const String appName = 'MyFinance';
  static const String appTagline = 'Master Your Personal Wealth';

  // Currency
  static const String defaultCurrencyCode = 'LKR';
  static const String defaultCurrencySymbol = 'Rs.';
  static const int currencyDecimals = 2;
  static const int centsFactor = 100; // 1 LKR = 100 cents

  // Preference Keys
  static const String prefThemeMode = 'app_theme_mode';
  static const String prefCurrencyCode = 'app_currency_code';
  static const String prefCurrencySymbol = 'app_currency_symbol';
  static const String prefOnboardingComplete = 'app_onboarding_complete';
  static const String prefBiometricEnabled = 'app_biometric_enabled';
  static const String prefPinCode = 'app_pin_code';
  static const String prefPinEnabled = 'app_pin_enabled';
  static const String prefFinancialMonthStartDay = 'financial_month_start_day';
  static const String prefCloudSyncEnabled = 'cloud_sync_enabled';
  static const String prefSupabaseUrl = 'supabase_url';
  static const String prefSupabaseAnonKey = 'supabase_anon_key';
}

enum AccountType {
  cashWallet,
  savingsAccount,
  currentAccount,
  fixedDeposit,
  digitalWallet,
  creditCard,
  foreignCurrency,
  otherAsset;

  String get displayName {
    switch (this) {
      case AccountType.cashWallet:
        return 'Cash Wallet';
      case AccountType.savingsAccount:
        return 'Savings Account';
      case AccountType.currentAccount:
        return 'Current Account';
      case AccountType.fixedDeposit:
        return 'Fixed Deposit';
      case AccountType.digitalWallet:
        return 'Digital Wallet';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.foreignCurrency:
        return 'Foreign Currency';
      case AccountType.otherAsset:
        return 'Other Asset';
    }
  }

  bool get isLiability => this == AccountType.creditCard;
}

enum TransactionType {
  income,
  expense,
  transfer,
  refund,
  adjustment;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }
}

enum DebtType {
  lent, // Money lent to others (Asset / Receivable)
  borrowed; // Money borrowed from others (Liability / Payable)

  String get displayName {
    switch (this) {
      case DebtType.lent:
        return 'Lent to Others';
      case DebtType.borrowed:
        return 'Borrowed from Others';
    }
  }
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }
}
