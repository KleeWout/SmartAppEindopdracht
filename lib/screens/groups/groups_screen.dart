import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:eindopdracht/core/constants/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/common/app_bottom_navigation.dart';
import 'widgets/group_item.dart';
import 'widgets/group_search_bar.dart';
import 'create_join_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        title: Text('Groups', style: AppStyles.heading.copyWith(color: AppColors.getAppBarTextColor(context))),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateJoinGroup(context),
            tooltip: 'Create or Join Group',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar - always visible regardless of data state
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GroupSearchBar(
              searchQuery: _searchQuery,
              onSearch: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Main content area
          Expanded(
            child: Consumer<GroupsProvider>(
              builder: (context, provider, _) {
                final groups = provider.groups;
                final isLoading = provider.isLoading;
                final error = provider.error;

                // Filter groups based on search query regardless of loading state
                final filteredGroups = groups.where((group) {
                  if (_searchQuery.isEmpty) return true;

                  // Search by name
                  final nameMatches = group.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());

                  // Add more search criteria here if group model is extended in the future
                  // For example: category search when implemented

                  return nameMatches;
                }).toList();

                if (isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading your groups...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading groups: $error',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              provider.reset(); // Try reloading data
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (groups.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/empty_state.png',
                            height: 150,
                            // If you don't have this asset, replace with an icon:
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.group_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No groups found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a new group or join an existing one to share expenses with friends and family',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildAddGroupButton(context),
                        ],
                      ),
                    ),
                  );
                }

                // Show message if search returns no results
                if (filteredGroups.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No groups found matching "$_searchQuery"',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Search'),
                        ),
                      ],
                    ),
                  );
                }

                // Group list with favorites section after filtering
                final favoriteGroups =
                    filteredGroups.where((group) => group.isFavorite).toList();
                final otherGroups =
                    filteredGroups.where((group) => !group.isFavorite).toList();

                return CustomScrollView(
                  slivers: [
                    // Favorites section (only show if there are favorites)
                    if (favoriteGroups.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Favorites',
                                style: AppStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.getTextColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GroupItem(group: favoriteGroups[index]),
                            );
                          }, childCount: favoriteGroups.length),
                        ),
                      ),
                    ],

                    // All groups or Other groups section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              favoriteGroups.isEmpty
                                  ? Icons.group
                                  : Icons.group_outlined,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              favoriteGroups.isEmpty
                                  ? 'All Groups'
                                  : 'Other Groups',
                              style: AppStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.getTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        80,
                      ), // Extra bottom padding for FAB
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GroupItem(
                                group: favoriteGroups.isEmpty
                                    ? filteredGroups[index]
                                    : otherGroups[index],
                              ),
                            );
                          },
                          childCount: favoriteGroups.isEmpty
                              ? filteredGroups.length
                              : otherGroups.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildAddGroupButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToCreateJoinGroup(context),
      icon: const Icon(Icons.add),
      label: const Text('Add Group'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  void _navigateToCreateJoinGroup(BuildContext context) {
    Navigator.pushNamed(context, '/create-join-group');
  }
}
