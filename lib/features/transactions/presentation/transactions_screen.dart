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
import '../../categories/presentation/categories_providers.dart';
import '../../categories/presentation/category_form_screen.dart';
import '../domain/transaction_entity.dart';
import 'transactions_providers.dart';
import 'transaction_form_screen.dart';
import '../data/receipt_scanner_service.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> with TickerProviderStateMixin {
  int? _selectedAccountId;
  int _selectedCategoryIndex = 0;
  TabController? _tabController;
  bool _isScanning = false;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

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
                const SizedBox(height: Spacing.xl),
                Text(
                  'Select Account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.lg),
                _buildAccountOptionTile(null, 'All Accounts', null),
                ...accounts.map((acc) => _buildAccountOptionTile(acc.id, acc.name, acc.type)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountOptionTile(int? accountId, String name, AccountType? type) {
    IconData icon = Icons.work_outline;
    Color color = Theme.of(context).colorScheme.primary;

    if (type != null) {
      switch (type) {
        case AccountType.cash:
          icon = Icons.payments_outlined;
          color = Theme.of(context).colorScheme.primary;
          break;
        case AccountType.bank:
          icon = Icons.account_balance_outlined;
          color = Colors.white;
          break;
        case AccountType.eWallet:
          icon = Icons.account_balance_wallet_outlined;
          color = Theme.of(context).colorScheme.secondary;
          break;
        case AccountType.rdn:
          icon = Icons.trending_up;
          color = Colors.purpleAccent;
          break;
      }
    }

    final isSelected = _selectedAccountId == accountId;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedAccountId = accountId);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? color : Colors.white12),
            borderRadius: BorderRadius.circular(Radii.md),
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: Spacing.md),
              Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle, color: color),
            ],
          ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(watchTransactionsProvider);
    final accountsAsync = ref.watch(watchAccountsProvider);
    final categoriesAsync = ref.watch(watchCategoriesProvider);

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

    double totalSpent = 0.0;
    double totalIncomeAmount = 0.0;
    int expenseCount = 0;
    int incomeCount = 0;

    if (transactionsAsync.hasValue) {
      final allTransactions = transactionsAsync.value!;
      var transactions = _selectedAccountId == null 
          ? allTransactions 
          : allTransactions.where((t) => t.accountId == _selectedAccountId).toList();
          
      if (_selectedCategoryIndex > 0 && categoriesAsync.hasValue) {
        final categories = categoriesAsync.value!;
        if (_selectedCategoryIndex - 1 < categories.length) {
          final catId = categories[_selectedCategoryIndex - 1].id;
          transactions = transactions.where((t) => t.categoryId == catId).toList();
        }
      }
      
      for (final t in transactions) {
        if (t.type == TransactionType.expense) {
          totalSpent += t.amount;
          expenseCount++;
        } else {
          totalIncomeAmount += t.amount;
          incomeCount++;
        }
      }
    }

    final avgSpend = expenseCount > 0 ? totalSpent / expenseCount : 0.0;
    final avgIncome = incomeCount > 0 ? totalIncomeAmount / incomeCount : 0.0;

    return Stack(
      children: [
        Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                centerTitle: false,
                floating: true,
                pinned: true,
                actions: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: Spacing.md),
                      child: InkWell(
                        onTap: () => _showAccountPicker(allAccounts),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_outline, size: 14, color: Colors.white60),
                              const SizedBox(width: 6),
                              Text(
                                _selectedAccountId == null ? 'ALL' : accountName.toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Section 1: Total Balance and Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xl, horizontal: Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(theme, 'Overview'),
                      const SizedBox(height: Spacing.md),
                      Text(
                        CurrencyFormatter.format(totalBalance),
                        style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: Spacing.xl),
                      Row(
                        children: [
                          Expanded(child: _buildMiniStat(theme, 'Total Spent', totalSpent, theme.colorScheme.error)),
                          const SizedBox(width: Spacing.sm),
                          Expanded(child: _buildMiniStat(theme, 'Avg Spend', avgSpend, theme.colorScheme.error)),
                          const SizedBox(width: Spacing.sm),
                          Expanded(child: _buildMiniStat(theme, 'Avg Income', avgIncome, theme.colorScheme.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Section Divider
              const SliverToBoxAdapter(child: Divider(height: 16, color: Colors.white10, thickness: 0.5)),

              // Section 2: Quick Features
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                        child: _buildSectionHeader(theme, 'Quick Actions'),
                      ),
                      const SizedBox(height: Spacing.md),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                        child: Row(
                          children: [
                            _buildFeatureBtn(
                              icon: Icons.document_scanner,
                              label: 'Scan',
                              color: theme.colorScheme.primary,
                              onTap: _handleScanReceipt,
                            ),
                            const SizedBox(width: Spacing.md),
                            _buildFeatureBtn(
                              icon: Icons.mic_none,
                              label: 'Mic Input',
                              color: Colors.purple,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mic Input coming soon')));
                              },
                            ),
                            const SizedBox(width: Spacing.md),
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
                            const SizedBox(width: Spacing.md),
                            _buildFeatureBtn(
                              icon: Icons.mail_outline,
                              label: 'Gmail Sync',
                              color: Colors.redAccent,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gmail Sync coming soon')));
                              },
                            ),
                            const SizedBox(width: Spacing.md),
                            _buildFeatureBtn(
                              icon: Icons.swap_horiz,
                              label: 'Transfer',
                              color: Colors.blue,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer coming soon')));
                              },
                            ),
                            const SizedBox(width: Spacing.md),
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
                    ],
                  ),
                ),
              ),
              
              // Section Divider
              const SliverToBoxAdapter(child: Divider(height: 16, color: Colors.white10, thickness: 0.5)),
              
              // Section 3: Transaction Logs Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
                  child: _buildSectionHeader(theme, 'Transaction Log'),
                ),
              ),
              
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                  child: TextField(
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      hintText: 'Search journal...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(right: Spacing.sm),
                        child: Icon(Icons.search, color: Colors.white38, size: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    ),
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                    },
                  ),
                ),
              ),

              // Category Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.lg),
                  child: Builder(
                    builder: (context) {
                      final categories = categoriesAsync.value ?? [];
                      final tabCount = categories.length + 2; // 'All' + categories + '+'
                      
                      if (_tabController == null || _tabController!.length != tabCount) {
                        _tabController?.dispose();
                        _tabController = TabController(length: tabCount, vsync: this, initialIndex: _selectedCategoryIndex);
                      }

                      return TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorColor: theme.colorScheme.primary,
                        indicatorWeight: 2,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                        labelPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                        onTap: (index) {
                          if (index == tabCount - 1) {
                            // Plus button tapped
                            _tabController!.index = _selectedCategoryIndex; // Revert
                            HapticFeedback.mediumImpact();
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => const CategoryFormScreen(),
                            ));
                            return;
                          }
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        tabs: [
                          const Tab(height: 32, text: 'All'),
                          ...categories.map((c) => Tab(height: 32, text: c.name)),
                          Tab(
                            height: 32,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(color: Colors.white12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white60, size: 16),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Section 3: Transactions List
              SliverToBoxAdapter(
                child: transactionsAsync.when(
                  data: (allTransactions) {
                    var transactions = _selectedAccountId == null 
                        ? allTransactions 
                        : allTransactions.where((t) => t.accountId == _selectedAccountId).toList();
                        
                    if (_selectedCategoryIndex > 0 && categoriesAsync.hasValue) {
                      final categories = categoriesAsync.value!;
                      if (_selectedCategoryIndex - 1 < categories.length) {
                        final catId = categories[_selectedCategoryIndex - 1].id;
                        transactions = transactions.where((t) => t.categoryId == catId).toList();
                      }
                    }

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
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
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

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            CurrencyFormatter.format(amount),
            style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
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
