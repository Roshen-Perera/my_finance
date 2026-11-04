import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../app/theme/theme_provider.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/more/presentation/more_screen.dart';

import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/savings_goals/presentation/savings_goals_screen.dart';
import '../../features/debts/presentation/debts_screen.dart';
import '../../features/recurring_transactions/presentation/recurring_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'main_navigation_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isOnboardingDone = prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
      final goingToOnboarding = state.matchedLocation == '/onboarding';

      if (!isOnboardingDone && !goingToOnboarding) {
        return '/onboarding';
      }
      if (isOnboardingDone && goingToOnboarding) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: '/accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MoreScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/savings',
        builder: (context, state) => const SavingsGoalsScreen(),
      ),
      GoRoute(
        path: '/debts',
        builder: (context, state) => const DebtsScreen(),
      ),
      GoRoute(
        path: '/recurring',
        builder: (context, state) => const RecurringScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
