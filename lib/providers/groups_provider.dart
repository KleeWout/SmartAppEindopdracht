import 'package:flutter/foundation.dart';
import 'dart:async';
import '../core/models/group.dart';
import '../core/services/firestore_service.dart';

class GroupsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Group> _groups = [];
  StreamSubscription? _groupsSubscription;
  String? _error;
  bool _isLoading = false;
  bool _isActionInProgress = false;

  // Constructor - initialize listener
  GroupsProvider() {
    _initializeFirestore();
  }

  // Initialize Firestore connection
  void _initializeFirestore() {
    _isLoading = true;
    notifyListeners();

    try {
      _groupsSubscription = _firestoreService.getUserGroups().listen(
        (groups) {
          _groups = groups;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = "Error loading groups: $error";
          _isLoading = false;
          notifyListeners();
          // print(_error);
        },
      );
    } catch (e) {
      _error = "Failed to initialize groups: $e";
      _isLoading = false;
      notifyListeners();
      // print(_error);
    }
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    super.dispose();
  }

  // Getters
  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get error => _error;

  // Handle auth state changes - call this when user logs in/out
  Future<void> handleAuthStateChanged() async {
    // print('GroupsProvider: Auth state changed, refreshing groups data');
    await reset(); // This cancels existing subscriptions, clears data, and reinitializes
  }

  // Reset provider state (e.g., after logout)
  Future<void> reset() async {
    await _groupsSubscription?.cancel();
    _groups = [];
    _isLoading = false;
    _isActionInProgress = false;
    _error = null;
    notifyListeners();

    // Reinitialize Firestore connection
    _initializeFirestore();
  }

  // Add a new group
  Future<void> addGroup(Group group) async {
    if (_isActionInProgress) return;

    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.addUserGroup(group);
    } catch (e) {
      _error = "Failed to add group: ${e.toString()}";
      notifyListeners();
      // print(_error);
      throw e;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Join an existing group
  Future<void> joinGroup(Group group) async {
    if (_isActionInProgress) return;

    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.joinExistingGroup(group);
    } catch (e) {
      _error = "Failed to join group: ${e.toString()}";
      notifyListeners();
      // print(_error);
      throw e;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Update an existing group
  Future<void> updateGroup(Group group) async {
    if (_isActionInProgress) return;

    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateUserGroup(group);
    } catch (e) {
      _error = "Failed to update group: ${e.toString()}";
      notifyListeners();
      // print(_error);
      throw e;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Delete a group
  Future<void> deleteGroup(String id) async {
    if (_isActionInProgress) return;

    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deleteUserGroup(id);
    } catch (e) {
      _error = "Failed to delete group: ${e.toString()}";
      notifyListeners();
      // print(_error);
      throw e;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  // Get a group by ID
  Group? getGroupById(String id) {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index != -1) {
      return _groups[index];
    }
    return null;
  }

  // Toggle favorite status of a group
  Future<void> toggleFavorite(String id) async {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index != -1) {
      final group = _groups[index];
      final updatedGroup = group.copyWith(isFavorite: !group.isFavorite);

      await updateGroup(updatedGroup);
    }
  }

  // For backward compatibility with any existing code
  void loadInitialData() {
    // This method no longer loads mock data
    // It's kept for compatibility with existing code
    // All data is now loaded from Firestore in _initializeFirestore()
    if (_groups.isEmpty) {
      _initializeFirestore();
    }
  }

  /// Clears all group data when a user's account is deleted
  void clearData() {
    // Cancel any active subscriptions
    _groupsSubscription?.cancel();
    _groupsSubscription = null;

    // Clear all group data
    _groups = [];
    _isLoading = false;
    _isActionInProgress = false;
    _error = null;

    // Notify listeners of the change
    notifyListeners();
  }
}
