import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/transaction_entity.dart';
import 'transactions_providers.dart';
import '../../categories/presentation/categories_providers.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../../core/domain/enums.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;

  const TransactionFormScreen({super.key, this.transaction});

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
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toStringAsFixed(0) ?? '',
    );
    _noteController = TextEditingController(text: widget.transaction?.note ?? '');
    _selectedType = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.transaction?.categoryId;
    _selectedAccountId = widget.transaction?.accountId;
    _selectedDate = widget.transaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null || _selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category and account.')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New Transaction' : 'Edit Transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction?'),
                    content: const Text('Are you sure you want to delete this transaction?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
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
          padding: const EdgeInsets.all(16.0),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() => _selectedType = set.first);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (Rp)', prefixText: 'Rp '),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid amount' : null,
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) {
                // If the selected category was deleted, clear the selection
                if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
                  _selectedCategoryId = null;
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),
            accountsAsync.when(
              data: (accounts) {
                if (_selectedAccountId != null && !accounts.any((a) => a.id == _selectedAccountId)) {
                  _selectedAccountId = null;
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.name));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              contentPadding: EdgeInsets.zero,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
