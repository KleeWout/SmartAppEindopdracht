import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import to access navigatorKey
import 'transaction_provider.dart';
import 'groups_provider.dart';
import 'receipt_provider.dart';
import 'category_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService) {
    _initUser();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final bool wasSignedIn = _user != null;
      final bool isSignedIn = user != null;
      _user = user;

      // If a new user has signed in, notify providers to refresh their data
      if (isSignedIn &&
          (!wasSignedIn || (wasSignedIn && _user?.uid != user?.uid))) {
        _notifyProvidersOfAuthChange();
      }

      notifyListeners();
    });
  }

  void _initUser() {
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> updateProfile({String? displayName}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user != null) {
        await _user!.updateDisplayName(displayName ?? _user!.displayName);

        // Reload user to get updated information
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user == null || _user!.email == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );

      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(newPassword);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      // Clear data in all providers before signing out
      // Use navigatorKey to get context without BuildContext
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Clear transaction data
        Provider.of<TransactionProvider>(context, listen: false).clearData();

        // You may need to add similar methods to other providers and call them here
        // For example:
        Provider.of<GroupsProvider>(context, listen: false).clearData();
        Provider.of<ReceiptProvider>(context, listen: false).clearData();
        Provider.of<CategoryProvider>(context, listen: false).clearData();
      }

      // Sign out user
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // Notify all relevant providers that auth state has changed (new user logged in)
  void _notifyProvidersOfAuthChange() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Tell transaction provider to refresh data for the new user
      Provider.of<TransactionProvider>(context, listen: false)
          .handleAuthStateChanged();

      // Notify other providers about the auth change
      Provider.of<GroupsProvider>(context, listen: false)
          .handleAuthStateChanged();

      // Add similar method calls for other providers that need to refresh data
      // when a user logs in, if they have handleAuthStateChanged() methods
    }
  }
}
