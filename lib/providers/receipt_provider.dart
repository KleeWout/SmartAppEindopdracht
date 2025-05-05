import 'package:flutter/foundation.dart';
import '../core/models/receipt.dart';
import '../core/models/receipt_item.dart';
import 'package:uuid/uuid.dart';

class ReceiptProvider extends ChangeNotifier {
  Receipt? _currentReceipt;

  Receipt? get currentReceipt => _currentReceipt;

  String get merchantName => _currentReceipt?.merchantName ?? '';
  String get category => _currentReceipt?.category ?? '';
  String get groupId => _currentReceipt?.group ?? '';
  DateTime get date => _currentReceipt?.date ?? DateTime.now();
  String? get description =>
      _currentReceipt?.description; // Added getter for description

  void initNewReceipt({String? merchantName}) {
    _currentReceipt = Receipt(
      id: const Uuid().v4(),
      merchantName: merchantName ?? '',
      date: DateTime.now(),
      total: 0.0,
      category: '',
      group: '',
      items: [], // Initialize with an empty list instead of default items
      description: '', // Initialize with empty string instead of null
    );
    notifyListeners();
  }

  void updateMerchantName(String name) {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: name,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: _currentReceipt!.items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateDate(DateTime date) {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: _currentReceipt!.items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateTotal(double total) {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: _currentReceipt!.items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateCategory(String category) {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: category,
        group: _currentReceipt!.group,
        items: _currentReceipt!.items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateGroup(String groupId) {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: groupId,
        items: _currentReceipt!.items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateImage(String imagePath) {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: _currentReceipt!.items,
        imagePath: imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  // New method to clear all items
  void clearItems() {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: [], // Empty items list
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description,
      );
      notifyListeners();
    }
  }

  // New method to add an item with predefined data
  void addItemWithData(String itemName, double itemPrice) {
    if (_currentReceipt != null) {
      final items = List<ReceiptItem>.from(_currentReceipt!.items);
      items.add(
        ReceiptItem(id: const Uuid().v4(), name: itemName, price: itemPrice),
      );

      // Calculate new total based on all items
      double newTotal = 0;
      for (var item in items) {
        newTotal += item.price;
      }

      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: newTotal, // Update total based on item prices
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description,
      );
      notifyListeners();
    }
  }

  void addItem() {
    if (_currentReceipt != null) {
      final items = List<ReceiptItem>.from(_currentReceipt!.items);
      items.add(
        ReceiptItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '',
          price: 0,
        ),
      );

      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateItemName(String itemId, String name) {
    if (_currentReceipt != null) {
      final items = _currentReceipt!.items.map((item) {
        if (item.id == itemId) {
          return ReceiptItem(id: item.id, name: name, price: item.price);
        }
        return item;
      }).toList();

      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateItemPrice(String itemId, double price) {
    if (_currentReceipt != null) {
      final items = _currentReceipt!.items.map((item) {
        if (item.id == itemId) {
          return ReceiptItem(id: item.id, name: item.name, price: price);
        }
        return item;
      }).toList();

      // Also update the total based on all items
      double newTotal = 0;
      for (var item in items) {
        newTotal += item.price;
      }

      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: newTotal,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void removeItem(String itemId) {
    if (_currentReceipt != null) {
      final items =
          _currentReceipt!.items.where((item) => item.id != itemId).toList();

      // Update the total based on remaining items
      double newTotal = 0;
      for (var item in items) {
        newTotal += item.price;
      }

      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: newTotal,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: items,
        imagePath: _currentReceipt!.imagePath,
        description: _currentReceipt!.description, // Preserve description
      );
      notifyListeners();
    }
  }

  void updateDescription(String description) {
    if (_currentReceipt != null) {
      _currentReceipt = Receipt(
        id: _currentReceipt!.id,
        merchantName: _currentReceipt!.merchantName,
        date: _currentReceipt!.date,
        total: _currentReceipt!.total,
        category: _currentReceipt!.category,
        group: _currentReceipt!.group,
        items: _currentReceipt!.items,
        imagePath: _currentReceipt!.imagePath,
        description: description,
      );
      notifyListeners();
    }
  }

  void resetReceipt() {
    _currentReceipt = null;
    notifyListeners();
  }

  /// Clears all receipt data when a user logs out
  void clearData() {
    // Reset the current receipt to ensure no data is carried over between users
    _currentReceipt = null;
    notifyListeners();
  }
}
