import 'dart:io';
import 'package:eindopdracht/widgets/common/form_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/models/transaction.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/app_dialog.dart';
import 'widgets/image_picker_options.dart';
import 'widgets/receipt_details_card.dart';
import 'widgets/item_list.dart';

/// Screen for adding new receipts to the app
///
/// Allows users to enter receipt details, add items, select categories
/// and groups, and attach images.
class AddReceiptScreen extends StatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _merchantNameController;
  bool _hasAttemptedSubmit = false;
  bool _hasEditedMerchantField = false;
  // Focus node to help manage keyboard focus
  final FocusNode _unfocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _merchantNameController = TextEditingController();

    // Initialize receipt data after the widget is built
    Future.microtask(() {
      final receiptProvider = Provider.of<ReceiptProvider>(
        context,
        listen: false,
      );
      receiptProvider.initNewReceipt();

      // Set the initial values of the controllers after the receipt is initialized
      _descriptionController.text = receiptProvider.description ?? '';
      _merchantNameController.text = receiptProvider.merchantName;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _merchantNameController.dispose();
    _unfocusNode.dispose();
    super.dispose();
  }

  // Helper method to unfocus any active text fields
  void _unfocusTextFields() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Unfocus when tapping outside of any text field
      onTap: _unfocusTextFields,
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.getAppBarBackgroundColor(context),
          title: const Text('Add receipt'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<ReceiptProvider>(
          builder: (context, receiptProvider, _) {
            final receipt = receiptProvider.currentReceipt;

            if (receipt == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Sync text controllers with provider data when it changes
            if (_merchantNameController.text != receipt.merchantName) {
              _merchantNameController.text = receipt.merchantName;
            }
            if (_descriptionController.text != receipt.description) {
              _descriptionController.text = receipt.description ?? '';
            }

            return NotificationListener<OverscrollIndicatorNotification>(
              // Unfocus text fields when scrolling begins to improve UX
              onNotification: (notification) {
                _unfocusTextFields();
                return false;
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merchant Name Field with validation
                      FormFieldWidget(
                        controller: _merchantNameController,
                        label: 'Name',
                        hint: 'Enter a name (required)',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        errorText:
                            (_hasAttemptedSubmit || _hasEditedMerchantField) &&
                                    _merchantNameController.text.isEmpty
                                ? 'Please enter a name'
                                : null,
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          setState(() {
                            _hasEditedMerchantField = true;
                          });
                          // Update the provider with new merchant name
                          Provider.of<ReceiptProvider>(context, listen: false)
                              .updateMerchantName(value);
                        },
                        suffixIcon: _merchantNameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _merchantNameController.clear();
                                  setState(() {
                                    _hasEditedMerchantField = true;
                                  });
                                  // Clear merchant name in provider
                                  Provider.of<ReceiptProvider>(context,
                                          listen: false)
                                      .updateMerchantName('');
                                },
                              ) as Widget
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Optional Description Field
                      FormFieldWidget(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Enter description',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          // Update the description in the receipt provider
                          Provider.of<ReceiptProvider>(context, listen: false)
                              .updateDescription(value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Image picker section
                      GestureDetector(
                        onTap: _unfocusTextFields,
                        child: const ImagePickerOptions(),
                      ),
                      const SizedBox(height: 24),

                      // Receipt details section (date, category, group)
                      GestureDetector(
                        onTap: _unfocusTextFields,
                        child: const ReceiptDetailsCard(),
                      ),
                      const SizedBox(height: 24),

                      // Receipt items list
                      const ItemList(),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: AppColors.getPrimaryButtonStyle(context),
                          onPressed: () => _saveReceipt(context),
                          child: const Text(
                            'Save Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Save the receipt as a transaction in Firestore
  ///
  /// Validates all required fields, shows loading dialog during save,
  /// and handles success/error cases appropriately.
  void _saveReceipt(BuildContext context) async {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (_formKey.currentState!.validate()) {
      final receiptProvider = Provider.of<ReceiptProvider>(
        context,
        listen: false,
      );
      final receipt = receiptProvider.currentReceipt;

      if (receipt != null) {
        // Validate required fields before saving
        if (receipt.merchantName.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a merchant name')),
          );
          return;
        }
        if (receipt.category == '') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category')),
          );
          return;
        }
        if (receipt.group == '') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a group')),
          );
          return;
        }

        // Show loading dialog during save operation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Saving receipt...'),
            if (receipt.imagePath != null) ...[
              const SizedBox(height: 8),
              const Text('Uploading image...'),
            ],
          ],
              ),
            );
          },
        );

        try {
          // Convert receipt to transaction model
          final transaction = TransactionModel(
            id: receipt.id,
            merchantName: receipt.merchantName,
            amount: receipt.total,
            date: receipt.date,
            category: receipt.category,
            groupId: receipt.group,
            description: receipt.description,
            receiptImagePath: null, // Will be set by TransactionProvider
            items: receipt.items,
          );

          final transactionProvider = Provider.of<TransactionProvider>(
            context,
            listen: false,
          );

          // Add transaction with image if available
          File? imageFile =
              receipt.imagePath != null ? File(receipt.imagePath!) : null;
          await transactionProvider.addTransaction(
            transaction,
            receiptImage: imageFile,
          );

          // Refresh transaction data to show the new entry
          await transactionProvider.refreshData();

          // Reset receipt provider for next use
          receiptProvider.resetReceipt();

          if (mounted) {
            // Close the loading dialog
            Navigator.of(context).pop();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt saved successfully')),
            );

            // Return to previous screen
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            // Close the loading dialog
            Navigator.of(context).pop();

            // Show error message with details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving receipt: ${e.toString()}')),
            );
          }
        }
      }
    }
  }
}
