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
                        style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        CurrencyFormatter.format(totalBalance),
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Divider(height: 1, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == accounts.length) {
                        // The "Create Account" transparent text button
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => const AccountFormScreen(),
                                ));
                              },
                              icon: Icon(Icons.add, color: theme.colorScheme.primary, size: 20),
                              label: Text(
                                'CREATE ACCOUNT',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.md),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, end: 0);
                      }

                      final account = accounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: _buildAccountCard(context, account),
                      ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, end: 0);
                    },
                    childCount: accounts.length + 1,
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
    Color typeColor = Theme.of(context).colorScheme.onSurface;
    
    switch (account.type) {
      case AccountType.cash:
        icon = Icons.payments_outlined;
        typeColor = theme.colorScheme.primary; // Turquoise
        break;
      case AccountType.bank:
        icon = Icons.account_balance_outlined;
        typeColor = Theme.of(context).colorScheme.onSurface; 
        break;
      case AccountType.eWallet:
        icon = Icons.account_balance_wallet_outlined;
        typeColor = theme.colorScheme.secondary; // Orange
        break;
      case AccountType.rdn:
        icon = Icons.trending_up; // Good for investment/RDN
        typeColor = Colors.purpleAccent; // Distinct color for RDN
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
                  ),
                  child: Text(
                    account.type.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'BALANCE',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(account.currentBalance),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
