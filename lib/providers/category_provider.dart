import 'package:flutter/foundation.dart';
import '../core/services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  CategoryProvider() {
    _loadCategories();
  }

  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<String> get filteredCategories {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    return _categories
        .where(
          (category) =>
              category.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  // Initialize categories from storage
  Future<void> _loadCategories() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _categoryService.getCategories();
    _isLoading = false;
    notifyListeners();
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Add a new category
  Future<bool> addCategory(String category) async {
    final success = await _categoryService.addCategory(category);
    if (success) {
      await _loadCategories(); // Reload all categories to ensure they're sorted correctly
    }
    return success;
  }

  // Delete a category
  Future<bool> deleteCategory(String category) async {
    final success = await _categoryService.deleteCategory(category);
    if (success) {
      await _loadCategories(); // Reload categories after deletion
    }
    return success;
  }

  // Check if a category exists (case insensitive)
  bool categoryExists(String category) {
    return _categories.any(
      (c) => c.toLowerCase() == category.trim().toLowerCase(),
    );
  }

  /// Clears all category data when a new user logs in
  void clearData() {
    // Clear all local category data
    // Adjust based on your actual implementation
    // If categories are user-specific, reset them
    // If using default categories, you might not need to clear them
    notifyListeners();
  }
}
