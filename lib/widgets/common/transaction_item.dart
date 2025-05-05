import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:eindopdracht/core/constants/app_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/models/transaction.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        decoration: BoxDecoration(
            color: AppColors.getCardBackgroundColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getCardBorderColor(context), width: 1),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.receipt, color: Colors.blue[800]),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.merchantName,
                  style: AppStyles.transactionTitle.copyWith(
                  color: AppColors.getTextColor(context),
                  ),
                ),
              ),
              // Show receipt icon if image is available
              if (transaction.receiptImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.image, size: 16, color: Colors.blue[800]),
                ),
            ],
          ),
          subtitle: Text(
            transaction.category,
            style: AppStyles.transactionCategory,
          ),
          trailing: Text(
            '€ ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: transaction.amount < 0 ? Colors.red : Colors.green,
            ),
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/transaction-detail',
              arguments: transaction,
            );
          },
        ),
      ),
    );
  }
}
