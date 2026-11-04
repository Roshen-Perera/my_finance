import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Hub', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildHubTile(
            context,
            icon: Icons.track_changes,
            iconColor: AppColors.primary,
            title: 'Budgets & Limits',
            subtitle: 'Monitor category spending limits and threshold alerts',
            route: '/budgets',
          ),
          _buildHubTile(
            context,
            icon: Icons.savings_outlined,
            iconColor: AppColors.savings,
            title: 'Savings Goals',
            subtitle: 'Track emergency funds, vehicle, education, and targets',
            route: '/savings',
          ),
          _buildHubTile(
            context,
            icon: Icons.account_balance_outlined,
            iconColor: AppColors.warning,
            title: 'Debts & Loans',
            subtitle: 'Manage money lent to others and loans borrowed',
            route: '/debts',
          ),
          _buildHubTile(
            context,
            icon: Icons.repeat,
            iconColor: AppColors.transfer,
            title: 'Recurring Activities',
            subtitle: 'Automate salary, subscriptions, utilities, and due dates',
            route: '/recurring',
          ),
          _buildHubTile(
            context,
            icon: Icons.picture_as_pdf_outlined,
            iconColor: Colors.deepPurple,
            title: 'Reports & Export',
            subtitle: 'Generate professional PDF statements and CSV data exports',
            route: '/reports',
          ),
          _buildHubTile(
            context,
            icon: Icons.category_outlined,
            iconColor: Colors.indigo,
            title: 'Categories & Subcategories',
            subtitle: 'Customize income and expense classification',
            route: '/categories',
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildHubTile(
            context,
            icon: Icons.settings_outlined,
            iconColor: theme.colorScheme.onSurface,
            title: 'Settings & Security',
            subtitle: 'Themes, Biometrics, Currency, and optional Cloud Sync',
            route: '/settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () => context.push(route),
      ),
    );
  }
}
