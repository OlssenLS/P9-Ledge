import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'transactions_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/icon_map.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../domain/transaction_entity.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;
  final double? initialAmount;
  final String? initialNote;
  final DateTime? initialDate;

  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.initialAmount,
    this.initialNote,
    this.initialDate,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TransactionType _selectedType;
  int? _selectedCategoryId;
  int? _selectedAccountId;
  int? _selectedToAccountId;
  late DateTime _selectedDate;
  bool _isNotesEnabled = false;

  @override
  void initState() {
    super.initState();
    final amt = widget.transaction?.amount ?? widget.initialAmount;
    _amountController = TextEditingController(
      text: amt != null ? amt.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(
      text: widget.transaction?.note ?? widget.initialNote ?? '',
    );
    _isNotesEnabled = _noteController.text.isNotEmpty;
    _selectedType = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.transaction?.categoryId;
    _selectedAccountId = widget.transaction?.accountId;
    _selectedToAccountId = widget.transaction?.toAccountId;
    _selectedDate = widget.transaction?.date ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    HapticFeedback.mediumImpact();

    if (_selectedCategoryId == null || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category and account.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final repo = ref.read(transactionsRepositoryProvider);

    if (widget.transaction == null) {
      await repo.addTransaction(
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        note: _noteController.text,
        date: _selectedDate,
      );
    } else {
      await repo.updateTransaction(
        id: widget.transaction!.id,
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId!,
        note: _noteController.text,
        date: _selectedDate,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  void _delete() async {
    HapticFeedback.heavyImpact();
    final repo = ref.read(transactionsRepositoryProvider);
    await repo.deleteTransaction(widget.transaction!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _selectedType == TransactionType.income
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _showTypePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildPickerSheet(
          title: 'Transaction Type',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.error),
                title: const Text('Expense Transaction'),
                subtitle: const Text('Money leaving your accounts (e.g., bills, food)'),
                trailing: _selectedType == TransactionType.expense 
                    ? Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.error) 
                    : Icon(Icons.radio_button_unchecked, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedType = TransactionType.expense);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.primary),
                title: const Text('Income Transaction'),
                subtitle: const Text('Money entering your accounts (e.g., salary)'),
                trailing: _selectedType == TransactionType.income 
                    ? Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.primary) 
                    : Icon(Icons.radio_button_unchecked, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedType = TransactionType.income);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final categoriesAsync = ref.watch(watchCategoriesProvider);
        return _buildPickerSheet(
          title: 'Select Category',
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const Center(child: Text('No categories available'));
              return ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];
                  return ListTile(
                    leading: Icon(IconMap.getIcon(c.icon), color: Color(c.color)),
                    title: Text(c.name),
                    trailing: _selectedCategoryId == c.id ? const Icon(Icons.check) : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedCategoryId = c.id);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }

  void _showAccountPicker({bool isDestination = false}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final accountsAsync = ref.watch(watchAccountsProvider);
        return _buildPickerSheet(
          title: 'Select Account',
          child: accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) return const Center(child: Text('No accounts available'));
              return ListView.builder(
                shrinkWrap: true,
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final a = accounts[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(a.name),
                    trailing: _selectedAccountId == a.id ? const Icon(Icons.check) : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedAccountId = a.id);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }

  Widget _buildPickerSheet({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.md),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = _selectedType == TransactionType.income ? theme.colorScheme.primary : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.transaction == null ? 'New Transaction' : 'Edit Transaction',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: Spacing.md),
              child: InkWell(
                onTap: _showTypePicker,
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedType == TransactionType.expense ? 'Expense' : 'Income',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.transaction != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction?'),
                    content: const Text('Are you sure you want to delete this transaction?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true), 
                        child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _delete();
              },
            ),
        ],
      ),
      body: Column(
        children: [

          // Massive Amount Input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xl, horizontal: Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AMOUNT', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                const SizedBox(height: Spacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('IDR ', style: theme.textTheme.headlineMedium?.copyWith(color: activeColor.withValues(alpha: 0.6))),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.left,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: activeColor,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          hintText: '0',
                          hintStyle: theme.textTheme.displayMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              children: [
                // First Card: Category, Account, Date
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Column(
                    children: [
                      if (_selectedType != TransactionType.transfer) ...[
                        _buildSelectorTile(
                          title: 'Category',
                          value: _selectedCategoryId != null 
                              ? ref.watch(watchCategoriesProvider).value?.where((c) => c.id == _selectedCategoryId).firstOrNull?.name ?? 'Select Category'
                              : 'Select Category',
                          icon: Icons.category_outlined,
                          onTap: _showCategoryPicker,
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                      ],
                      _buildSelectorTile(
                        title: _selectedType == TransactionType.transfer ? 'From Account' : 'Account',
                        value: _selectedAccountId != null 
                            ? ref.watch(watchAccountsProvider).value?.where((a) => a.id == _selectedAccountId).firstOrNull?.name ?? 'Select Account'
                            : 'Select Account',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => _showAccountPicker(isDestination: false),
                      ),
                      if (_selectedType == TransactionType.transfer) ...[
                        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                        _buildSelectorTile(
                          title: 'To Account',
                          value: _selectedToAccountId != null 
                              ? ref.watch(watchAccountsProvider).value?.where((a) => a.id == _selectedToAccountId).firstOrNull?.name ?? 'Select Account'
                              : 'Select Account',
                          icon: Icons.account_balance_wallet,
                          onTap: () => _showAccountPicker(isDestination: true),
                        ),
                      ],
                      Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                      _buildSelectorTile(
                        title: 'Date',
                        value: DateFormat.yMMMd().format(_selectedDate),
                        icon: Icons.calendar_today_outlined,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _pickDate();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                
                // Second Card: Notes
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isNotesEnabled = !_isNotesEnabled;
                            if (!_isNotesEnabled) _noteController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(Radii.md),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.notes, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60)),
                              const SizedBox(width: Spacing.md),
                              Expanded(
                                child: Text('Add Notes', style: Theme.of(context).textTheme.titleMedium),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: CupertinoSwitch(
                                  value: _isNotesEnabled,
                                  activeTrackColor: activeColor,
                                  inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                                  onChanged: (val) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _isNotesEnabled = val;
                                      if (!val) _noteController.clear();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isNotesEnabled) ...[
                        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                          child: TextField(
                            controller: _noteController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter transaction note...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 100), // padding for bottom button
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: _selectedType == TransactionType.income ? Colors.black : Theme.of(context).colorScheme.onSurface,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
            ),
            child: Text(
              widget.transaction == null ? 'Confirm Transaction' : 'Save Changes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60)),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
          ],
        ),
      ),
    );
  }
}
