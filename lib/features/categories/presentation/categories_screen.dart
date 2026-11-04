import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state_view.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context, String type) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.accountPalette.first;
    String selectedIcon = 'category';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Add ${type == 'expense' ? 'Expense' : 'Income'} Category', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Pet Care, Consultation'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Color Badge', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppColors.accountPalette.map((color) {
                        final isChosen = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 16,
                            child: isChosen ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter category name')),
                          );
                          return;
                        }

                        await ref.read(categoryRepositoryProvider).addCategory(
                          name: name,
                          type: type,
                          iconCode: selectedIcon,
                          colorValue: selectedColor.toARGB32(),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Category'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () {
              final type = _tabController.index == 0 ? 'expense' : 'income';
              _showAddCategoryDialog(context, type);
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenses = categories.where((c) => c.type == 'expense' && c.parentCategoryId == null).toList();
          final income = categories.where((c) => c.type == 'income' && c.parentCategoryId == null).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenses, categories, 'expense'),
              _buildCategoryList(income, categories, 'income'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCategoryList(List<dynamic> parentList, List<dynamic> allCategories, String type) {
    if (parentList.isEmpty) {
      return EmptyStateView(
        icon: Icons.category_outlined,
        title: 'No Categories',
        description: 'Categories help you understand and control your spending.',
        actionLabel: 'Add Category',
        onAction: () => _showAddCategoryDialog(context, type),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: parentList.length,
      itemBuilder: (context, index) {
        final cat = parentList[index];
        final subcategories = allCategories.where((c) => c.parentCategoryId == cat.id).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CategoryIcon(
              iconCode: cat.iconCode,
              colorValue: cat.colorValue,
              size: 20,
              padding: 8,
            ),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              cat.isDefault ? 'Standard System Category' : 'Custom Category',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            children: [
              if (subcategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No subcategories defined', style: TextStyle(fontSize: 12, color: Colors.grey)),
                )
              else
                ...subcategories.map((sub) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 48, right: 16),
                    leading: const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                    title: Text(sub.name, style: const TextStyle(fontSize: 13)),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
