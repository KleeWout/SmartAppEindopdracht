import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../core/constants/app_styles.dart';

class GroupsGrid extends StatelessWidget {
  const GroupsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode for stable background color reference
    final backgroundColor = AppColors.getCardBackgroundColor(context);
    final borderColor = AppColors.getCardBorderColor(context);
    final textColor = AppColors.getTextColor(context);

    final groupsProvider = Provider.of<GroupsProvider>(context);
    // Filter to only show favorite groups on the home screen
    final favoriteGroups =
        groupsProvider.groups.where((group) => group.isFavorite).toList();

    if (favoriteGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(Icons.star_border, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No favorite groups yet',
                style: AppStyles.body.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Star a group in the Groups tab to add it here',
                style: AppStyles.caption.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: favoriteGroups.length,
      itemBuilder: (context, index) {
        final group = favoriteGroups[index];
        return GestureDetector(
          onTap: () {
            // Navigate to group detail page
            Navigator.pushNamed(context, '/group-detail', arguments: group);
          },
          child: Container(
            decoration: BoxDecoration(
              // Use the cached theme colors to prevent flashing during refresh
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppStyles.cardRadius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        backgroundImage: group.imageUrl != null
                            ? NetworkImage(group.imageUrl!)
                            : null,
                        radius: 32,
                        child: group.imageUrl == null
                            ? Icon(Icons.people, color: Colors.blue[800])
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        group.name,
                        style: AppStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.star, color: Colors.blue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
