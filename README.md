# MyFinance — Personal Finance & Wealth Management Application

**MyFinance** is a comprehensive personal financial management application designed to track, manage, and optimize personal wealth. Built with Flutter, Clean Architecture, Riverpod, Drift ORM (SQLite), and optional Supabase cloud integration, MyFinance provides reliable financial calculations, offline-first operation, and a polished Material 3 fintech aesthetic.

---

## Key Features

### 1. Dashboard & Financial Intelligence
- **Available Liquid Funds vs. Net Worth**: Clear distinction between spendable money (cash in hand and checking/savings accounts) and total net worth (assets minus liabilities).
- **Monthly Cash Flow**: Real-time computation of monthly income, expenses, and net cash flow.
- **Rule-Based Insights**: Real-time feedback detecting spending trends, top category expenditures, deficit alerts, and bill due reminders.
- **Budget Utilization & Savings Tracking**: Interactive progress indicators displaying current limits and goal targets.

### 2. Multi-Account & Cash Management
- Supported Account Types:
  - Physical Cash Wallet
  - Savings Accounts
  - Current Accounts
  - Fixed Deposits
  - Digital Wallets
  - Credit Cards (Liabilities)
  - Foreign Currency Accounts
  - Other Financial Assets
- **Internal Account Transfers**: Moving money between accounts (e.g. Bank to Cash) updates account balances with zero artificial inflation of income or expenses.
- **Balance Reconciliation**: Ability to reconcile physical cash counts or bank statements with an audit trail.

### 3. Double-Entry Ledger & Financial Accuracy
- Monetary amounts are strictly handled in integer minor units (cents) to avoid floating-point rounding errors.
- Every transaction produces balanced accounting entries (Debits and Credits).
- Soft deletion and auditable reversals restore historical balances and transaction accuracy.

### 4. Budgets & Spending Caps
- Custom thresholds (50%, 75%, 90%, 100%) with alerts.
- Filter by specific categories or apply overall spending limits.
- Real-time remaining balance and percentage calculation.

### 5. Savings Goals
- Financial target milestones (Emergency Fund, Vehicle, Vacation, Education).
- Automated monthly contribution requirement calculations.
- Optional linked account deductions.

### 6. Debts & Loans
- Track money borrowed (Liabilities) and money lent to others (Receivables).
- Track principal repayments separate from interest charges.
- Automated status transition to 'Settled' upon zero balance.

### 7. Recurring Financial Activities
- Schedule salaries, utility bills, subscriptions, and rent across Daily, Weekly, Monthly, and Yearly intervals.
- Automatic transaction creation or prompt for confirmation.

### 8. Reports & Document Export
- Generate printable PDF Financial Statements with executive summaries, account breakdowns, and transaction logs.
- Export raw data to standard CSV spreadsheets for Microsoft Excel and Google Sheets.
- Integrated system share sheet.

### 9. Security & Privacy
- Optional Biometric Authentication (Fingerprint / Face Unlock).
- 100% offline-first local SQLite database with zero cloud requirement.
- Optional Supabase integration behind a modular abstraction.

---

## Technology Stack

- **Framework**: Flutter 3.47+ / Dart 3.13+
- **State Management**: Riverpod (`flutter_riverpod`, `NotifierProvider`)
- **Navigation**: `go_router`
- **Database**: SQLite with Drift ORM
- **Charts**: `fl_chart`
- **Security**: `local_auth`, `flutter_secure_storage`
- **Exporting**: `pdf`, `csv`, `share_plus`
- **Backend (Optional)**: `supabase_flutter`

---

## Project Structure (Clean Architecture)

```
lib/
  main.dart               # Entry point with ProviderScope
  app/
    app.dart              # MaterialApp configuration
    router/               # GoRouter routes and NavigationShell
    theme/                # Custom Material 3 fintech palette & ThemeProvider
  core/
    constants/            # Default categories, account types, currencies
    database/             # Drift schema, tables, and AppDatabase
    security/             # Biometrics and secure storage
    services/             # Notifications and optional Cloud Sync
    utils/                # FinancialCalculator, CurrencyFormatter, DateFormatter
  features/
    onboarding/           # First-launch setup flow
    dashboard/            # Financial overview and insight widgets
    transactions/         # Unified ledger transactions repository and screens
    accounts/             # Multi-account repository and cards
    categories/           # Category tree management
    budgets/              # Budget tracking repository and progress UI
    savings_goals/        # Savings milestone tracking
    debts/                # Loan and debt repayment tracking
    recurring_transactions/# Due scheduler and auto-processor
    analytics/            # Inflow/outflow bar charts and category pie charts
    reports/              # PDF and CSV generator and share repository
    settings/             # Themes, currency, financial month, cloud sync
  shared/
    providers/            # Central dependency injection providers
    widgets/              # Common cards, category icons, empty states
```

---

## Getting Started

### 1. Prerequisites
- Flutter SDK installed (`stable` channel)
- Android SDK installed (API 23+)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Database Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the Application
```bash
flutter run
```

### 5. Run Automated Tests
```bash
flutter test
```

### 6. Analyze Codebase
```bash
flutter analyze
```

---

## Optional Supabase Cloud Setup

If you wish to enable cloud synchronization:
1. Create a Supabase project at [supabase.com](https://supabase.com).
2. Execute the schema script located in `supabase_setup.sql`.
3. In the MyFinance app, navigate to **More > Settings > Supabase Cloud Integration**, input your Project URL and Anon Key, and enable Cloud Sync.
