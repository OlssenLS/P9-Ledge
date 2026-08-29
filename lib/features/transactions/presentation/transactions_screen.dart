import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import 'transactions_providers.dart';
import 'transaction_form_screen.dart';
import '../data/receipt_scanner_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_map.dart';
import '../domain/transaction_entity.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/design_tokens.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _isScanning = false;

  Future<void> _showAddOptions() async {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
          ),
          padding: Insets.bottomSheet,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Text(
                  'Add Transaction',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.lg),
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  title: 'Manual Entry',
                  subtitle: 'Enter transaction details yourself',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const TransactionFormScreen(),
                    ));
                  },
                ),
                const SizedBox(height: Spacing.md),
                _buildOptionTile(
                  icon: Icons.document_scanner_outlined,
                  title: 'Scan Receipt',
                  subtitle: 'Offline ML Kit extraction',
                  onTap: () {
                    Navigator.pop(context);
                    _handleScanReceipt();
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScanReceipt() async {
    final scanner = ref.read(receiptScannerProvider);

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() => _isScanning = true);
    
    try {
      final receipt = await scanner.scanReceipt(File(xfile.path));
      if (receipt != null && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => TransactionFormScreen(
            initialAmount: receipt.amount,
            initialNote: receipt.note,
            initialDate: receipt.date,
          ),
        ));
      } else if (mounted) {
        _showError('Could not find amount/date in the receipt.');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        margin: const EdgeInsets.all(Spacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(watchTransactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Transactions'),
            pinned: true,
            floating: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, Spacing.md),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).setQuery(val);
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Stack(
              children: [
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white24),
                              const SizedBox(height: Spacing.md),
                              Text(
                                'No transactions yet',
                                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white60),
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                'Scan a receipt or add one manually.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn();
                    }

                    final Map<DateTime, List<TransactionEntity>> grouped = {};
                    for (final t in transactions) {
                      final date = DateTime(t.date.year, t.date.month, t.date.day);
                      grouped.putIfAbsent(date, () => []).add(t);
                    }

                    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.lg, Spacing.md, Spacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat.yMMMd().format(date),
                                    style: theme.textTheme.titleSmall?.copyWith(color: Colors.white60),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(dailyTotal),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: dailyTotal >= 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...dailyTransactions.map((t) => _buildTransactionItem(t, theme)),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => _buildSkeletonLoader(),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                if (_isScanning)
                  Positioned.fill(
                    child: Container(
                      color: theme.scaffoldBackgroundColor.withOpacity(0.8),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(Spacing.xl),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(Radii.lg),
                            boxShadow: [
                              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: theme.colorScheme.primary),
                              const SizedBox(height: Spacing.lg),
                              Text('Extracting data...', style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms),
                  ),
              ],
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

  Widget _buildTransactionItem(TransactionEntity t, ThemeData theme) {
    final isIncome = t.type == TransactionType.income;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => TransactionFormScreen(transaction: t),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        child: Row(
          children: [
            Hero(
              tag: 'transaction-icon-${t.id}',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: t.category != null ? Color(t.category!.color).withOpacity(0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(
                  t.category != null ? IconMap.getIcon(t.category!.icon) : Icons.receipt,
                  color: t.category != null ? Color(t.category!.color) : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.category?.name ?? 'Unknown',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (t.note != null && t.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.note!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(t.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isIncome ? theme.colorScheme.primary : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 60, height: 16, color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }
}
