import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _supabaseUrlController = TextEditingController();
  final _supabaseKeyController = TextEditingController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final syncService = ref.read(syncServiceProvider);
    _supabaseUrlController.text = syncService.supabaseUrl ?? '';
    _supabaseKeyController.text = syncService.supabaseAnonKey ?? '';
  }

  @override
  void dispose() {
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    super.dispose();
  }

  void _showCloudSyncDialog(BuildContext context) {
    final syncService = ref.read(syncServiceProvider);
    bool enabled = syncService.isCloudSyncEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Supabase Cloud Sync (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Your data remains 100% functional offline on this device. When configured, your records synchronize with your private Supabase database.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Cloud Sync'),
                      value: enabled,
                      onChanged: (val) => setDialogState(() => enabled = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _supabaseUrlController,
                      decoration: const InputDecoration(labelText: 'Supabase Project URL', hintText: 'https://xyz.supabase.co'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _supabaseKeyController,
                      decoration: const InputDecoration(labelText: 'Supabase Anon Key', hintText: 'eyJhbGciOi...'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await syncService.configureSupabase(
                          url: _supabaseUrlController.text.trim(),
                          anonKey: _supabaseKeyController.text.trim(),
                          enableSync: enabled,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cloud sync configuration saved')),
                          );
                        }
                      },
                      child: const Text('Save Configuration'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final securityService = ref.watch(securityServiceProvider);
    final syncService = ref.watch(syncServiceProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    final currency = prefs.getString(AppConstants.prefCurrencyCode) ?? AppConstants.defaultCurrencyCode;
    final financialStartDay = prefs.getInt(AppConstants.prefFinancialMonthStartDay) ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Appearance
          _buildSectionHeader('Appearance & Theme'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (set) => ref.read(themeModeProvider.notifier).setThemeMode(set.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial Preferences
          _buildSectionHeader('Financial Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Base Currency'),
                  subtitle: Text('$currency (Default for accounts and calculations)'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Select Base Currency'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () {
                              prefs.setString(AppConstants.prefCurrencyCode, 'LKR');
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                            child: const Text('Sri Lankan Rupee (LKR / Rs.)'),
                          ),
                          SimpleDialogOption(
                            onPressed: () {
                              prefs.setString(AppConstants.prefCurrencyCode, 'USD');
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                            child: const Text('US Dollar (USD / \$)'),
                          ),
                          SimpleDialogOption(
                            onPressed: () {
                              prefs.setString(AppConstants.prefCurrencyCode, 'EUR');
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                            child: const Text('Euro (EUR / €)'),
                          ),
                          SimpleDialogOption(
                            onPressed: () {
                              prefs.setString(AppConstants.prefCurrencyCode, 'GBP');
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                            child: const Text('British Pound (GBP / £)'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Financial Month Start Day'),
                  subtitle: Text('Day $financialStartDay of each month (e.g. Salary day)'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Start Day of Month'),
                        children: [1, 5, 10, 15, 20, 25, 28].map((day) {
                          return SimpleDialogOption(
                            onPressed: () {
                              prefs.setInt(AppConstants.prefFinancialMonthStartDay, day);
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                            child: Text('Day $day of each month'),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security & Privacy
          _buildSectionHeader('Security & Protection'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Require fingerprint or face unlock to open app'),
                  value: securityService.isBiometricEnabled,
                  onChanged: (val) async {
                    if (val) {
                      final canAuth = await securityService.canCheckBiometrics();
                      if (!canAuth) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometrics not available on this device')),
                          );
                        }
                        return;
                      }
                      final authenticated = await securityService.authenticateBiometric();
                      if (authenticated) {
                        await securityService.setBiometricEnabled(true);
                        setState(() {});
                      }
                    } else {
                      await securityService.setBiometricEnabled(false);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cloud Sync (Supabase)
          _buildSectionHeader('Cloud Backup & Sync'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Supabase Cloud Integration'),
                  subtitle: Text(
                    syncService.isConfigured && syncService.isCloudSyncEnabled
                        ? 'Configured & Active'
                        : 'Offline Only (Configurable)',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showCloudSyncDialog(context),
                ),
                if (syncService.isConfigured && syncService.isCloudSyncEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sync Now'),
                    subtitle: const Text('Upload pending transactions to Supabase'),
                    trailing: _isSyncing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    onTap: _isSyncing
                        ? null
                        : () async {
                            setState(() => _isSyncing = true);
                            final res = await syncService.syncNow();
                            setState(() => _isSyncing = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res.message)),
                              );
                            }
                          },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About
          _buildSectionHeader('About MyFinance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Application Version'),
                  subtitle: const Text('1.0.0 (Production Release)'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Data Privacy'),
                  subtitle: const Text('All financial records are stored securely in local SQLite on this device.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8),
      ),
    );
  }
}
