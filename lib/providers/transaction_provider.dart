import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/transaction.dart';
import '../core/services/firestore_service.dart';
import '../core/services/storage_service.dart';

class TransactionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService.instance;

  // Main data collections
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _recentTransactions = [];
  Map<String, List<TransactionModel>> _groupTransactions = {};

  // State management
  String? _selectedGroupId;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _error;

  // Stream subscriptions to manage Firestore listeners
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _recentTransactionsSubscription;
  StreamSubscription? _groupTransactionsSubscription;

  TransactionProvider() {
    // Start listening to Firestore
    _initializeFirestore();
  }

  // Initialize all Firestore listeners
  void _initializeFirestore() {
    try {
      // Listen for all transactions
      _transactionsSubscription = _firestoreService.getTransactions().listen(
        (transactions) {
          _transactions = transactions;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = "Failed to load transactions: ${error.toString()}";
          _isLoading = false;
          notifyListeners();
          // print(_error);
        },
      );

      // Listen specifically for recent transactions
      _recentTransactionsSubscription =
          _firestoreService.getRecentTransactions().listen(
        (transactions) {
          _recentTransactions = transactions;
          notifyListeners();
        },
        onError: (error) {
          // Error is already handled by the main subscription
          // print("Error loading recent transactions: ${error.toString()}");
        },
      );

      // Initialize group transactions subscription if a group is selected
      if (_selectedGroupId != null) {
        _subscribeToGroupTransactions(_selectedGroupId!);
      }
    } catch (e) {
      _error = "Initialization error: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      // print(_error);
    }
  }

  // Subscribe to transactions for a specific group
  void _subscribeToGroupTransactions(String groupId) {
    _groupTransactionsSubscription?.cancel();

    _groupTransactionsSubscription =
        _firestoreService.getGroupTransactions(groupId).listen(
      (transactions) {
        _groupTransactions[groupId] = transactions;
        notifyListeners();
      },
      onError: (error) {
        // print("Error loading group transactions: ${error.toString()}");
      },
    );
  }

  // Reload data (useful after auth changes or network reconnects)
  Future<void> refreshData() async {
    if (_isLoading || _isActionInProgress) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Dispose existing subscriptions
    await _transactionsSubscription?.cancel();
    await _recentTransactionsSubscription?.cancel();
    await _groupTransactionsSubscription?.cancel();

    // Clear data
    _groupTransactions = {};

    // Reinitialize Firestore connections
    _initializeFirestore();
  }

  // Handle auth state changes - call this when user logs in/out
  Future<void> handleAuthStateChanged() async {
    // print(
    //   'TransactionProvider: Auth state changed, refreshing transaction data',
    // );
    // Reset selected group
    _selectedGroupId = null;
    // Clear group transactions cache
    _groupTransactions = {};
    // Clear transaction lists to prevent showing previous user's data during reload
    _transactions = [];
    _recentTransactions = [];
    // Notify listeners of the cleared data
    notifyListeners();
    // Refresh all transaction data
    await refreshData();
  }

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get error => _error;
  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  String? get selectedGroupId => _selectedGroupId;

  // Get transactions for the selected group
  List<TransactionModel> get groupTransactions {
    if (_selectedGroupId == null ||
        !_groupTransactions.containsKey(_selectedGroupId)) {
      return [];
    }
    return _groupTransactions[_selectedGroupId]!;
  }

  // Get transactions for a specific group
  List<TransactionModel> getTransactionsForGroup(String groupId) {
    return _groupTransactions[groupId] ?? [];
  }

  // Select a group to view its transactions
  void selectGroup(String? groupId) {
    if (groupId == _selectedGroupId) return;

    _selectedGroupId = groupId;

    if (groupId != null) {
      // Subscribe to the group's transactions if not already loaded
      if (!_groupTransactions.containsKey(groupId)) {
        _subscribeToGroupTransactions(groupId);
      }
    } else {
      // If no group is selected, cancel the group subscription
      _groupTransactionsSubscription?.cancel();
      _groupTransactionsSubscription = null;
    }

    notifyListeners();
  }

  // Group transactions by date for timeline display
  Map<DateTime, List<TransactionModel>> get transactionsByDate {
    final Map<DateTime, List<TransactionModel>> result = {};
    final List<TransactionModel> transactionsToGroup =
        _selectedGroupId != null ? groupTransactions : _transactions;

    for (final transaction in transactionsToGroup) {
      // Normalize date to remove time component
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (!result.containsKey(date)) {
        result[date] = [];
      }

      result[date]!.add(transaction);
    }

    return result;
  }

  // --- CRUD Operations ---

  // Add a new transaction with optional receipt image
  Future<void> addTransaction(
    TransactionModel transaction, {
    File? receiptImage,
  }) async {
    if (_isActionInProgress) return;

    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      // If there's an image to upload, do that first and get the URL
      String? imageUrl;
      if (receiptImage != null) {
        // Ensure we have a valid group ID
        if (transaction.groupId.isEmpty) {
          throw Exception('Cannot upload receipt: Missing group ID');
        }

        try {
          // Use the groupId from the transaction for organizing images
          imageUrl = await _storageService.uploadReceiptImage(
            receiptImage,
            transaction.groupId,
          );
        } catch (e) {
          // print('Error during image upload: $e');
          // Continue without image if upload fails
        }
      }

      // Create the transaction with the image URL if we have one
      final TransactionModel transactionToAdd = imageUrl != null
          ? TransactionModel(
              id: transaction.id,
              merchantName: transaction.merchantName,
              amount: transaction.amount,
              date: transaction.date,
              category: transaction.category,
              groupId: transaction.groupId,
              receiptImagePath: imageUrl, // Use the Firebase Storage URL
              description: transaction.description,
              items: transaction.items,
            )
          : transaction;

      // Only add the transaction to the group's transactions collection
      await _firestoreService.addGroupTransaction(
        transactionToAdd.groupId,
        transactionToAdd,
      );
    } catch (e) {
      _error = "Failed to add transaction: ${e.toString()}";
      notifyListeners();
      // print(_error);
      throw e;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Update an existing transaction with optional new receipt image
  Future<void> updateTransaction(
    TransactionModel transaction, {
    File? receiptImage,
  }) async {
    if (_isActionInProgress) return;

    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      // If there's a new image to upload, do that first and get the URL
      String? imageUrl = transaction.receiptImagePath;
      if (receiptImage != null) {
        // Delete old image if exists
        if (transaction.receiptImagePath != null) {
          try {
            await _storageService.deleteReceiptImage(
              transaction.receiptImagePath!,
            );
          } catch (e) {
            // print('Error deleting old image: $e');
            // Continue even if deletion fails
          }
        }

        // Upload new image using the transaction's groupId
        imageUrl = await _storageService.uploadReceiptImage(
          receiptImage,
          transaction.groupId,
        );
      }

      // Update the transaction with the new image URL if we have one
      final TransactionModel transactionToUpdate = TransactionModel(
        id: transaction.id,
        merchantName: transaction.merchantName,
        amount: transaction.amount,
        date: transaction.date,
        category: transaction.category,
        groupId: transaction.groupId,
        receiptImagePath: imageUrl,
        description: transaction.description,
        items: transaction.items,
      );

      // Only update in the group's transactions collection
      await _firestoreService
          .getGroupTransactionsCollection(transactionToUpdate.groupId)
          .doc(transactionToUpdate.id)
          .update(transactionToUpdate.toMap());
    } catch (e) {
      _error = "Failed to update transaction: ${e.toString()}";
      notifyListeners();
      // print(_error);
      throw e;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Delete a transaction and its associated receipt image
  Future<void> deleteTransaction(String id) async {
    if (_isActionInProgress) return;

    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      // Find the transaction to get its groupId
      final transaction = _transactions.firstWhere(
        (t) => t.id == id,
        orElse: () =>
            _groupTransactions.values.expand((list) => list).firstWhere(
                  (t) => t.id == id,
                  orElse: () => throw Exception('Transaction not found'),
                ),
      );

      // Delete the image from Firebase Storage if it exists
      if (transaction.receiptImagePath != null) {
        try {
          await _storageService.deleteReceiptImage(
            transaction.receiptImagePath!,
          );
        } catch (e) {
          // print('Error deleting image: $e');
          // Continue even if image deletion fails
        }
      }

      // Delete from the group's transactions collection
      await _firestoreService
          .getGroupTransactionsCollection(transaction.groupId)
          .doc(id)
          .delete();
    } catch (e) {
      _error = "Failed to delete transaction: ${e.toString()}";
      notifyListeners();
      // print(_error);
      throw e;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Helper method to get the image file from Firebase Storage
  Future<File?> getReceiptImage(String? imageUrl) async {
    if (imageUrl == null) return null;

    try {
      return await _storageService.getReceiptImage(imageUrl);
    } catch (e) {
      // print('Error getting receipt image: $e');
      return null;
    }
  }

  /// Clears all transaction data when a new user logs in
  void clearData() {
    // Clear all local transaction data
    // Adjust based on your actual implementation
    _transactions = [];
    _recentTransactions = [];
    // Reset any other state variables
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up all subscriptions when provider is disposed
    _transactionsSubscription?.cancel();
    _recentTransactionsSubscription?.cancel();
    _groupTransactionsSubscription?.cancel();
    super.dispose();
  }
}
