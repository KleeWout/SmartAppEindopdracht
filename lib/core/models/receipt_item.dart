/// Model representing an individual item on a receipt
///
/// Stores details about a receipt line item including name, price,
/// and optional assignment to a person in a group.
class ReceiptItem {
  final String id;
  final String name;
  final double price;
  final String? assignedTo;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    this.assignedTo,
  });

  /// Converts this item to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'assignedTo': assignedTo,
    };
  }

  /// Creates a ReceiptItem from a map retrieved from Firestore
  static ReceiptItem fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id'],
      name: map['name'],
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : map['price'],
      assignedTo: map['assignedTo'],
    );
  }

  /// Creates a copy of this item with specified fields replaced
  ReceiptItem copyWith({
    String? id,
    String? name,
    double? price,
    String? assignedTo,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
