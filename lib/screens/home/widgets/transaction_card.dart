import 'package:flutter/material.dart';
import '../../../core/models/transaction.dart';
import '../../../core/constants/app_styles.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionCard({Key? key, required this.transaction})
    : super(key: key);

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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.cardRadius),
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey[300], radius: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchantName,
                      style: AppStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
      ),
    );
  }
}
