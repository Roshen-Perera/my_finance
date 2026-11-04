import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/category_icon.dart';
import '../domain/analytics_models.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _timeRange = 'this_month'; // 'this_week', 'this_month', 'last_month', 'last_3_months', 'this_year'
  int _touchedPieIndex = -1;

  ({DateTime start, DateTime end}) _getRange() {
    final now = DateTime.now();
    switch (_timeRange) {
      case 'this_week':
        return DateFormatter.getWeekRange(now);
      case 'last_month':
        return DateFormatter.getMonthRange(DateTime(now.year, now.month - 1, 1));
      case 'last_3_months':
        final start = DateTime(now.year, now.month - 2, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return (start: start, end: end);
      case 'this_year':
        return DateFormatter.getYearRange(now);
      case 'this_month':
      default:
        return DateFormatter.getMonthRange(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = _getRange();
    final analyticsRepo = ref.watch(analyticsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Range Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRangeChip('This Month', 'this_month'),
                const SizedBox(width: 8),
                _buildRangeChip('This Week', 'this_week'),
                const SizedBox(width: 8),
                _buildRangeChip('Last Month', 'last_month'),
                const SizedBox(width: 8),
                _buildRangeChip('Last 3 Months', 'last_3_months'),
                const SizedBox(width: 8),
                _buildRangeChip('This Year', 'this_year'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Inflows vs Outflows Bar Chart
          FutureBuilder<List<MonthlyTrendPoint>>(
            future: analyticsRepo.getMonthlyTrend(monthsBack: 6),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
              }
              final data = snapshot.data ?? [];
              if (data.isEmpty) return const SizedBox();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Income vs Expenses (6 Months)', style: theme.textTheme.titleMedium),
                          Row(
                            children: [
                              _buildLegend(AppColors.income, 'Income'),
                              const SizedBox(width: 10),
                              _buildLegend(AppColors.expense, 'Expense'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final index = val.toInt();
                                    if (index >= 0 && index < data.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(data[index].monthLabel, style: const TextStyle(fontSize: 11)),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            barGroups: List.generate(data.length, (i) {
                              final pt = data[i];
                              final incVal = pt.incomeCents / 100000.0;
                              final expVal = pt.expenseCents / 100000.0;

                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: incVal,
                                    color: AppColors.income,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  BarChartRodData(
                                    toY: expVal,
                                    color: AppColors.expense,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Expense Categories Breakdown (Pie Chart & List)
          FutureBuilder<List<CategorySpending>>(
            future: analyticsRepo.getCategorySpendingBreakdown(range.start, range.end),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No expense data recorded in this period.')),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spending by Category', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: List.generate(list.length, (i) {
                              final item = list[i];
                              final isTouched = i == _touchedPieIndex;
                              final radius = isTouched ? 50.0 : 42.0;

                              return PieChartSectionData(
                                color: Color(item.colorValue),
                                value: item.amountCents.toDouble(),
                                title: '${item.percentage.toStringAsFixed(0)}%',
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: isTouched ? 14 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Ranked Category List
                      ...list.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CategoryIcon(
                                iconCode: cat.iconCode,
                                colorValue: cat.colorValue,
                                size: 16,
                                padding: 8,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('${cat.percentage.toStringAsFixed(1)}% of total', style: theme.textTheme.labelSmall),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatCents(cat.amountCents),
                                style: AppTypography.amountStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRangeChip(String label, String value) {
    final isSelected = _timeRange == value;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _timeRange = value),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
    );
  }
}
