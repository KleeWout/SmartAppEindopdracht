import 'package:eindopdracht/widgets/common/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/models/group.dart';
import '../../core/models/transaction.dart';
import '../../providers/groups_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/app_bottom_navigation.dart';
import 'edit_group_screen.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late Group _currentGroup;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    // Select the group to load its transactions
    Future.microtask(() {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).selectGroup(_currentGroup.id);
    });
  }

  void _refreshGroupData() {
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    final updatedGroup = groupsProvider.getGroupById(_currentGroup.id);
    if (updatedGroup != null) {
      setState(() {
        _currentGroup = updatedGroup;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        title: Text(_currentGroup.name,
            style: AppStyles.heading
                .copyWith(color: AppColors.getAppBarTextColor(context))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _currentGroup.isFavorite ? Icons.star : Icons.star_border,
              color: _currentGroup.isFavorite
                  ? AppColors.primary
                  : AppColors.getTextColor(context),
            ),
            onPressed: () {
              Provider.of<GroupsProvider>(
                context,
                listen: false,
              ).toggleFavorite(_currentGroup.id);
              _refreshGroupData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Group Profile Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Group Profile Image
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: _currentGroup.imageUrl != null
                        ? NetworkImage(_currentGroup.imageUrl!)
                        : null,
                    child: _currentGroup.imageUrl == null
                        ? Icon(Icons.group, size: 50, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Group ID with copy button
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getCardBackgroundColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.getCardBorderColor(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Group ID: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getTextColor(context),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _currentGroup.id,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy,
                              size: 20, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _currentGroup.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Group ID copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Copy Group ID',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Group Total Amount
                  Consumer<TransactionProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const CircularProgressIndicator(strokeWidth: 2);
                      }

                      final transactions = provider.groupTransactions;
                      final total = transactions.fold<double>(
                        0.0,
                        (sum, transaction) => sum + transaction.amount,
                      );

                      return Column(
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    AppColors.getSecondaryTextColor(context)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '€${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Edit and Leave Group Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Group'),
                        onPressed: () => _navigateToEditGroup(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Leave Group'),
                        onPressed: () => _showLeaveGroupDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              thickness: 1,
              color: AppColors.getDividerColor(context),
            ),

            // Transactions List Header
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Group Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Transactions List
            Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final transactions = provider.groupTransactions;

                if (transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No transactions in this group yet.'),
                    ),
                  );
                }

                // Group transactions by date
                final transactionsByDate = provider.transactionsByDate;
                final dates = transactionsByDate.keys.toList()
                  ..sort((a, b) =>
                      b.compareTo(a)); // Sort dates in descending order

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final dayTransactions = transactionsByDate[date]!;

                    return _buildTransactionGroup(date, dayTransactions);
                  },
                );
              },
            ),
          ],
        ),
      ),
      // Removed floatingActionButton
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildTransactionGroup(
    DateTime date,
    List<TransactionModel> transactions,
  ) {
    final formatter = DateFormat('EEEE, MMMM d, y');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            formatter.format(date),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...transactions.map(
          (transaction) => Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: TransactionItem(transaction: transaction),
          ),
        ),
        Divider(
          thickness: 1,
          color: AppColors.getDividerColor(context),
        ),
      ],
    );
  }

  Future<void> _showEditGroupDialog(BuildContext context) async {
    final textController = TextEditingController(text: _currentGroup.name);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Group name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final updatedGroup = _currentGroup.copyWith(
                  name: textController.text,
                );
                Provider.of<GroupsProvider>(
                  context,
                  listen: false,
                ).updateGroup(updatedGroup);
                Navigator.pop(context);

                // Refresh to update the group name in the UI
                _refreshGroupData();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLeaveGroupDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? '
          'You will lose access to all group transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<GroupsProvider>(
                context,
                listen: false,
              ).deleteGroup(_currentGroup.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to groups list
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditGroup(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EditGroupScreen(group: _currentGroup),
      ),
    )
        .then((_) {
      // Refresh group data when returning from Edit Group Screen
      _refreshGroupData();
    });
  }
}
