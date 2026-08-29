import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/domain/enums.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/presentation/transactions_providers.dart';
import '../../transactions/domain/transaction_entity.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(watchTransactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
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

          for (final t in thisMonthTxs) {
            if (t.type == TransactionType.income) {
              totalIncome += t.amount;
            } else {
              totalExpense += t.amount;
              if (t.category != null) {
                final catId = t.category!.id;
                expenseByCategory[catId] = (expenseByCategory[catId] ?? 0) + t.amount;
                categoryColors[catId] = Color(t.category!.color);
                categoryNames[catId] = t.category!.name;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              Text('THIS MONTH', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white60)),
              const SizedBox(height: Spacing.sm),
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
              
              if (totalExpense > 0 && expenseByCategory.isNotEmpty) ...[
                Text('EXPENSE BREAKDOWN', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white60)),
                const SizedBox(height: Spacing.lg),
                Container(
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(Radii.lg),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: expenseByCategory.entries.map((e) {
                              return PieChartSectionData(
                                color: categoryColors[e.key] ?? Colors.grey,
                                value: e.value,
                                title: '',
                                radius: 40,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                      ...expenseByCategory.entries.map((e) {
                        final percentage = (e.value / totalExpense) * 100;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: categoryColors[e.key] ?? Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Text(categoryNames[e.key] ?? 'Unknown', style: theme.textTheme.bodyMedium),
                              const Spacer(),
                              Text(CurrencyFormatter.format(e.value), style: theme.textTheme.titleSmall),
                              const SizedBox(width: Spacing.md),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 100),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
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
}
