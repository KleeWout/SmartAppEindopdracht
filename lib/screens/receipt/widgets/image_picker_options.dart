import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../providers/receipt_provider.dart';
import '../../../core/services/receipt_analyzer_service.dart';
import '../../../core/constants/app_colors.dart';

class ImagePickerOptions extends StatelessWidget {
  const ImagePickerOptions({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        if (!context.mounted) return;

        // Show loading indicator
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Processing receipt image...')),
        );

        // Update the receipt with the new image
        final provider = Provider.of<ReceiptProvider>(context, listen: false);
        provider.updateImage(image.path);

        // Analyze the receipt with ML Kit for both camera and gallery images
        final receiptAnalyzer = ReceiptAnalyzerService();
        final receiptData = await receiptAnalyzer.analyzeReceipt(image.path);

        if (!context.mounted) return;

        // Update the receipt with the extracted data
        if (receiptData.merchantName.isNotEmpty) {
          print("Setting merchant name to: ${receiptData.merchantName}");
          // Force UI update with a small delay to ensure the provider update is processed
          Future.microtask(() {
            provider.updateMerchantName(receiptData.merchantName);
          });
        }

        if (receiptData.totalAmount > 0) {
          print("Setting total amount to: ${receiptData.totalAmount}");
          provider.updateTotal(receiptData.totalAmount);
        }

        if (receiptData.date != null) {
          print("Setting date to: ${receiptData.date}");
          provider.updateDate(receiptData.date!);
        }

        if (receiptData.possibleCategory.isNotEmpty) {
          print("Setting category to: ${receiptData.possibleCategory}");
          provider.updateCategory(receiptData.possibleCategory);
        }

        // Add the extracted items to the receipt
        if (receiptData.items.isNotEmpty) {
          print("Adding ${receiptData.items.length} items to receipt");
          // Clear existing items first (if any)
          provider.clearItems();

          // Add each extracted item
          for (final item in receiptData.items) {
            provider.addItemWithData(item.name, item.price);
          }
        }

        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Receipt processed with ${receiptData.items.length} items! Check and adjust details if needed.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error processing image: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current receipt from the provider to access imagePath
    final provider = Provider.of<ReceiptProvider>(context);
    final receipt = provider.currentReceipt;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          'Add receipt',
          style: TextStyle(
              fontSize: 18, color: AppColors.getSecondaryTextColor(context)),
        ),
      ),
      // Display image preview if available
      if (receipt?.imagePath != null && receipt!.imagePath!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.getCardBorderColor(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(receipt.imagePath!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickImage(context, ImageSource.camera),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.getColor(context, Colors.grey.shade300,
                          AppColors.borderGray1Dark)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt, color: AppColors.primary, size: 24),
                    const SizedBox(height: 8),
                    Text('Camera',
                        style: TextStyle(
                            color: AppColors.getColor(context,
                                AppColors.primary, AppColors.primaryDark))),
                    Text(
                      'Scan Receipt',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.getColor(context, AppColors.primary,
                              AppColors.primaryDark)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _pickImage(context, ImageSource.gallery),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.getColor(context, Colors.grey.shade300,
                          AppColors.borderGray1Dark)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library,
                        color: AppColors.getColor(
                            context, Colors.grey, AppColors.greyDark),
                        size: 24),
                    const SizedBox(height: 8),
                    Text('Gallery',
                        style: TextStyle(
                            color: AppColors.getColor(
                                context, Colors.grey, AppColors.greyDark))),
                    Text(
                      'Choose from Gallery',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.getColor(
                              context, Colors.grey, AppColors.greyDark)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
    ]);
  }
}
