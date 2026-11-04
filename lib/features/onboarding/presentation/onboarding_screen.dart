import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../shared/providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Preferences
  ThemeMode _selectedTheme = ThemeMode.system;
  String _selectedCurrency = AppConstants.defaultCurrencyCode;

  // Step 2: Cash Account
  final _cashBalanceController = TextEditingController(text: '10,000');

  // Step 3: Bank Account
  final _bankNameController = TextEditingController(text: 'Commercial Bank');
  final _bankBalanceController = TextEditingController(text: '50,000');
  AccountType _bankAccountType = AccountType.savingsAccount;

  // Step 4: Monthly Budget (Optional)
  final _budgetController = TextEditingController(text: '75,000');
  bool _enableInitialBudget = true;

  @override
  void dispose() {
    _pageController.dispose();
    _cashBalanceController.dispose();
    _bankNameController.dispose();
    _bankBalanceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final budgetRepo = ref.read(budgetRepositoryProvider);

    // Save Theme & Currency
    await ref.read(themeModeProvider.notifier).setThemeMode(_selectedTheme);
    await prefs.setString(AppConstants.prefCurrencyCode, _selectedCurrency);

    // Create Cash Wallet
    final cashCents = CurrencyFormatter.parseToCents(_cashBalanceController.text) ?? 0;
    await accountRepo.createAccount(
      name: 'Cash Wallet',
      type: AccountType.cashWallet.name,
      institutionName: 'Physical Cash',
      currency: _selectedCurrency,
      openingBalanceCents: cashCents,
      openingDate: DateTime.now(),
      colorValue: 0xFF10B981,
      iconCode: 'account_balance_wallet',
    );

    // Create Primary Bank Account
    final bankName = _bankNameController.text.trim().isEmpty ? 'Primary Bank' : _bankNameController.text.trim();
    final bankCents = CurrencyFormatter.parseToCents(_bankBalanceController.text) ?? 0;
    await accountRepo.createAccount(
      name: bankName,
      type: _bankAccountType.name,
      institutionName: bankName,
      currency: _selectedCurrency,
      openingBalanceCents: bankCents,
      openingDate: DateTime.now(),
      colorValue: 0xFF3B82F6,
      iconCode: 'account_balance',
    );

    // Optionally create monthly overall budget
    if (_enableInitialBudget) {
      final budgetCents = CurrencyFormatter.parseToCents(_budgetController.text);
      if (budgetCents != null && budgetCents > 0) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        await budgetRepo.createBudget(
          name: 'Monthly Spending Budget',
          amountCents: budgetCents,
          period: 'monthly',
          startDate: start,
          endDate: end,
          warningThresholdPercent: 80,
          rollover: false,
          categoryIds: [], // Overall budget for all categories
        );
      }
    }

    // Mark Onboarding Complete
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(theme),
                  _buildCashPage(theme),
                  _buildBankPage(theme),
                  _buildBudgetPage(theme),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentPage--);
                      },
                      child: const Text('Back'),
                    )
                  else
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip Setup'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentPage++);
                      } else {
                        _completeOnboarding();
                      }
                    },
                    child: Text(_currentPage == 3 ? 'Get Started' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.account_balance_wallet, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to ${AppConstants.appName}',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Your comprehensive personal wealth management and financial intelligence hub.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Text('Theme Preference', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {_selectedTheme},
            onSelectionChanged: (set) => setState(() => _selectedTheme = set.first),
          ),
          const SizedBox(height: 24),
          Text('Base Currency', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 'LKR', child: Text('Sri Lankan Rupee (LKR / Rs.)')),
              DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD / \$)')),
              DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR / €)')),
              DropdownMenuItem(value: 'GBP', child: Text('British Pound (GBP / £)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedCurrency = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCashPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_outlined, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Physical Cash Wallet',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Track cash in hand for daily expenses, groceries, and transport.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _cashBalanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              prefixText: 'Rs. ',
              labelText: 'Current Cash Balance',
              hintText: '0.00',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_balance, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Primary Bank Account',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your main savings or salary bank account.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'Bank / Institution Name',
              hintText: 'e.g. Commercial Bank, BOC, Sampath',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AccountType>(
            initialValue: _bankAccountType,
            decoration: const InputDecoration(labelText: 'Account Type'),
            items: const [
              DropdownMenuItem(value: AccountType.savingsAccount, child: Text('Savings Account')),
              DropdownMenuItem(value: AccountType.currentAccount, child: Text('Current Account')),
              DropdownMenuItem(value: AccountType.digitalWallet, child: Text('Digital Wallet')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _bankAccountType = val);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bankBalanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              prefixText: 'Rs. ',
              labelText: 'Opening Balance',
              hintText: '0.00',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.track_changes, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Monthly Spending Target',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting a target helps you monitor spending limits and avoid financial distress.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          SwitchListTile(
            title: const Text('Set Monthly Budget Target'),
            value: _enableInitialBudget,
            onChanged: (val) => setState(() => _enableInitialBudget = val),
            contentPadding: EdgeInsets.zero,
          ),
          if (_enableInitialBudget) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                prefixText: 'Rs. ',
                labelText: 'Monthly Budget Cap',
                hintText: '75,000.00',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
