import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../providers/receipt_provider.dart';
import '../../../providers/groups_provider.dart';
import '../category_selection_screen.dart';

class ReceiptForm extends StatefulWidget {
  const ReceiptForm({super.key});

  @override
  _ReceiptFormState createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<ReceiptForm> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  String _selectedCategory = 'None';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final receiptProvider = Provider.of<ReceiptProvider>(
      context,
      listen: false,
    );
    _merchantController.text = receiptProvider.merchantName;
    _selectedCategory = receiptProvider.category;
    _selectedDate = receiptProvider.date;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<GroupsProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merchant input
          TextFormField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: 'Merchant name',
              labelStyle: AppStyles.inputLabel,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: AppStyles.body,
            onChanged: (value) {
              Provider.of<ReceiptProvider>(
                context,
                listen: false,
              ).updateMerchantName(value);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter merchant name';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Date picker
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date', style: AppStyles.inputLabel),
                  Text(
                    '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: AppStyles.body,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Category selector
          GestureDetector(
            onTap: () => _selectCategory(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Category', style: AppStyles.inputLabel),
                  Row(
                    children: [
                      Text(_selectedCategory, style: AppStyles.body),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      Provider.of<ReceiptProvider>(context, listen: false).updateDate(picked);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];

    return months[month - 1];
  }

  Future<void> _selectCategory(BuildContext context) async {
    // Navigate to the category selection screen
    final selectedCategory = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CategorySelectionScreen(currentCategory: _selectedCategory),
      ),
    );

    // Update the category if a selection was made
    if (selectedCategory != null) {
      setState(() {
        _selectedCategory = selectedCategory;
      });
      Provider.of<ReceiptProvider>(
        context,
        listen: false,
      ).updateCategory(selectedCategory);
    }
  }
}
