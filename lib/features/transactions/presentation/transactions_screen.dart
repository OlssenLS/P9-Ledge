import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'transactions_providers.dart';
import 'transaction_form_screen.dart';
import '../data/receipt_scanner_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_map.dart';
import '../domain/transaction_entity.dart';
import '../../../core/domain/enums.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _isScanning = false;

  Future<void> _showAddOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Manual Entry'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const TransactionFormScreen(),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner),
                title: const Text('Scan Receipt'),
                onTap: () {
                  Navigator.pop(context);
                  _handleScanReceipt();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _handleScanReceipt() async {
    final scanner = ref.read(receiptScannerProvider);
    String? apiKey = await scanner.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      apiKey = await _promptForApiKey();
      if (apiKey == null || apiKey.isEmpty) return; // User cancelled
      await scanner.saveApiKey(apiKey);
    }

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() => _isScanning = true);
    
    try {
      final receipt = await scanner.scanReceipt(File(xfile.path), apiKey);
      if (receipt != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => TransactionFormScreen(
            initialAmount: receipt.amount,
            initialNote: receipt.note,
            initialDate: receipt.date,
          ),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to parse receipt or no data found.')),
        );
      }
    } catch (e) {
      // Clear the API key if it fails, in case it was a bad key
      await scanner.saveApiKey('');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Scanner Error'),
            content: SingleChildScrollView(
              child: Text(e.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<String?> _promptForApiKey() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('To use the AI Receipt Scanner, please enter your Gemini API Key.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'API Key'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              ),
              onChanged: (val) {
                ref.read(searchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(child: Text('No transactions found.'));
              }

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
                        color: Theme.of(context).colorScheme.surface,
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
          if (_isScanning)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning receipt with AI...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }
}
