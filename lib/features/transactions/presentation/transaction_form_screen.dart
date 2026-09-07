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
  final _amountFocus = FocusNode();
  
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  
  late TransactionType _selectedType;
  int? _selectedCategoryId;
  int? _selectedAccountId;
  int? _selectedToAccountId;
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
    _selectedToAccountId = widget.transaction?.toAccountId;
    _selectedDate = widget.transaction?.date ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final amtText = _amountController.text.replaceAll(',', '');
      final amount = double.tryParse(amtText) ?? 0;
      
      if (_selectedType != TransactionType.transfer && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        return;
      }
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account')));
        return;
      }
      if (_selectedType == TransactionType.transfer && _selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a destination account')));
        return;
      }
      if (_selectedType == TransactionType.transfer && _selectedAccountId == _selectedToAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destination account cannot be the same')));
        return;
      }

      final repo = ref.read(transactionsRepositoryProvider);
      
      if (widget.transaction == null) {
        await repo.addTransaction(
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategoryId,
          accountId: _selectedAccountId!,
          toAccountId: _selectedToAccountId,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          date: _selectedDate,
        );
      } else {
        await repo.updateTransaction(
          id: widget.transaction!.id,
          amount: amount,
          type: _selectedType,
          categoryId: _selectedCategoryId,
          accountId: _selectedAccountId!,
          toAccountId: _selectedToAccountId,
          note: _noteController.text.isEmpty ? null : _noteController.text,
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

  void _showTypePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContainer(
          title: 'Transaction Type',
          children: TransactionType.values.map((type) => _buildTypeOptionTile(type)).toList(),
        );
      }
    );
  }
  
  Widget _buildTypeOptionTile(TransactionType type) {
    IconData icon;
    Color color;
    String label = type.name.toUpperCase();
    
    switch (type) {
      case TransactionType.expense:
        icon = Icons.arrow_upward;
        color = Theme.of(context).colorScheme.error;
        break;
      case TransactionType.income:
        icon = Icons.arrow_downward;
        color = Theme.of(context).colorScheme.primary;
        break;
      case TransactionType.transfer:
        icon = Icons.swap_horiz;
        color = Colors.blueAccent;
        break;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedType = type);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: _selectedType == type ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(Radii.md),
          color: _selectedType == type ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: Spacing.md),
            Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_selectedType == type)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
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
        return _buildBottomSheetContainer(
          title: 'Select Category',
          children: [
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) return const Center(child: Text('No categories available'));
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
          ],
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
        return _buildBottomSheetContainer(
          title: isDestination ? 'To Account' : 'From Account',
          children: [
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) return const Center(child: Text('No accounts available'));
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final a = accounts[index];
                    final isSelected = isDestination ? _selectedToAccountId == a.id : _selectedAccountId == a.id;
                    return ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined),
                      title: Text(a.name),
                      subtitle: Text(a.type.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isDestination) {
                            _selectedToAccountId = a.id;
                          } else {
                            _selectedAccountId = a.id;
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day, _selectedDate.hour, _selectedDate.minute);
      });
    }
  }

  Widget _buildBottomSheetContainer({required String title, required List<Widget> children}) {
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.transaction != null;
    final isDark = theme.brightness == Brightness.dark;
    
    Color activeColor;
    switch (_selectedType) {
      case TransactionType.expense:
        activeColor = theme.colorScheme.onSurface;
        break;
      case TransactionType.income:
        activeColor = theme.colorScheme.primary;
        break;
      case TransactionType.transfer:
        activeColor = Colors.blueAccent;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(isEditing ? 'EDIT TRANSACTION' : 'NEW TRANSACTION', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: isDark ? Colors.white38 : Colors.black38)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(Spacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Amount Input Card
                  Container(
                    padding: const EdgeInsets.all(Spacing.xl),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(Radii.lg),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AMOUNT', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.38))),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'IDR',
                              style: theme.textTheme.titleMedium?.copyWith(color: activeColor.withValues(alpha: 0.60), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                focusNode: _amountFocus,
                                keyboardType: TextInputType.number,
                                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: activeColor),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.24)),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid amount' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(Radii.lg),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Column(
                      children: [
                        // Type Selector
                        InkWell(
                          onTap: _showTypePicker,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
                          child: Padding(
                            padding: const EdgeInsets.all(Spacing.lg),
                            child: Row(
                              children: [
                                Icon(Icons.swap_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                                const SizedBox(width: Spacing.md),
                                Text('Type', style: theme.textTheme.titleMedium),
                                const Spacer(),
                                Text(_selectedType.name.toUpperCase(), style: theme.textTheme.titleMedium?.copyWith(color: activeColor)),
                                const SizedBox(width: Spacing.xs),
                                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                        
                        // Category (Hidden for transfers)
                        if (_selectedType != TransactionType.transfer) ...[
                          InkWell(
                            onTap: _showCategoryPicker,
                            child: Padding(
                              padding: const EdgeInsets.all(Spacing.lg),
                              child: Row(
                                children: [
                                  Icon(Icons.category_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                                  const SizedBox(width: Spacing.md),
                                  Text('Category', style: theme.textTheme.titleMedium),
                                  const Spacer(),
                                  Text(
                                    _selectedCategoryId != null 
                                      ? ref.watch(watchCategoriesProvider).value?.where((c) => c.id == _selectedCategoryId).firstOrNull?.name ?? 'Select'
                                      : 'Select', 
                                    style: theme.textTheme.titleMedium?.copyWith(color: _selectedCategoryId != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.38))
                                  ),
                                  const SizedBox(width: Spacing.xs),
                                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                        ],
                        
                        // Account
                        InkWell(
                          onTap: () => _showAccountPicker(isDestination: false),
                          child: Padding(
                            padding: const EdgeInsets.all(Spacing.lg),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                                const SizedBox(width: Spacing.md),
                                Text(_selectedType == TransactionType.transfer ? 'From Account' : 'Account', style: theme.textTheme.titleMedium),
                                const Spacer(),
                                Text(
                                  _selectedAccountId != null 
                                    ? ref.watch(watchAccountsProvider).value?.where((a) => a.id == _selectedAccountId).firstOrNull?.name ?? 'Select'
                                    : 'Select', 
                                  style: theme.textTheme.titleMedium?.copyWith(color: _selectedAccountId != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.38))
                                ),
                                const SizedBox(width: Spacing.xs),
                                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                              ],
                            ),
                          ),
                        ),
                        
                        // To Account (Only for transfers)
                        if (_selectedType == TransactionType.transfer) ...[
                          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                          InkWell(
                            onTap: () => _showAccountPicker(isDestination: true),
                            child: Padding(
                              padding: const EdgeInsets.all(Spacing.lg),
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, color: theme.colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                                  const SizedBox(width: Spacing.md),
                                  Text('To Account', style: theme.textTheme.titleMedium),
                                  const Spacer(),
                                  Text(
                                    _selectedToAccountId != null 
                                      ? ref.watch(watchAccountsProvider).value?.where((a) => a.id == _selectedToAccountId).firstOrNull?.name ?? 'Select'
                                      : 'Select', 
                                    style: theme.textTheme.titleMedium?.copyWith(color: _selectedToAccountId != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.38))
                                  ),
                                  const SizedBox(width: Spacing.xs),
                                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                        
                        // Date
                        InkWell(
                          onTap: _pickDate,
                          child: Padding(
                            padding: const EdgeInsets.all(Spacing.lg),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                                const SizedBox(width: Spacing.md),
                                Text('Date', style: theme.textTheme.titleMedium),
                                const Spacer(),
                                Text(DateFormat.yMMMd().format(_selectedDate), style: theme.textTheme.titleMedium),
                                const SizedBox(width: Spacing.xs),
                                Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                              ],
                            ),
                          ),
                        ),
                        
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),

                        // Notes Field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xs),
                          child: Row(
                            children: [
                              Icon(Icons.edit_note, color: theme.colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                              const SizedBox(width: Spacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _noteController,
                                  style: theme.textTheme.titleMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Notes (Optional)',
                                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: Spacing.md),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: Spacing.xxl),
                  
                  if (isEditing)
                    TextButton.icon(
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
                                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          _delete();
                        }
                      },
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      label: Text('DELETE TRANSACTION', style: TextStyle(color: theme.colorScheme.error, letterSpacing: 1.5)),
                    ),
                    
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: _save,
            elevation: 0,
            backgroundColor: activeColor,
            label: Text(
              isEditing ? 'SAVE CHANGES' : 'CONFIRM TRANSACTION', 
              style: theme.textTheme.titleMedium?.copyWith(color: _selectedType == TransactionType.income ? Colors.black : theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ),
    );
  }
}
