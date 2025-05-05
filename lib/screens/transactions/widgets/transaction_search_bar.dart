import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../widgets/common/search_bar_widget.dart';

class TransactionSearchBar extends StatefulWidget {
  final TransactionFilter filter;
  final Function(TransactionFilter) onFilterChanged;

  const TransactionSearchBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<TransactionSearchBar> createState() => _TransactionSearchBarState();
}

class _TransactionSearchBarState extends State<TransactionSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.searchTerm);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.getCardBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SearchBarWidget(
              showBorder: false,
              controller: _searchController,
              hintText: 'Search by name or description',
              onChanged: (value) {
                final updatedFilter = widget.filter.copyWith(searchTerm: value);
                widget.onFilterChanged(updatedFilter);
              },
            ),
          ),
          Container(
            height: 34,
            width: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: widget.filter.hasFilter
                  ? AppColors.primary.withAlpha(25)
                  : AppColors.getDividerColor(context),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.tune,
                size: 18,
                color: widget.filter.hasFilter
                    ? AppColors.primary
                    : AppColors.getIconColor(context),
              ),
              onPressed: () {
                _showFilterDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    // Create a working copy of the filter
    TransactionFilter workingFilter = widget.filter.copyWith();

    // Controllers for range inputs
    final minAmountController = TextEditingController(
      text: workingFilter.minAmount?.toString() ?? '',
    );
    final maxAmountController = TextEditingController(
      text: workingFilter.maxAmount?.toString() ?? '',
    );

    // Format for displaying dates
    final dateFormat = DateFormat('dd/MM/yyyy');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.tune,
                    color: AppColors.getIconColor(context), size: 22),
                SizedBox(width: 12),
                Text(
                  'Filter Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Range
                  Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      'Amount Range:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.getTextColor(context),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            fillColor:
                                AppColors.getCardBackgroundColor(context),
                            hintText: 'Min',
                            prefixText: '€ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppColors.getCardBorderColor(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppColors.getCardBorderColor(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: maxAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max',
                            prefixText: '€ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppColors.getCardBorderColor(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppColors.getCardBorderColor(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor:
                                AppColors.getCardBackgroundColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Date Range
                  Text(
                    'Date Range:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  workingFilter.startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary:
                                          AppColors.getCardBackgroundColor(
                                              context),
                                      surface: AppColors.getCardBackgroundColor(
                                          context),
                                      onSurface:
                                          AppColors.getTextColor(context),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                workingFilter = workingFilter.copyWith(
                                  startDate: date,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.getCardBorderColor(context)),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.getCardBackgroundColor(context),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    workingFilter.startDate != null
                                        ? dateFormat
                                            .format(workingFilter.startDate!)
                                        : 'From',
                                    style: TextStyle(
                                      color: workingFilter.startDate != null
                                          ? AppColors.getTextColor(context)
                                          : AppColors.getTextColor(context),
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.getIconColor(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  workingFilter.endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary:
                                          AppColors.getCardBackgroundColor(
                                              context),
                                      surface: AppColors.getCardBackgroundColor(
                                          context),
                                      onSurface:
                                          AppColors.getTextColor(context),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                workingFilter = workingFilter.copyWith(
                                  endDate: date,
                                );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.getCardBorderColor(context)),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.getCardBackgroundColor(context),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    workingFilter.endDate != null
                                        ? dateFormat
                                            .format(workingFilter.endDate!)
                                        : 'To',
                                    style: TextStyle(
                                      color: workingFilter.endDate != null
                                          ? AppColors.getTextColor(context)
                                          : AppColors.getTextColor(context),
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.getIconColor(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Categories
                  Text(
                    'Categories:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selected category chips
                  if (workingFilter.categories.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.getCardBackgroundColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.getCardBorderColor(context)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: workingFilter.categories.map((category) {
                          return Chip(
                            backgroundColor: AppColors.primary.withAlpha(25),
                            side: const BorderSide(color: Colors.transparent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            label: Text(
                              category,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            onDeleted: () {
                              setState(() {
                                workingFilter.categories.remove(category);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Button to add categories
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Category Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await _showCategorySelector(context, workingFilter, (
                          updatedFilter,
                        ) {
                          setState(() {
                            workingFilter = updatedFilter;
                          });
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Groups
                  Text(
                    'Groups:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selected group chips
                  if (workingFilter.groups.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.getCardBackgroundColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.getCardBorderColor(context)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: workingFilter.groups.map((group) {
                          return Chip(
                            backgroundColor: AppColors.primary.withAlpha(25),
                            side: const BorderSide(color: Colors.transparent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            label: Text(
                              group,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            onDeleted: () {
                              setState(() {
                                workingFilter.groups.remove(group);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Button to add groups
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Group Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await _showGroupSelector(context, workingFilter, (
                          updatedFilter,
                        ) {
                          setState(() {
                            workingFilter = updatedFilter;
                          });
                        });
                      },
                    ),
                  ),

                  // Space at the bottom to separate from buttons
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      // Clear all filters
                      workingFilter.clear();
                      _searchController.clear();
                      Navigator.pop(context);
                      widget.onFilterChanged(workingFilter);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Update filter with amount values
                      double? minAmount;
                      double? maxAmount;

                      if (minAmountController.text.isNotEmpty) {
                        String minAmountText = minAmountController.text;
                        // Only convert comma to period if user manually entered a comma
                        if (minAmountText.contains(',')) {
                          minAmountText = minAmountText.replaceAll(',', '.');
                        }
                        minAmount = double.tryParse(minAmountText);
                      }

                      if (maxAmountController.text.isNotEmpty) {
                        String maxAmountText = maxAmountController.text;
                        // Only convert comma to period if user manually entered a comma
                        if (maxAmountText.contains(',')) {
                          maxAmountText = maxAmountText.replaceAll(',', '.');
                        }
                        maxAmount = double.tryParse(maxAmountText);
                      }

                      final updatedFilter = workingFilter.copyWith(
                        minAmount: minAmount,
                        maxAmount: maxAmount,
                      );

                      Navigator.pop(context);
                      widget.onFilterChanged(updatedFilter);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Method to handle category selection for filtering
  Future<void> _showCategorySelector(
    BuildContext context,
    TransactionFilter workingFilter,
    Function(TransactionFilter) onFilterUpdated,
  ) async {
    // Get categories from provider
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // Reset any previous search query to show all categories
    categoryProvider.updateSearchQuery('');

    // Show multi-select category dialog
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Categories'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categories list with checkboxes
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: Consumer<CategoryProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final categories = provider.categories;

                        if (categories.isEmpty) {
                          return const Center(
                            child: Text('No categories available'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected =
                                workingFilter.categories.contains(category);

                            return CheckboxListTile(
                              title: Text(category),
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    if (!workingFilter.categories
                                        .contains(category)) {
                                      workingFilter.categories.add(category);
                                    }
                                  } else {
                                    workingFilter.categories.remove(category);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onFilterUpdated(workingFilter);
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Method to handle group selection for filtering
  Future<void> _showGroupSelector(
    BuildContext context,
    TransactionFilter workingFilter,
    Function(TransactionFilter) onFilterUpdated,
  ) async {
    // Get groups from provider
    Provider.of<GroupsProvider>(context, listen: false);

    // Show multi-select group dialog
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Groups'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Groups list with checkboxes
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: Consumer<GroupsProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final groups = provider.groups;

                        if (groups.isEmpty) {
                          return const Center(
                            child: Text('No groups available'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            final isSelected =
                                workingFilter.groups.contains(group.name);

                            return CheckboxListTile(
                              title: Text(group.name),
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    if (!workingFilter.groups.contains(
                                      group.name,
                                    )) {
                                      workingFilter.groups.add(group.name);
                                    }
                                  } else {
                                    workingFilter.groups.remove(group.name);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onFilterUpdated(workingFilter);
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
