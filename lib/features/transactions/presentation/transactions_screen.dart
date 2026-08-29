import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'transactions_providers.dart';
import 'transaction_form_screen.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_map.dart';
import '../domain/transaction_entity.dart';
import '../../../core/domain/enums.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(watchTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                ref.read(searchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          // Group by date (ignoring time)
          final Map<DateTime, List<TransactionEntity>> grouped = {};
          for (final t in transactions) {
            final date = DateTime(t.date.year, t.date.month, t.date.day);
            grouped.putIfAbsent(date, () => []).add(t);
          }

          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dailyTransactions = grouped[date]!;
              final dailyTotal = dailyTransactions.fold<double>(0, (sum, t) {
                return t.type == TransactionType.income ? sum + t.amount : sum - t.amount;
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[200],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat.yMMMd().format(date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            CurrencyFormatter.format(dailyTotal),
                            key: ValueKey(dailyTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dailyTotal >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...dailyTransactions.map((t) {
                    final isIncome = t.type == TransactionType.income;
                    return ListTile(
                      leading: Hero(
                        tag: 'transaction-icon-${t.id}',
                        child: CircleAvatar(
                          backgroundColor: t.category != null ? Color(t.category!.color) : Colors.grey,
                          child: Icon(
                            t.category != null ? IconMap.getIcon(t.category!.icon) : Icons.category,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(t.category?.name ?? 'Unknown Category'),
                      subtitle: Text('${t.account?.name ?? 'Unknown'} ${t.note != null && t.note!.isNotEmpty ? " - ${t.note}" : ""}'),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${CurrencyFormatter.format(t.amount)}',
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => TransactionFormScreen(transaction: t),
                        ));
                      },
                    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const TransactionFormScreen(),
          ));
        },
      ),
    );
  }
}
