import 'receipt_item.dart';

class Receipt {
  final String id;
  final String merchantName;
  final DateTime date;
  final double total;
  final String category;
  final String group;
  final List<ReceiptItem> items;
  final String? imagePath;
  final String? description; // Added description field

  Receipt({
    required this.id,
    required this.merchantName,
    required this.date,
    required this.total,
    required this.category,
    required this.group,
    required this.items,
    this.imagePath,
    this.description, // Added description parameter
  });

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      merchantName: map['merchantName'],
      date: DateTime.parse(map['date']),
      total: map['total'],
      category: map['category'],
      group: map['group'],
      items:
          (map['items'] as List)
              .map((item) => ReceiptItem.fromMap(item))
              .toList(),
      imagePath: map['imagePath'],
      description: map['description'], // Added description
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantName': merchantName,
      'date': date.toIso8601String(),
      'total': total,
      'category': category,
      'group': group,
      'items': items.map((item) => item.toMap()).toList(),
      'imagePath': imagePath,
      'description': description, // Added description
    };
  }
}
