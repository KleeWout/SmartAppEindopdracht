import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:eindopdracht/core/constants/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/receipt_provider.dart';
import '../../../core/models/receipt_item.dart';

class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, _) {
        final receipt = provider.currentReceipt;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items',
                      style: AppStyles.receiptDetailText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        provider.addItem();
                      },
                    ),
                  ],
                ),
              ),
              // Items list
              if (receipt.items.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: receipt.items.length,
                  itemBuilder: (context, index) {
                    return ItemRowWidget(
                      item: receipt.items[index],
                      isLast: index == receipt.items.length - 1,
                    );
                  },
                ),
              if (receipt.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No items yet. Click the + button to add items.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Create a StatefulWidget for each item row to properly manage input controllers
class ItemRowWidget extends StatefulWidget {
  final ReceiptItem item;
  final bool isLast;

  const ItemRowWidget({
    super.key,
    required this.item,
    this.isLast = false,
  });

  @override
  State<ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<ItemRowWidget> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    // Use the price value without forcing two decimal places
    _priceController = TextEditingController(
      text: widget.item.price.toString().replaceAll(RegExp(r'\.0+$'), ''),
    );
  }

  @override
  void didUpdateWidget(ItemRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers only if the item has changed
    if (oldWidget.item.name != widget.item.name) {
      _nameController.text = widget.item.name;
    }
    if (oldWidget.item.price != widget.item.price) {
      // Don't force two decimal places
      _priceController.text =
          widget.item.price.toString().replaceAll(RegExp(r'\.0+$'), '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReceiptProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: widget.isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.getCardBorderColor(context)),
        ),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: 20, vertical: widget.isLast ? 4 : 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Item name',
                hintStyle: TextStyle(color: AppColors.getTextColor(context)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              controller: _nameController,
              onChanged: (value) {
                provider.updateItemName(widget.item.id, value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Price',
                hintStyle: TextStyle(color: AppColors.grey),
                prefixText: '€ ',
                prefixStyle: TextStyle(color: Colors.black, fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.number,
              controller: _priceController,
              onTap: () {
                if (_priceController.text.isNotEmpty) {
                  _priceController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _priceController.text.length,
                  );
                }
              },
              onChanged: (value) {
                try {
                  // Only convert comma to period if user entered a comma
                  final price =
                      double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                  provider.updateItemPrice(widget.item.id, price);

                  // Don't call setState or let the controller update from didUpdateWidget
                  // while the user is still typing
                } catch (e) {
                  // Safely handle parsing errors
                  provider.updateItemPrice(widget.item.id, 0.0);
                }
              },
              // Don't auto-format the price when user finishes typing
              onEditingComplete: () {
                // Do nothing here to preserve user's input format
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              provider.removeItem(widget.item.id);
            },
          ),
        ],
      ),
    );
  }

  // The methods below are kept for functionality but made invisible in the UI
  // They would be used when editing items in a more detailed view

  Widget _buildEditableItemRow(BuildContext context) {
    final provider = Provider.of<ReceiptProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Item name',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              controller: _nameController,
              onChanged: (value) {
                provider.updateItemName(widget.item.id, value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Price',
                prefixText: '€ ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.number,
              controller: _priceController,
              onTap: () {
                // Select all text in input
                _priceController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _priceController.text.length,
                );
              },
              onChanged: (value) {
                final price = double.tryParse(value) ?? 0.0;
                provider.updateItemPrice(widget.item.id, price);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              provider.removeItem(widget.item.id);
            },
          ),
        ],
      ),
    );
  }
}
