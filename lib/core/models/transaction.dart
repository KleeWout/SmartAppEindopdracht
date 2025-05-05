import 'package:cloud_firestore/cloud_firestore.dart';
import 'receipt_item.dart';

/// A model representing a financial transaction in the app
///
/// Contains details about a purchase including merchant information,
/// amount, date, category, and optional receipt details.
class TransactionModel {
  final String id;
  final String merchantName;
  late final double amount;
  final DateTime date;
  final String category;
  final String groupId; // Required, not nullable
  final String? receiptImagePath;
  final String? description;
  late final List<ReceiptItem>? items;

  TransactionModel({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    required this.groupId,
    this.receiptImagePath,
    this.description,
    this.items,
  });

  /// Creates a TransactionModel from a Firestore document map
  ///
  /// Handles various data formats and type conversions for robustness
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // Handle different types for amount (int, double, or string)
    double amount;
    if (map['amount'] is int) {
      amount = (map['amount'] as int).toDouble();
    } else if (map['amount'] is String) {
      try {
        // Safely handle string conversion to double
        final stringAmount = map['amount'] as String;
        if (stringAmount.isEmpty) {
          amount = 0.0; // Default to zero for empty strings
        } else {
          amount = double.parse(stringAmount);
        }
      } catch (e) {
        print('Error parsing amount: ${map['amount']}');
        amount = 0.0;
      }
    } else if (map['amount'] is double) {
      amount = map['amount'] as double;
    } else {
      // Handle null or unexpected types
      print('Unexpected amount type: ${map['amount']}');
      amount = 0.0;
    }

    // Convert Firestore Timestamp to DateTime
    DateTime date;
    if (map['date'] is Timestamp) {
      date = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      date = DateTime.parse(map['date']);
    } else {
      throw FormatException('Invalid date format in Firestore document');
    }

    // Parse receipt items if they exist
    List<ReceiptItem>? items;
    if (map['items'] != null) {
      items = (map['items'] as List)
          .map((item) => ReceiptItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return TransactionModel(
      id: map['id'],
      merchantName: map['merchantName'],
      amount: amount,
      date: date,
      category: map['category'],
      groupId: map['groupId'] ?? '', // Ensure we always have a groupId
      receiptImagePath: map['receiptImagePath'],
      description: map['description'],
      items: items,
    );
  }

  /// Converts this transaction to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantName': merchantName,
      'amount': amount,
      'date': Timestamp.fromDate(
          date), // Store as Timestamp for Firestore compatibility
      'category': category,
      'groupId': groupId,
      'receiptImagePath': receiptImagePath,
      'description': description,
      'items': items?.map((item) => item.toMap()).toList(),
    };
  }
}
