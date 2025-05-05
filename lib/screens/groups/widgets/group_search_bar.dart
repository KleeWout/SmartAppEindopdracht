import 'package:flutter/material.dart';
import '../../../widgets/common/search_bar_widget.dart';

class GroupSearchBar extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearch;

  const GroupSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearch,
  });

  @override
  State<GroupSearchBar> createState() => _GroupSearchBarState();
}

class _GroupSearchBarState extends State<GroupSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(GroupSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if the search query changed externally
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBarWidget(
      controller: _searchController,
      hintText: 'Search groups',
      onChanged: widget.onSearch,
    );
  }
}
