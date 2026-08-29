import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/domain/enums.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_map.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../domain/transaction_entity.dart';
import 'transactions_providers.dart';
import 'transaction_form_screen.dart';
import '../data/receipt_scanner_service.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int? _selectedAccountId;
  bool _isScanning = false;

  void _showAccountPicker(List<AccountEntity> accounts) {
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
                const SizedBox(height: Spacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Text('Select Account', style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: Spacing.md),
                ListTile(
                  title: const Text('All Accounts'),
                  trailing: _selectedAccountId == null ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedAccountId = null);
                    Navigator.pop(context);
                  },
                ),
                ...accounts.map((acc) => ListTile(
                  title: Text(acc.name),
                  trailing: _selectedAccountId == acc.id ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedAccountId = acc.id);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(watchTransactionsProvider);
    final accountsAsync = ref.watch(watchAccountsProvider);

    double totalBalance = 0.0;
    String accountName = 'All Accounts';
    List<AccountEntity> allAccounts = [];

    if (accountsAsync.hasValue) {
      allAccounts = accountsAsync.value!;
      if (_selectedAccountId == null) {
        totalBalance = allAccounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
      } else {
        final acc = allAccounts.where((a) => a.id == _selectedAccountId).firstOrNull;
        if (acc != null) {
          totalBalance = acc.currentBalance;
          accountName = acc.name;
        }
      }
    }

    return Stack(
      children: [
        Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('Journal', style: TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: false,
                floating: true,
                pinned: true,
              ),
              
              // Section 1: Total Balance
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xl, horizontal: Spacing.md),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showAccountPicker(allAccounts),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(accountName, style: theme.textTheme.titleSmall?.copyWith(color: Colors.white70)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        CurrencyFormatter.format(totalBalance),
                        style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Section 2: Quick Features
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureBtn(
                        icon: Icons.document_scanner,
                        label: 'Scan',
                        color: theme.colorScheme.primary,
                        onTap: _handleScanReceipt,
                      ),
                      _buildFeatureBtn(
                        icon: Icons.edit,
                        label: 'Manual',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const TransactionFormScreen(),
                          ));
                        },
                      ),
                      _buildFeatureBtn(
                        icon: Icons.swap_horiz,
                        label: 'Transfer',
                        color: Colors.blue,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer coming soon')));
                        },
                      ),
                      _buildFeatureBtn(
                        icon: Icons.file_download_outlined,
                        label: 'Export',
                        color: Colors.green,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export coming soon')));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Section 3: Transaction Logs Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xxl, Spacing.md, Spacing.sm),
                  child: Text('TRANSACTION LOG', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white60)),
                ),
              ),
              
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search journal...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val);
                      },
                    ),
                  ),
                ),
              ),

              // Section 3: Transactions List
              SliverToBoxAdapter(
                child: transactionsAsync.when(
                  data: (allTransactions) {
                    // Filter by selected account
                    final transactions = _selectedAccountId == null 
                        ? allTransactions 
                        : allTransactions.where((t) => t.accountId == _selectedAccountId).toList();

                    if (transactions.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
                              const SizedBox(height: Spacing.md),
                              Text(
                                'No entries found',
                                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white60),
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
                            ...dailyTransactions.map((t) => _buildTransactionItem(context, t, theme)),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => _buildSkeletonLoader(),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
        
        // Scanning Overlay
        if (_isScanning)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(Spacing.xl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: Spacing.lg),
                      Text('Extracting receipt...', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: Spacing.sm),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionEntity t, ThemeData theme) {
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
                  color: t.category != null ? Color(t.category!.color).withValues(alpha: 0.15) : Colors.white10,
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
