import 'package:eindopdracht/widgets/common/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final recentTransactions = transactionProvider.recentTransactions;
    final isLoading = transactionProvider.isLoading;
    final error = transactionProvider.error;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return const Center(
        child: Text(
          'No transactions yet. Add some!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );

      // return Center(
      //   child: Text(
      //     'Error loading transactions: $error',
      //     style: TextStyle(color: Colors.red),
      //     textAlign: TextAlign.center,
      //   ),
      // );
    }

    if (recentTransactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions yet. Add some!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: recentTransactions
          .map((transaction) => TransactionItem(transaction: transaction))
          .toList(),
    );
  }
}
