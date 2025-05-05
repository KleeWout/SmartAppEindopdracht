import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../core/services/category_service.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../core/constants/app_colors.dart';

class CategorySelectionScreen extends StatefulWidget {
  final String currentCategory;

  const CategorySelectionScreen({Key? key, required this.currentCategory})
      : super(key: key);

  @override
  _CategorySelectionScreenState createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize search with empty string to show all categories
    Future.microtask(() {
      Provider.of<CategoryProvider>(
        context,
        listen: false,
      ).updateSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _selectCategory(BuildContext context, String category) {
    Navigator.pop(context, category);
  }

  void _handleAddCategory(BuildContext context) async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // Check if category already exists
    if (categoryProvider.categoryExists(query)) {
      // If it exists, just select it
      _selectCategory(
        context,
        categoryProvider.categories.firstWhere(
          (c) => c.toLowerCase() == query.toLowerCase(),
        ),
      );
      return;
    }

    // Otherwise, add the new category
    final success = await categoryProvider.addCategory(query);

    if (success) {
      // Select the newly added category
      _selectCategory(context, query);
    }
  }

  // Method to handle category deletion
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String category,
  ) async {
    // Check if it's a default category that can't be deleted
    final isDefaultCategory = CategoryService.defaultCategories.contains(
      category,
    );

    if (isDefaultCategory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default categories cannot be deleted'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text('Are you sure you want to delete "$category"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final success = await categoryProvider.deleteCategory(category);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$category" deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.getAppBarBackgroundColor(context),
          title: const Text('Select Category')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Search or add a category',
              onChanged: (value) {
                Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                ).updateSearchQuery(value);
              },
              // suffixIcon: IconButton(
              //   icon: const Icon(Icons.add_circle_outline),
              //   onPressed: () => _handleAddCategory(context),
              //   tooltip: 'Add as new category',
              // ),
            ),
          ),

          // Category list
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, _) {
                if (categoryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredCategories = categoryProvider.filteredCategories;
                final query = _searchController.text.trim();
                final showAddOption =
                    query.isNotEmpty && !categoryProvider.categoryExists(query);

                return ListView.builder(
                  itemCount:
                      filteredCategories.length + (showAddOption ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Add category item at the top if we have a query
                    if (showAddOption && index == 0) {
                      return ListTile(
                        leading: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                        ),
                        title: Text('Add "$query" as new category'),
                        onTap: () => _handleAddCategory(context),
                      );
                    }

                    // Adjust index if we have add option
                    final categoryIndex = showAddOption ? index - 1 : index;
                    final category = filteredCategories[categoryIndex];
                    final isSelected = category == widget.currentCategory;

                    return ListTile(
                      leading: Icon(
                        Icons.category,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      onTap: () => _selectCategory(context, category),
                      onLongPress: () => _showDeleteConfirmation(
                        context,
                        category,
                      ), // Show a visual hint that the item can be long-pressed
                      trailing:
                          CategoryService.defaultCategories.contains(category)
                              ? null
                              : const Icon(Icons.more_vert, size: 16),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
