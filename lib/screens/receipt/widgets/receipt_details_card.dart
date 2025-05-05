import 'dart:io';
import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:eindopdracht/core/constants/app_styles.dart';
import 'package:eindopdracht/core/models/group.dart';
import 'package:eindopdracht/providers/groups_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/receipt_provider.dart';
import '../category_selection_screen.dart';
import '../../groups/group_selection_screen.dart';

class ReceiptDetailsCard extends StatelessWidget {
  const ReceiptDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final receiptProvider = Provider.of<ReceiptProvider>(context);
    final receipt = receiptProvider.currentReceipt;

    if (receipt == null) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getCardBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            width: double.infinity,
            child: Text('Receipt Details',
                style:
                    AppStyles.receiptDetailText.copyWith(color: Colors.white)),
          ),
          // Details
          _buildDetailRow(
            context: context,
            label: 'Date',
            value: DateFormat('dd MMMM yyyy').format(receipt.date),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: receipt.date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (date != null) {
                receiptProvider.updateDate(date);
              }
            },
          ),
          _buildDetailRow(
            context: context,
            label: 'Total',
            value: '€ ${receipt.total.toStringAsFixed(2)}',
            onTap: () {
              // Show dialog to edit total
              _showEditTotalDialog(context, receipt.total);
            },
          ),
          _buildDetailRow(
            context: context,
            label: 'Category',
            value: receipt.category == ''
                ? 'No category selected'
                : receipt.category,
            onTap: () {
              // Show category selector
              _showCategorySelector(context, receipt.category);
            },
          ),
          _buildDetailRow(
            context: context,
            label: 'Group',
            value: receipt.group == ''
                ? 'No group selected'
                : _getGroupName(context, receipt.group),
            onTap: () {
              // Show group selector dialog
              _showGroupSelector(context, receipt.group);
            },
            isLast: true,
          ),
          // Removed image preview section
        ],
      ),
    );
  }

  // Helper method to get the group name from its ID
  String _getGroupName(BuildContext context, String groupId) {
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    final group = groupsProvider.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => Group(id: groupId, name: groupId),
    );
    return group.name;
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: AppColors.getCardBorderColor(context)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getTextColor(context),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.getIconColor(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTotalDialog(
    BuildContext context,
    double currentTotal,
  ) async {
    final textController = TextEditingController(text: currentTotal.toString());

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Total'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '€ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTotal =
                  double.tryParse(textController.text) ?? currentTotal;
              Provider.of<ReceiptProvider>(
                context,
                listen: false,
              ).updateTotal(newTotal);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategorySelector(
    BuildContext context,
    String currentCategory,
  ) async {
    // Unfocus any text fields before navigating
    FocusScope.of(context).unfocus();

    // Navigate to the category selection screen instead of showing a dialog
    final selectedCategory = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategorySelectionScreen(currentCategory: currentCategory),
      ),
    );

    // Update the category if a selection was made
    if (selectedCategory != null) {
      Provider.of<ReceiptProvider>(
        context,
        listen: false,
      ).updateCategory(selectedCategory);
    }
  }

  // Show group selector screen
  Future<void> _showGroupSelector(
    BuildContext context,
    String currentGroupId,
  ) async {
    // Unfocus any text fields before navigating
    FocusScope.of(context).unfocus();

    // Navigate to the group selection screen
    final selectedGroupId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GroupSelectionScreen(currentGroupId: currentGroupId),
      ),
    );

    // Update the group if a selection was made
    if (selectedGroupId != null) {
      Provider.of<ReceiptProvider>(
        context,
        listen: false,
      ).updateGroup(selectedGroupId);
    }
  }
}
