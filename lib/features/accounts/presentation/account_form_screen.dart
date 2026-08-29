import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/account_entity.dart';
import 'accounts_providers.dart';
import '../../../core/domain/enums.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account?.startingBalance.toStringAsFixed(0) ?? '0',
    );
    _selectedType = widget.account?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(accountsRepositoryProvider);
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'New Account' : 'Edit Account'),
        actions: [
          if (widget.account != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text('Are you sure you want to delete this account?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  _delete();
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: AccountType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(labelText: 'Starting Balance (Rp)', prefixText: 'Rp '),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid amount' : null,
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
