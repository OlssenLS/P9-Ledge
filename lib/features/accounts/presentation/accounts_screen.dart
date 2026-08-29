import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'accounts_providers.dart';
import 'account_form_screen.dart';
import '../../../core/utils/currency_formatter.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(watchAccountsProvider);

    return Scaffold(
      appBar: AppBar(),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts found.'));
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet)),
                title: Text(account.name),
                subtitle: Text(account.type.name),
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: Text(
                    CurrencyFormatter.format(account.currentBalance),
                    key: ValueKey(account.currentBalance),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AccountFormScreen(account: account),
                  ));
                },
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const AccountFormScreen(),
          ));
        },
      ),
    );
  }
}
