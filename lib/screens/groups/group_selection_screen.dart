import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../core/constants/app_colors.dart';

class GroupSelectionScreen extends StatefulWidget {
  final String currentGroupId;

  const GroupSelectionScreen({super.key, required this.currentGroupId});

  @override
  _GroupSelectionScreenState createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _selectGroup(BuildContext context, String groupId) {
    Navigator.pop(context, groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.getAppBarBackgroundColor(context),
          title: const Text('Select Group')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Search groups',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Group list
          Expanded(
            child: Consumer<GroupsProvider>(
              builder: (context, groupsProvider, _) {
                if (groupsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groups = groupsProvider.groups;
                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No groups available',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/groups');
                          },
                          child: const Text('Create a Group'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter groups by search query
                final filteredGroups = _searchQuery.isEmpty
                    ? groups
                    : groups
                        .where(
                          (group) => group.name.toLowerCase().contains(
                                _searchQuery,
                              ),
                        )
                        .toList();

                if (filteredGroups.isEmpty) {
                  return const Center(
                    child: Text('No groups found matching your search'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    final isSelected = group.id == widget.currentGroupId;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          group.name.isNotEmpty
                              ? group.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        group.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      onTap: () => _selectGroup(context, group.id),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
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
