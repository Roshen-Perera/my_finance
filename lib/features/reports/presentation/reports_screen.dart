import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportsRepo = ref.watch(reportsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Exports', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Range Configuration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Report Period', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _startDate = picked);
                            }
                          },
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text('From: ${DateFormatter.formatDate(_startDate)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _endDate = picked);
                            }
                          },
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text('To: ${DateFormatter.formatDate(_endDate)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // PDF Financial Statement Export Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PDF Financial Statement', style: theme.textTheme.titleMedium),
                            Text(
                              'Formal executive summary with balances and audit logs',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isGenerating
                        ? null
                        : () async {
                            setState(() => _isGenerating = true);
                            try {
                              final path = await reportsRepo.exportFinancialReportPdf(
                                title: 'Financial Statement',
                                startDate: _startDate,
                                endDate: _endDate,
                              );
                              await reportsRepo.shareReport(path, 'MyFinance Statement');
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Export failed: $e')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isGenerating = false);
                            }
                          },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Generate & Share PDF'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // CSV Raw Data Export Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.table_chart, color: AppColors.income, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CSV Spreadsheet Export', style: theme.textTheme.titleMedium),
                            Text(
                              'Raw transactions compatible with Microsoft Excel & Google Sheets',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isGenerating
                        ? null
                        : () async {
                            setState(() => _isGenerating = true);
                            try {
                              final path = await reportsRepo.exportTransactionsCsv(
                                startDate: _startDate,
                                endDate: _endDate,
                              );
                              await reportsRepo.shareReport(path, 'MyFinance CSV Data');
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Export failed: $e')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isGenerating = false);
                            }
                          },
                    icon: const Icon(Icons.table_view, size: 18),
                    label: const Text('Export & Share CSV'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
