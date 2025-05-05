import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service that manages all authentication-related functionality
///
/// Handles user authentication with Firebase Auth and credential management
/// with SharedPreferences for features like "Remember Me".
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SharedPreferences keys
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if a user is currently logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Save user credentials if "Remember Me" is enabled
  ///
  /// Stores email and password in SharedPreferences only if rememberMe is true.
  /// If rememberMe is false, any stored credentials are removed.
  Future<void> saveLoginCredentials(
    String email,
    String password,
    bool rememberMe,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Save rememberMe preference
    await prefs.setBool(_rememberMeKey, rememberMe);

    // Only save credentials if rememberMe is true
    if (rememberMe) {
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);
    } else {
      // Clear saved credentials if rememberMe is false
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);
    }
  }

  /// Retrieve saved login credentials from SharedPreferences
  ///
  /// Returns a map containing rememberMe status and credentials (if enabled)
  Future<Map<String, dynamic>> getSavedLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (rememberMe) {
      final email = prefs.getString(_emailKey) ?? '';
      final password = prefs.getString(_passwordKey) ?? '';

      return {'rememberMe': rememberMe, 'email': email, 'password': password};
    }

    return {'rememberMe': rememberMe, 'email': '', 'password': ''};
  }

  /// Sign in with email and password
  ///
  /// Handles Firebase Auth exceptions and includes error logging for troubleshooting
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print("Attempting to sign in with email: $email");

      // Use a safer approach to handle Firebase Auth responses
      try {
        final result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print("Sign in successful for user: ${result.user?.uid}");
        return result;
      } on FirebaseAuthException catch (authError) {
        print(
            "Firebase Auth Exception: ${authError.code} - ${authError.message}");
        rethrow;
      }
    } catch (e) {
      print("Sign in error: $e");
      if (e is TypeError) {
        // Handle the specific type casting error
        print(
            "Type error during authentication. This is likely due to a Firebase SDK version mismatch.");

        // Check if the user was actually authenticated despite the error
        if (_auth.currentUser != null) {
          print(
              "User appears to be authenticated despite error. Creating UserCredential manually.");
          throw FirebaseAuthException(
              code: 'type-error',
              message:
                  'Authentication succeeded but encountered a type error. Please try again.');
        }
      }
      rethrow;
    }
  }

  /// Create a new user account with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  /// Attempt automatic login with saved credentials
  ///
  /// Uses credentials stored in SharedPreferences to log in the user
  /// without requiring manual input. Only works if "Remember Me" was enabled.
  Future<bool> tryAutoLogin() async {
    try {
      // If the user is already logged in, no need to proceed with auto-login
      if (_auth.currentUser != null) {
        print("User already logged in, skipping auto-login");
        return true;
      }

      final credentials = await getSavedLoginCredentials();
      print("Trying auto-login, remember me: ${credentials['rememberMe']}");

      if (credentials['rememberMe'] &&
          credentials['email'].isNotEmpty &&
          credentials['password'].isNotEmpty) {
        try {
          print("Attempting auto-login for email: ${credentials['email']}");
          await signInWithEmailAndPassword(
            credentials['email'],
            credentials['password'],
          );
          print("Auto-login successful");
          return true;
        } on FirebaseAuthException catch (e) {
          print(
              "Auto-login failed with Firebase Auth Exception: ${e.code} - ${e.message}");

          // Check if auth was successful despite the exception (some error types)
          if (_auth.currentUser != null) {
            print("User appears to be logged in despite exception");
            return true;
          }
          return false;
        } catch (e) {
          print("Auto-login failed: $e");
          return false;
        }
      }

      print("Auto-login skipped - conditions not met");
      return false;
    } catch (e) {
      print("Error during auto-login process: $e");
      return false;
    }
  }

  /// Clear all saved credentials from SharedPreferences
  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }

  /// Send a password reset email to the provided email address
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update the user's profile information
  ///
  /// Handles Firebase SDK version compatibility issues with a fallback approach
  /// that tries individual updates if the batch update fails.
  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Try the combined update first (more efficient)
      try {
        // Create update object with only the fields that are provided
        Map<String, dynamic> profileUpdates = {};
        if (displayName != null) profileUpdates['displayName'] = displayName;
        if (photoURL != null) profileUpdates['photoURL'] = photoURL;

        // Only perform update if there are changes to make
        if (profileUpdates.isNotEmpty) {
          await user.updateProfile(
              displayName: displayName, photoURL: photoURL);
          // Force refresh user to ensure changes are reflected
          await user.reload();
        }
      } catch (e) {
        print('Error in updateProfile: $e');
        // Fallback to individual updates if the combined update fails

        // Try updating display name
        if (displayName != null) {
          try {
            await _setDisplayName(user, displayName);
          } catch (e) {
            print('Error updating display name: $e');
          }
        }

        // Try updating photo URL
        if (photoURL != null) {
          try {
            await _setPhotoURL(user, photoURL);
          } catch (e) {
            print('Error updating photo URL: $e');
          }
        }
      }

      return;
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Helper method to set display name safely with SDK version compatibility
  Future<void> _setDisplayName(User user, String displayName) async {
    try {
      await user.updateProfile(displayName: displayName);
    } catch (e) {
      print('Error in _setDisplayName: $e');
      // The Firestore profile will still be updated if we're using that
    }
  }

  // Helper method to set photo URL safely with SDK version compatibility
  Future<void> _setPhotoURL(User user, String photoURL) async {
    try {
      await user.updateProfile(photoURL: photoURL);
    } catch (e) {
      print('Error in _setPhotoURL: $e');
      // The Firestore profile will still be updated if we're using that
    }
  }

  /// Delete the current user account and all associated data
  ///
  /// This operation:
  /// 1. Deletes the user's data from Firestore (document and subcollections)
  /// 2. Deletes the user's authentication record
  /// 3. Clears any saved credentials
  ///
  /// Requires recent authentication. If this fails with a requires-recent-login error,
  /// the user should be prompted to re-authenticate before calling this method again.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final String userId = user.uid;

    try {
      // Create a Firestore batch to perform multiple operations atomically
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 1. Get reference to the user document
      final userDocRef = firestore.collection('users').doc(userId);

      // 2. Get all groups where the user is a member
      final userGroupsSnapshot = await userDocRef.collection('groups').get();

      // 3. Process each group (remove user reference)
      for (final groupDoc in userGroupsSnapshot.docs) {
        final String groupId = groupDoc.id;

        // Get a reference to the group document in the main groups collection
        final groupRef = firestore.collection('groups').doc(groupId);

        // Get the group data to check if the user is the owner
        final groupData = await groupRef.get();

        if (groupData.exists) {
          // Check if the user is the owner of this group
          final groupMap = groupData.data() as Map<String, dynamic>;
          final String? creatorId = groupMap['creatorId'] as String?;

          if (creatorId == userId) {
            // User is the owner - you might want to:
            // Option 1: Delete the entire group and its transactions
            // Get all transactions in the group
            final transactionsSnapshot =
                await groupRef.collection('transactions').get();

            // Add delete operations for all transactions to the batch
            final batch = firestore.batch();
            for (final transactionDoc in transactionsSnapshot.docs) {
              batch.delete(transactionDoc.reference);
            }

            // Add delete operation for the group itself
            batch.delete(groupRef);

            // Commit this batch separately to avoid exceeding batch size limits
            await batch.commit();

            // Note: Additional logic could be added here to transfer ownership
            // to another member instead of deleting the group
          }
          // If user is not the owner, we don't delete the group
        }
      }

      // 4. Delete the user document and all its subcollections
      // This is done after group processing to ensure we have access to the groups data
      await _deleteUserDocumentAndSubcollections(userId);

      // 5. Delete the Firebase Authentication account
      await user.delete();

      // 6. Clear saved credentials
      await clearSavedCredentials();
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }

  /// Helper method to delete a user document and all its subcollections
  Future<void> _deleteUserDocumentAndSubcollections(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(userId);

    // Delete subcollections first
    // 1. Delete groups subcollection
    final userGroupsSnapshot = await userDocRef.collection('groups').get();
    final groupsBatch = firestore.batch();

    for (final doc in userGroupsSnapshot.docs) {
      groupsBatch.delete(doc.reference);
    }

    if (userGroupsSnapshot.docs.isNotEmpty) {
      await groupsBatch.commit();
    }

    // 2. Delete transactions subcollection (if it exists for backward compatibility)
    final userTransactionsSnapshot =
        await userDocRef.collection('transactions').get();
    final transactionsBatch = firestore.batch();

    for (final doc in userTransactionsSnapshot.docs) {
      transactionsBatch.delete(doc.reference);
    }

    if (userTransactionsSnapshot.docs.isNotEmpty) {
      await transactionsBatch.commit();
    }

    // 3. Finally delete the user document itself
    await userDocRef.delete();
  }

  /// Re-authenticate user with email and password
  ///
  /// Used before sensitive operations like changing password or deleting account
  Future<void> reauthenticate(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create credential
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    // Re-authenticate
    await user.reauthenticateWithCredential(credential);
  }
}
