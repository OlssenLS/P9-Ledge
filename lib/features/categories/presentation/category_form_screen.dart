import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/category_entity.dart';
import 'categories_providers.dart';
import '../../../core/utils/icon_map.dart';
import '../../../core/theme/design_tokens.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final CategoryEntity? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;

  static const List<int> _colors = [
    0xFF40E0D0, // Turquoise (Primary)
    0xFFFFA500, // Orange (Secondary)
    0xFFCF6679, // Red/Error
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF03A9F4, // Light Blue
    0xFF00BCD4, // Cyan
    0xFF009688, // Teal
    0xFF4CAF50, // Green
    0xFF8BC34A, // Light Green
    0xFFCDDC39, // Lime
    0xFFFFEB3B, // Yellow
    0xFFFFC107, // Amber
    0xFFFF5722, // Deep Orange
    0xFF795548, // Brown
    0xFF9E9E9E, // Grey
    0xFF607D8B, // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? IconMap.icons.keys.first;
    _selectedColor = widget.category?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(categoriesRepositoryProvider);
      if (widget.category == null) {
        await repo.addCategory(_nameController.text, _selectedIcon, _selectedColor);
      } else {
        await repo.updateCategory(widget.category!.id, _nameController.text, _selectedIcon, _selectedColor);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  void _delete() async {
    final repo = ref.read(categoriesRepositoryProvider);
    await repo.deleteCategory(widget.category!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null ? 'NEW CATEGORY' : 'EDIT CATEGORY',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        actions: [
          if (widget.category != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Category?'),
                    content: const Text('Are you sure you want to delete this category?'),
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
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(Spacing.xl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Category Preview & Name
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Color(_selectedColor).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        child: Icon(
                          IconMap.getIcon(_selectedIcon),
                          color: Color(_selectedColor),
                          size: 28,
                        ),
                      ).animate(key: ValueKey(_selectedIcon)).scale(duration: 200.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: Spacing.xl),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xxl),
                  
                  // Icon Selection
                  Text('ICON', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: Spacing.md),
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    child: Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: IconMap.icons.keys.map((iconName) {
                        final isSelected = _selectedIcon == iconName;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIcon = iconName);
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.all(Spacing.md),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconMap.getIcon(iconName),
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: Spacing.xl),
                  
                  // Color Selection
                  Text('COLOR', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: Spacing.md),
                  Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    child: Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: _colors.map((colorValue) {
                        final isSelected = _selectedColor == colorValue;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = colorValue);
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(colorValue),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 3) : Border.all(color: Colors.transparent, width: 3),
                            ),
                            child: isSelected ? Icon(Icons.check, color: theme.colorScheme.onSurface, size: 20) : null,
                          ),
                        ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 150.ms);
                      }).toList(),
                    ),
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
            label: Text('SAVE CATEGORY', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
