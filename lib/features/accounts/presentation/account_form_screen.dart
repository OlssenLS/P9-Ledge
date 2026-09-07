import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/account_entity.dart';
import 'accounts_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_formatter.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final AccountEntity? account;

  const AccountFormScreen({super.key, this.account});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late AccountType _selectedType;
  
  final _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account?.startingBalance.toStringAsFixed(0) ?? '',
    );
    _selectedType = widget.account?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(accountsRepositoryProvider);
      final balance = double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0.0;
      
      if (widget.account == null) {
        await repo.addAccount(_nameController.text, _selectedType, balance);
      } else {
        await repo.updateAccount(widget.account!.id, _nameController.text, _selectedType, balance);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  void _delete() async {
    final repo = ref.read(accountsRepositoryProvider);
    await repo.deleteAccount(widget.account!.id);
    if (mounted) Navigator.pop(context);
  }
  
  void _showTypePicker() {
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Text(
                  'Account Type',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.lg),
                ...AccountType.values.map((type) => _buildTypeOptionTile(type)),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildTypeOptionTile(AccountType type) {
    IconData icon;
    Color color;
    String label = type.name.toUpperCase();
    
    switch (type) {
      case AccountType.cash:
        icon = Icons.payments_outlined;
        color = Theme.of(context).colorScheme.primary;
        break;
      case AccountType.bank:
        icon = Icons.account_balance_outlined;
        color = Theme.of(context).colorScheme.onSurface;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: InkWell(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.account != null;
    
    String typeLabel = _selectedType.name.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(isEditing ? 'Edit Account' : 'New Account', style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STARTING BALANCE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'IDR',
                        style: theme.textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _balanceController,
                          focusNode: _amountFocus,
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: theme.textTheme.displaySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  // Name Field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, Spacing.xs),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            style: theme.textTheme.titleMedium,
                            decoration: InputDecoration(
                              hintText: 'Account Name (e.g. BCA, GoPay)',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(vertical: Spacing.md),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
                  
                  // Type Selector
                  InkWell(
                    onTap: _showTypePicker,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.lg)),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), size: 20),
                          const SizedBox(width: Spacing.md),
                          Text('Type', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          Text(typeLabel, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                          const SizedBox(width: Spacing.xs),
                          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: Spacing.xxl),
            
            if (isEditing)
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: const Text('Are you sure you want to delete this account? This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true), 
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                          child: const Text('Delete')
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    _delete();
                  }
                },
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                label: Text('DELETE ACCOUNT', style: TextStyle(color: theme.colorScheme.error, letterSpacing: 1.2)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
              elevation: 0,
            ),
            child: const Text('SAVE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }
}
