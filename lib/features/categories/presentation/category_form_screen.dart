import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_entity.dart';
import 'categories_providers.dart';
import '../../../core/utils/icon_map.dart';

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
    0xFFF44336, // Red
    0xFFE91E63, // Pink
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
    0xFFFF9800, // Orange
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
        actions: [
          if (widget.category != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Category?'),
                    content: const Text('Are you sure you want to delete this category?'),
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
            const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IconMap.icons.keys.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: CircleAvatar(
                    backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                    child: Icon(
                      IconMap.getIcon(iconName),
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((colorValue) {
                final isSelected = _selectedColor == colorValue;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = colorValue),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                    ),
                  ),
                );
              }).toList(),
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
