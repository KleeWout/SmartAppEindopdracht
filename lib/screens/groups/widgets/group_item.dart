import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/group.dart';
import '../../../providers/groups_provider.dart';
import '../../../core/constants/app_styles.dart';
import '../group_detail_page.dart';

class GroupItem extends StatelessWidget {
  final Group group;

  const GroupItem({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(AppStyles.cardRadius),
        border: Border.all(
          color: AppColors.getCardBorderColor(context),
        ),
      ),
      // Use ClipRRect to maintain rounded corners with InkWell
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.cardRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to group detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailPage(group: group),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  // Leading avatar
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    backgroundImage: group.imageUrl != null
                        ? NetworkImage(group.imageUrl!)
                        : null,
                    child: group.imageUrl == null
                        ? Icon(Icons.people, color: Colors.blue[800])
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Title (expanded to take available space)
                  Expanded(
                    child: Text(
                      group.name,
                      style: AppStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextColor(context),
                      ),
                    ),
                  ),
                  // Trailing star icon
                  IconButton(
                    icon: Icon(
                      group.isFavorite ? Icons.star : Icons.star_border,
                      color: group.isFavorite ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      Provider.of<GroupsProvider>(
                        context,
                        listen: false,
                      ).toggleFavorite(group.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
