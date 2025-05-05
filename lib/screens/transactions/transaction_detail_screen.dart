import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants/app_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/app_dialog.dart';
import '../receipt/category_selection_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _merchantNameController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;

  // Transaction date
  late DateTime _selectedDate;

  bool _isEditing = false;
  File? _receiptImageFile;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with transaction data
    _merchantNameController = TextEditingController(
      text: widget.transaction.merchantName,
    );
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _categoryController = TextEditingController(
      text: widget.transaction.category,
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description ?? '',
    );
    _selectedDate = widget.transaction.date;

    // Load receipt image
    if (widget.transaction.receiptImagePath != null) {
      _loadReceiptImage();
    }
  }

  /// Load the receipt image from Firebase Storage
  Future<void> _loadReceiptImage() async {
    if (widget.transaction.receiptImagePath == null) return;

    setState(() {
      _isLoadingImage = true;
    });

    try {
      final imageFile = await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).getReceiptImage(widget.transaction.receiptImagePath);

      if (mounted) {
        setState(() {
          _receiptImageFile = imageFile;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      // print('Error loading receipt image: $e');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    _merchantNameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (_isEditing) {
          // Show confirmation dialog when trying to leave while editing
          final shouldDiscard = await _showDiscardChangesDialog(context);
          if (shouldDiscard && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(context),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _isEditing ? 'Edit Transaction' : 'Receipt Details',
            style: AppStyles.heading.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            // Edit button (visible when not in edit mode)
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
            // Save button (visible in edit mode)
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _saveChanges,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main transaction details (merchant, amount, date, category)
              _buildTransactionDetailsCard(),
              const SizedBox(height: 16),

              // Receipt image (if available)
              if (widget.transaction.receiptImagePath != null)
                _buildReceiptImageCard(),
              const SizedBox(height: 16),

              // Receipt items (if available)
              if (widget.transaction.items != null &&
                  widget.transaction.items!.isNotEmpty)
                _buildItemsCard(),
              const SizedBox(height: 24),

              // Delete transaction button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _showDeleteConfirmation,
                  child: const Text(
                    'Delete Transaction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card displaying transaction core details
  Widget _buildTransactionDetailsCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.getCardBorderColor(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant name field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Name', style: AppStyles.transactionTitle),
                const SizedBox(height: 12),
                _isEditing
                    ? TextField(
                        controller: _merchantNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Name',
                          contentPadding: EdgeInsets.all(12),
                        ),
                      )
                    : Text(
                        widget.transaction.merchantName,
                        style: AppStyles.body
                            .copyWith(color: AppColors.getTextColor(context)),
                      ),
              ],
            ),

            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),

            // Description field (now directly below merchant name)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: AppStyles.transactionTitle),
                const SizedBox(height: 8),
                _isEditing
                    ? TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Add a description',
                          hintStyle:
                              TextStyle(color: AppColors.getTextColor(context)),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        maxLines: 2,
                      )
                    : widget.transaction.description == null ||
                            widget.transaction.description!.isEmpty
                        ? Text(
                            'No description',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.getTextColor(context),
                            ),
                          )
                        : Text(
                            widget.transaction.description!,
                            style: TextStyle(
                              color: AppColors.getTextColor(context),
                            ),
                          ),
              ],
            ),

            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),

            // Amount field
            _buildAmountField(),

            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),

            // Date field
            _buildDateField(),

            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),

            // Category field
            _buildCategoryField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.getCardBorderColor(context),
    );
  }

  /// Card displaying receipt image
  Widget _buildReceiptImageCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.getCardBorderColor(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receipt Image', style: AppStyles.transactionTitle),
            const SizedBox(height: 12),
            if (_isLoadingImage)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.transaction.receiptImagePath!.startsWith('http')
                    ? Image.network(
                        widget.transaction.receiptImagePath!,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, _) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20.0,
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 50,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Error loading image',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : _receiptImageFile != null
                        ? Image.file(_receiptImageFile!)
                        : const Center(
                            child: Text(
                              'Image not available',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ),
              ),
          ],
        ),
      ),
    );
  }

  /// Card displaying receipt items breakdown
  Widget _buildItemsCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.getCardBorderColor(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receipt Items', style: AppStyles.transactionTitle),
            const SizedBox(height: 12),
            Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.lightGrey, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Item',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextColor(context),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Price',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextColor(context),
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),

                // Items list
                if (widget.transaction.items != null)
                  ...widget.transaction.items!.map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.getCardBorderColor(context),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.name,
                              style: TextStyle(
                                  color: AppColors.getTextColor(context)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '€ ${item.price.toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  color: AppColors.getTextColor(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Total row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextColor(context),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '€ ${widget.transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextColor(context),
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Merchant name field (read-only or editable)

  /// Amount field (read-only or editable)
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount', style: AppStyles.transactionTitle),
        const SizedBox(height: 12),
        _isEditing
            ? TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Amount',
                  prefixText: '€ ',
                  contentPadding: EdgeInsets.all(12),
                ),
                keyboardType: TextInputType.number,
              )
            : Text(
                '€ ${widget.transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextColor(context),
                ),
              ),
      ],
    );
  }

  /// Date field (read-only or date picker)
  Widget _buildDateField() {
    final dateFormat = DateFormat('MMMM d, y');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date', style: AppStyles.transactionTitle),
        const SizedBox(height: 12),
        _isEditing
            ? InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary:
                                AppColors.getCardBackgroundColor(context),
                            surface: AppColors.getCardBackgroundColor(context),
                            onSurface: AppColors.getTextColor(context),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.getEditTransactionBorder(context)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateFormat.format(_selectedDate)),
                      const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              )
            : Text(
                dateFormat.format(widget.transaction.date),
                style: AppStyles.body.copyWith(
                  color: AppColors.getTextColor(context),
                ),
              ),
      ],
    );
  }

  /// Category field (read-only or category picker)
  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: AppStyles.transactionTitle),
        const SizedBox(height: 12),
        _isEditing
            ? InkWell(
                onTap: () {
                  _showCategorySelector(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.getEditTransactionBorder(context)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_categoryController.text),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.getCardBorderColor(context),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.transaction.category,
                      style: TextStyle(
                        color: AppColors.getTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  /// Opens category selection screen
  Future<void> _showCategorySelector(BuildContext context) async {
    // Navigate to the category selection screen
    final selectedCategory = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          currentCategory: _categoryController.text,
        ),
      ),
    );

    // Update the category if a selection was made
    if (selectedCategory != null) {
      setState(() {
        _categoryController.text = selectedCategory;
      });
    }
  }

  /// Save changes to the transaction
  void _saveChanges() async {
    // Validate input
    String amountText = _amountController.text;

    // Only convert comma to period if the user manually entered a comma
    if (amountText.contains(',')) {
      amountText = amountText.replaceAll(',', '.');
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Show loading dialog
    AppDialog.showLoading(
      context,
      message: 'Saving changes...',
      dismissible: false,
    );

    try {
      // Create updated transaction
      final updatedTransaction = TransactionModel(
        id: widget.transaction.id,
        merchantName: _merchantNameController.text,
        amount: amount,
        date: _selectedDate,
        category: _categoryController.text,
        groupId: widget.transaction.groupId,
        receiptImagePath: widget.transaction.receiptImagePath,
        description: _descriptionController.text,
        items: widget.transaction.items, // Preserve the receipt items
      );

      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).updateTransaction(updatedTransaction);

      if (mounted) {
        // Refresh data to show updated changes
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).refreshData();

        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );

        // Navigate back to previous screen to see refreshed data
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation() async {
    // Show dialog to confirm deletion
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            // Only pop the dialog here, don't call _deleteTransaction directly
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // If user confirmed deletion, then call delete
    if (result == true) {
      await _deleteTransaction();
    }
  }

  /// Delete the transaction
  Future<void> _deleteTransaction() async {
    // Show loading dialog
    AppDialog.showLoading(
      context,
      message: 'Deleting transaction...',
      dismissible: false,
    );

    try {
      // Delete the transaction
      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).deleteTransaction(widget.transaction.id);

      // Refresh the transaction data
      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).refreshData();

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Simply navigate back to previous screen (don't show snackbar on previous screen)
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  /// Show dialog to confirm discarding changes
  Future<bool> _showDiscardChangesDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
