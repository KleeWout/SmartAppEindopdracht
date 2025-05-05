import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:eindopdracht/core/constants/app_styles.dart';
import 'package:eindopdracht/widgets/common/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/common/app_bottom_navigation.dart';
import 'models/transaction_filter.dart';
import 'widgets/transaction_search_bar.dart';
import 'widgets/date_header.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = TransactionFilter();

  void _onFilterChanged(TransactionFilter newFilter) {
    setState(() {
      _filter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        title: Text('Transactions', style: AppStyles.heading.copyWith(color: AppColors.getAppBarTextColor(context))),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TransactionSearchBar(
              filter: _filter,
              onFilterChanged: _onFilterChanged,
            ),
          ),
          if (_filter.hasFilter) _buildActiveFilters(),
          Expanded(child: _buildTransactionsList()),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Filters:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_filter.minAmount != null || _filter.maxAmount != null)
                Chip(
                  label: Text(
                    'Amount: ${_filter.minAmount != null ? '€${_filter.minAmount}' : '€0'} - ${_filter.maxAmount != null ? '€${_filter.maxAmount}' : '∞'}',
                  ),
                  deleteIcon: const Icon(Icons.clear, size: 18),
                  onDeleted: () {
                    setState(() {
                      _filter = _filter.copyWith(
                        minAmount: null,
                        maxAmount: null,
                      );
                    });
                  },
                ),
              if (_filter.startDate != null || _filter.endDate != null)
                Chip(
                  label: const Text('Date Range'),
                  deleteIcon: const Icon(Icons.clear, size: 18),
                  onDeleted: () {
                    setState(() {
                      _filter = _filter.copyWith(
                        startDate: null,
                        endDate: null,
                      );
                    });
                  },
                ),
              ..._filter.categories.map(
                (category) => Chip(
                  label: Text(category),
                  deleteIcon: const Icon(Icons.clear, size: 18),
                  onDeleted: () {
                    final updatedCategories = List<String>.from(
                      _filter.categories,
                    )..remove(category);
                    setState(() {
                      _filter = _filter.copyWith(categories: updatedCategories);
                    });
                  },
                ),
              ),
              ..._filter.groups.map(
                (group) => Chip(
                  label: Text('Group: $group'),
                  deleteIcon: const Icon(Icons.clear, size: 18),
                  onDeleted: () {
                    final updatedGroups = List<String>.from(_filter.groups)
                      ..remove(group);
                    setState(() {
                      _filter = _filter.copyWith(groups: updatedGroups);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        // Apply filters to the transactions
        final filteredTransactions = _filterTransactions(
          provider.transactions,
          _filter,
        );

        // Group filtered transactions by date
        final Map<DateTime, List<TransactionModel>> filteredByDate = {};
        for (final transaction in filteredTransactions) {
          final date = DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          );

          if (!filteredByDate.containsKey(date)) {
            filteredByDate[date] = [];
          }

          filteredByDate[date]!.add(transaction);
        }

        final sortedDates = filteredByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        if (sortedDates.isEmpty) {
          return const Center(
            child: Text(
              'No transactions match your filters',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final transactions = filteredByDate[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DateHeader(date: date),
                ...transactions.map(
                  (transaction) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: TransactionItem(transaction: transaction),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
    TransactionFilter filter,
  ) {
    if (!filter.hasFilter) {
      return transactions;
    }

    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);

    // Map group names to group IDs for filtering
    final groupIdsByName = <String, String>{};
    if (filter.groups.isNotEmpty) {
      for (final group in groupsProvider.groups) {
        if (filter.groups.contains(group.name)) {
          groupIdsByName[group.name] = group.id;
        }
      }
    }

    return transactions.where((transaction) {
      // Search term filter (search in merchant name and description)
      if (filter.searchTerm.isNotEmpty) {
        final searchTermLower = filter.searchTerm.toLowerCase();
        final nameMatch = transaction.merchantName.toLowerCase().contains(
              searchTermLower,
            );
        final descriptionMatch = transaction.description != null &&
            transaction.description!.toLowerCase().contains(searchTermLower);

        if (!nameMatch && !descriptionMatch) {
          return false;
        }
      }

      // Amount range filter
      if (filter.minAmount != null && transaction.amount < filter.minAmount!) {
        return false;
      }

      if (filter.maxAmount != null && transaction.amount > filter.maxAmount!) {
        return false;
      }

      // Date range filter
      if (filter.startDate != null) {
        final startDate = DateTime(
          filter.startDate!.year,
          filter.startDate!.month,
          filter.startDate!.day,
        );

        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );

        if (transactionDate.isBefore(startDate)) {
          return false;
        }
      }

      if (filter.endDate != null) {
        final endDate = DateTime(
          filter.endDate!.year,
          filter.endDate!.month,
          filter.endDate!.day,
        );

        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );

        // Add 1 day to include the end date fully
        final adjustedEndDate = endDate.add(const Duration(days: 1));

        if (transactionDate.isAfter(adjustedEndDate)) {
          return false;
        }
      }

      // Category filter
      if (filter.categories.isNotEmpty &&
          !filter.categories.contains(transaction.category)) {
        return false;
      }

      // Merchant filter (if implemented)
      if (filter.merchants.isNotEmpty &&
          !filter.merchants.contains(transaction.merchantName)) {
        return false;
      }

      // Group filter
      if (filter.groups.isNotEmpty) {
        final groupIds = groupIdsByName.values.toList();
        if (!groupIds.contains(transaction.groupId)) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
