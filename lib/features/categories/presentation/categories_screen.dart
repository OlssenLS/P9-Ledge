import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'categories_providers.dart';
import '../../../core/utils/icon_map.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(watchCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(cat.color),
                  child: Icon(IconMap.getIcon(cat.icon), color: Colors.white),
                ),
                title: Text(cat.name),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => CategoryFormScreen(category: cat),
                  ));
                },
              );
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
            builder: (context) => const CategoryFormScreen(),
          ));
        },
      ),
    );
  }
}
