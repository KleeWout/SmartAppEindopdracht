// import 'package:flutter/foundation.dart';
// import '../models/transaction.dart';
// import '../models/receipt.dart';
// import '../models/group.dart';

// class DatabaseService {
//   // Singleton pattern
//   DatabaseService._privateConstructor();
//   static final DatabaseService _instance = DatabaseService._privateConstructor();
//   static DatabaseService get instance => _instance;
  
//   // Mock database for development
//   final List<TransactionModel> _transactions = [];
//   final List<Group> _groups = [];
//   final List<Receipt> _receipts = [];
  
//   // Transaction methods
//   Future<List<TransactionModel>> getTransactions() async {
//     // In a real app, this would be a database query
//     await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
//     return _transactions;
//   }
  
//   Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     return _transactions.take(limit).toList();
//   }
  
//   Future<void> addTransaction(TransactionModel transaction) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     _transactions.add(transaction);
//   }
  
//   // Group methods
//   Future<List<Group>> getGroups() async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     return _groups;
//   }
  
//   Future<void> addGroup(Group group) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     _groups.add(group);
//   }
  
//   // Receipt methods
//   Future<void> addReceipt(Receipt receipt) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     _receipts.add(receipt);
    
//     // Add corresponding transaction
//     final transaction = TransactionModel(
//       id: receipt.id,
//       merchantName: receipt.merchantName,
//       amount: receipt.total,
//       date: receipt.date,
//       category: receipt.category,
//       // groupId: receipt.groupId,
//       groupId: receipt.group,
//     );
    
//     await addTransaction(transaction);
//   }
  
//   Future<Receipt?> getReceiptById(String id) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     try {
//       return _receipts.firstWhere((receipt) => receipt.id == id);
//     } catch (e) {
//       return null;
//     }
//   }
// }