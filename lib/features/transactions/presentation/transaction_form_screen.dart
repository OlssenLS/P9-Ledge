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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TransactionType _selectedType;
  int? _selectedCategoryId;
  int? _selectedAccountId;
  late DateTime _selectedDate;

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
    _selectedType = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.transaction?.categoryId;
    _selectedAccountId = widget.transaction?.accountId;
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
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null || _selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a category and account.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final repo = ref.read(transactionsRepositoryProvider);
      final amount = double.tryParse(_amountController.text) ?? 0.0;

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
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(watchCategoriesProvider);
    final accountsAsync = ref.watch(watchAccountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New Transaction' : 'Edit Transaction'),
        actions: [
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: Insets.screen,
          children: [
            if (widget.transaction != null)
              Center(
                child: Hero(
                  tag: 'transaction-icon-${widget.transaction!.id}',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.transaction!.category != null 
                          ? Color(widget.transaction!.category!.color).withOpacity(0.15) 
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    child: Icon(
                      widget.transaction!.category != null 
                          ? IconMap.getIcon(widget.transaction!.category!.icon) 
                          : Icons.receipt,
                      color: widget.transaction!.category != null 
                          ? Color(widget.transaction!.category!.color) 
                          : Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            if (widget.transaction != null) const SizedBox(height: Spacing.xl),
            
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                HapticFeedback.selectionClick();
                setState(() => _selectedType = set.first);
              },
              style: ButtonStyle(
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md))),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: _selectedType == TransactionType.income ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
              validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid amount' : null,
            ),
            const SizedBox(height: Spacing.lg),
            
            categoriesAsync.when(
              data: (categories) {
                if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
                  _selectedCategoryId = null;
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories.map((c) {
                    return DropdownMenuItem(
                      value: c.id, 
                      child: Row(
                        children: [
                          Icon(IconMap.getIcon(c.icon), color: Color(c.color), size: 20),
                          const SizedBox(width: Spacing.sm),
                          Text(c.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryId = v);
                  },
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: Spacing.lg),
            
            accountsAsync.when(
              data: (accounts) {
                if (_selectedAccountId != null && !accounts.any((a) => a.id == _selectedAccountId)) {
                  _selectedAccountId = null;
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: accounts.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.name));
                  }).toList(),
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedAccountId = v);
                  },
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: Spacing.lg),
            
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _pickDate();
              },
              borderRadius: BorderRadius.circular(Radii.md),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: Spacing.xxl),
            
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
              ),
              child: const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
