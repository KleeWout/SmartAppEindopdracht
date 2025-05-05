import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const String _categoriesKey = 'user_categories';

  // Default categories - will be used if no categories are saved yet
  static const List<String> defaultCategories = [
    'Food',
    'Supplies & Materials',
    'Entertainment',
    'Transportation',
    'Utilities',
    'Other',
  ];

  // Get all categories (default + user-added)
  Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final userCategories = prefs.getStringList(_categoriesKey);

    if (userCategories == null || userCategories.isEmpty) {
      // If no user categories exist yet, save and return the defaults
      await saveCategories(defaultCategories);
      return defaultCategories;
    }

    return userCategories;
  }

  // Save categories to shared preferences
  Future<void> saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  // Add a new category if it doesn't already exist
  Future<bool> addCategory(String category) async {
    if (category.trim().isEmpty) {
      return false;
    }

    final categories = await getCategories();

    // Check if category already exists (case insensitive)
    if (categories.any(
      (c) => c.toLowerCase() == category.trim().toLowerCase(),
    )) {
      return false;
    }

    categories.add(category.trim());
    await saveCategories(categories);
    return true;
  }

  // Delete a category
  Future<bool> deleteCategory(String category) async {
    final categories = await getCategories();

    // Don't allow deleting default categories
    if (defaultCategories.contains(category)) {
      return false;
    }

    // Check if category exists
    if (!categories.any((c) => c == category)) {
      return false;
    }

    categories.remove(category);
    await saveCategories(categories);
    return true;
  }
}
