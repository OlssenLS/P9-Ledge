import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'accounts_providers.dart';
import 'account_form_screen.dart';
import '../../../core/utils/currency_formatter.dart';

import 'package:flutter/services.dart';

import '../../../core/domain/enums.dart';
import '../../../core/theme/design_tokens.dart';

import '../domain/account_entity.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(watchAccountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.sm),
            child: IconButton(
              icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const AccountFormScreen(),
                ));
              },
            ),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);

          return CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PORTFOLIO',
                        style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white38),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        CurrencyFormatter.format(totalBalance),
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Divider(height: 1, thickness: 0.5, color: Colors.white10),
                ),
              ),

              if (accounts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xl),
                    child: Center(
                      child: Text(
                        'No accounts found.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white38),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final account = accounts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.md),
                          child: _buildAccountCard(context, account),
                        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, end: 0);
                      },
                      childCount: accounts.length,
                    ),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for nav bar
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AccountEntity account) {
    final theme = Theme.of(context);
    
    IconData icon = Icons.account_balance_wallet_outlined;
    Color typeColor = Colors.white;
    
    switch (account.type) {
      case AccountType.cash:
        icon = Icons.payments_outlined;
        typeColor = theme.colorScheme.primary; // Turquoise
        break;
      case AccountType.bank:
        icon = Icons.account_balance_outlined;
        typeColor = Colors.white; 
        break;
      case AccountType.eWallet:
        icon = Icons.account_balance_wallet_outlined;
        typeColor = theme.colorScheme.secondary; // Orange
        break;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => AccountFormScreen(account: account),
        ));
      },
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: Spacing.md),
                    Text(
                      account.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    account.type.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'BALANCE',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Colors.white38),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(account.currentBalance),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
