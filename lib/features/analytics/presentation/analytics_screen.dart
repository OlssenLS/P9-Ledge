import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/domain/enums.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../../transactions/domain/transaction_entity.dart';

enum ChartType { pie, bar, line }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  ChartType _selectedChart = ChartType.pie;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(watchTransactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('ANALYTICS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white38)),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Text(
                'No data available.',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white38),
              ),
            );
          }

          // Compute this month's stats
          final now = DateTime.now();
          final thisMonthTxs = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();

          double totalIncome = 0;
          double totalExpense = 0;
          final Map<int, double> expenseByCategory = {};
          final Map<int, Color> categoryColors = {};
          final Map<int, String> categoryNames = {};
          
          final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          List<double> dailyExpenses = List.filled(daysInMonth, 0.0);
          double largestTx = 0.0;

          for (final t in thisMonthTxs) {
            if (t.type == TransactionType.income) {
              totalIncome += t.amount;
            } else {
              totalExpense += t.amount;
              dailyExpenses[t.date.day - 1] += t.amount;
              if (t.amount > largestTx) largestTx = t.amount;
              
              if (t.category != null) {
                final catId = t.category!.id;
                expenseByCategory[catId] = (expenseByCategory[catId] ?? 0) + t.amount;
                categoryColors[catId] = Color(t.category!.color);
                categoryNames[catId] = t.category!.name;
              }
            }
          }
          
          // Insights
          String topCategory = 'None';
          double topCatValue = 0;
          expenseByCategory.forEach((key, value) {
            if (value > topCatValue) {
              topCatValue = value;
              topCategory = categoryNames[key] ?? 'Unknown';
            }
          });
          
          final double avgDailySpend = totalExpense / max(1, now.day);
          final double maxDailySpend = dailyExpenses.reduce(max);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(Spacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Total Summary
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Income',
                            amount: totalIncome,
                            color: theme.colorScheme.primary,
                            icon: Icons.arrow_downward,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            title: 'Expense',
                            amount: totalExpense,
                            color: theme.colorScheme.error,
                            icon: Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xxl),

                    // Chart Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SPENDING TRENDS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white60)),
                        _buildChartTypeSelector(theme),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    
                    // Chart Display
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(Radii.lg),
                      ),
                      child: _buildSelectedChart(
                        theme: theme, 
                        expenseByCategory: expenseByCategory, 
                        categoryColors: categoryColors, 
                        dailyExpenses: dailyExpenses,
                        maxDailySpend: maxDailySpend,
                      ),
                    ),
                    
                    const SizedBox(height: Spacing.xxl),
                    Text('KEY INSIGHTS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white60)),
                    const SizedBox(height: Spacing.md),
                    
                    // Key Insights Cards
                    Row(
                      children: [
                        Expanded(child: _buildInsightCard(context, 'Top Category', topCategory, Icons.star, Colors.orangeAccent)),
                        const SizedBox(width: Spacing.md),
                        Expanded(child: _buildInsightCard(context, 'Daily Avg', CurrencyFormatter.format(avgDailySpend), Icons.analytics_outlined, Colors.purpleAccent)),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(child: _buildInsightCard(context, 'Largest Tx', CurrencyFormatter.format(largestTx), Icons.shopping_bag_outlined, Colors.blueAccent)),
                        const SizedBox(width: Spacing.md),
                        Expanded(child: _buildInsightCard(context, 'Active Days', '${dailyExpenses.where((d) => d > 0).length} Days', Icons.calendar_today, Colors.greenAccent)),
                      ],
                    ),
                    
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
  
  Widget _buildChartTypeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartIcon(ChartType.pie, Icons.pie_chart, theme),
          _buildChartIcon(ChartType.bar, Icons.bar_chart, theme),
          _buildChartIcon(ChartType.line, Icons.show_chart, theme),
        ],
      ),
    );
  }
  
  Widget _buildChartIcon(ChartType type, IconData icon, ThemeData theme) {
    final isSelected = _selectedChart == type;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedChart = type);
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(icon, size: 18, color: isSelected ? theme.colorScheme.primary : Colors.white38),
      ),
    );
  }

  Widget _buildSelectedChart({
    required ThemeData theme,
    required Map<int, double> expenseByCategory,
    required Map<int, Color> categoryColors,
    required List<double> dailyExpenses,
    required double maxDailySpend,
  }) {
    if (_selectedChart == ChartType.pie) {
      if (expenseByCategory.isEmpty) return const Center(child: Text('No category data', style: TextStyle(color: Colors.white38)));
      return PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: expenseByCategory.entries.map((e) {
            return PieChartSectionData(
              color: categoryColors[e.key] ?? Colors.grey,
              value: e.value,
              title: '',
              radius: 30,
            );
          }).toList(),
        ),
      );
    } else if (_selectedChart == ChartType.bar) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxDailySpend * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 5 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  );
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: dailyExpenses.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key + 1,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: theme.colorScheme.error,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      );
    } else {
      // Line Chart
      final spots = dailyExpenses.asMap().entries.map((e) => FlSpot((e.key + 1).toDouble(), e.value)).toList();
      return LineChart(
        LineChartData(
          minY: 0,
          maxY: maxDailySpend * 1.2,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 5 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  );
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.colorScheme.secondary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required double amount, required Color color, required IconData icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            CurrencyFormatter.format(amount),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightCard(BuildContext context, String title, String value, IconData icon, Color iconColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
