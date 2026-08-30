import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('SETTINGS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          // Appearance
          _buildSectionHeader('APPEARANCE', theme),
          _buildSettingsTile(
            context,
            icon: themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: themeMode == ThemeMode.dark,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).toggle(val);
              },
            ),
          ),
          
          const SizedBox(height: Spacing.xl),
          
          // Data Management
          _buildSectionHeader('DATA MANAGEMENT', theme),
          _buildSettingsTile(
            context,
            icon: Icons.cloud_upload_outlined,
            title: 'Backup Data',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup feature coming soon!')));
            },
          ),
          const SizedBox(height: Spacing.sm),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'Reset All Data',
            iconColor: theme.colorScheme.error,
            textColor: theme.colorScheme.error,
            onTap: () {
              // TODO: Implement actual database reset
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset All Data?'),
                  content: const Text('This will permanently delete all your transactions, accounts, and categories. This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data reset feature coming soon!')));
                      },
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: Spacing.xl),
          
          // About
          _buildSectionHeader('ABOUT', theme),
          _buildSettingsTile(
            context,
            icon: Icons.new_releases_outlined,
            title: 'Changelogs',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changelogs coming soon!')));
            },
          ),
          
          const SizedBox(height: Spacing.xxl),
          Center(
            child: Text(
              'Ledge v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm, left: Spacing.xs),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.5,
          color: theme.brightness == Brightness.dark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? (isDark ? Colors.white70 : Colors.black87), size: 22),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor ?? (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            if (trailing != null) trailing else if (onTap != null) Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }
}
