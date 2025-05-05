import 'package:flutter/material.dart';
import '../../../core/models/transaction.dart';
import '../../../core/constants/app_styles.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to transaction detail screen
        Navigator.pushNamed(
          context,
          '/transaction-detail',
          arguments: transaction,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: Colors.white,
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey[300], radius: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchantName,
                    style: AppStyles.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(transaction.category, style: AppStyles.caption),
                ],
              ),
            ),
            Text(
              '€${transaction.amount.toStringAsFixed(2)}',
              style: AppStyles.amount,
            ),
          ],
        ),
      ),
    );
  }
}
