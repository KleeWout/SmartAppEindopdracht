import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../models/group.dart';

/// Service for interacting with Firestore database
///
/// Handles all database operations for users, groups, and transactions.
/// Provides methods for data retrieval, creation, updates and deletion.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // === Collection References ===

  /// Reference to users collection
  CollectionReference get usersCollection => _firestore.collection('users');

  /// Reference to groups collection
  CollectionReference get groupsCollection => _firestore.collection('groups');

  /// Get user's personal groups subcollection
  CollectionReference getUserGroupsCollection() {
    return getUserDoc().collection('groups');
  }

  /// Get reference to a specific group document
  DocumentReference getGroupDoc(String groupId) {
    return groupsCollection.doc(groupId);
  }

  /// Get transactions collection for a specific group
  CollectionReference getGroupTransactionsCollection(String groupId) {
    return getGroupDoc(groupId).collection('transactions');
  }

  /// Get reference to current user's document
  DocumentReference getUserDoc() {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }
    return usersCollection.doc(currentUserId);
  }

  /// Get user's transactions collection (deprecated)
  CollectionReference getTransactionsCollection() {
    return getUserDoc().collection('transactions');
  }

  // === User Operations ===

  /// Get user data from Firestore
  ///
  /// Returns null if user is not logged in or document doesn't exist
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUserId == null) {
      print('Cannot get user data: No user is logged in');
      return null;
    }

    try {
      DocumentSnapshot userDoc = await getUserDoc().get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        print('User document does not exist');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Initialize user document if it doesn't exist
  ///
  /// Creates a basic user document structure in Firestore
  Future<void> initializeUserDocument() async {
    if (currentUserId == null) {
      print('Cannot initialize user document: No user is logged in');
      return;
    }

    try {
      final userDoc = await usersCollection.doc(currentUserId).get();

      if (!userDoc.exists) {
        print('User document does not exist. Creating it now...');
        // Create user document with basic structure
        await usersCollection.doc(currentUserId).set({
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('User document created successfully');
      } else {
        print('User document already exists');
      }
    } catch (e) {
      print('Error initializing user document: $e');
      throw e;
    }
  }

  /// Update user profile data
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update(userData);
    }
  }

  // === Group Operations ===

  /// Get all groups for the current user
  ///
  /// Returns a stream of groups that updates in real-time
  Stream<List<Group>> getUserGroups() {
    try {
      // Check if user is logged in
      if (currentUserId == null) {
        print('No user logged in. Cannot get groups.');
        return Stream.value([]);
      }

      print('Getting groups for user ID: $currentUserId');

      return getUserGroupsCollection().snapshots().map((snapshot) {
        print('Groups snapshot received - doc count: ${snapshot.docs.length}');

        final groups = snapshot.docs
            .map((doc) {
              print('Processing group doc: ${doc.id}');
              try {
                return Group.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing group data: $e');
                print('Raw group data: ${doc.data()}');
                return null;
              }
            })
            .where((group) => group != null)
            .cast<Group>()
            .toList();

        print('Parsed ${groups.length} groups successfully');
        return groups;
      });
    } catch (e) {
      print('Error getting user groups: $e');
      return Stream.error(e);
    }
  }

  /// Add a new group created by the current user
  ///
  /// Creates the group in the global groups collection and adds a reference
  /// to the user's personal groups collection
  Future<void> addUserGroup(Group group) async {
    try {
      // First add the group to the groups collection
      await groupsCollection.doc(group.id).set(group.toMap());

      // Then add a reference to the user's groups collection
      await getUserGroupsCollection().doc(group.id).set(group.toMap());
    } catch (e) {
      print('Error adding group: $e');
      throw e;
    }
  }

  /// Join an existing group
  ///
  /// Adds a reference to the group in the user's personal groups collection
  /// without modifying the global group
  Future<void> joinExistingGroup(Group group) async {
    try {
      // Only add a reference to the user's groups collection
      // This avoids permission issues with the global groups collection
      await getUserGroupsCollection().doc(group.id).set(group.toMap());
    } catch (e) {
      print('Error joining group: $e');
      throw e;
    }
  }

  /// Remove a group from the user's groups
  ///
  /// Only removes from the user's personal groups collection,
  /// not from the global groups collection
  Future<void> deleteUserGroup(String groupId) async {
    try {
      // Delete from the user's groups collection
      await getUserGroupsCollection().doc(groupId).delete();

      // Note: We don't delete from the global groups collection
      // as other users may still be using this group
    } catch (e) {
      print('Error deleting group: $e');
      throw e;
    }
  }

  /// Update group details
  ///
  /// Updates both the user's reference and the global group
  Future<void> updateUserGroup(Group group) async {
    try {
      // Update in the user's groups collection
      await getUserGroupsCollection().doc(group.id).update(group.toMap());

      // Update in the main groups collection
      await groupsCollection.doc(group.id).update(group.toMap());
    } catch (e) {
      print('Error updating group: $e');
      throw e;
    }
  }

  /// Check if user is a member of a specific group
  Future<bool> isUserGroupMember(String groupId) async {
    if (currentUserId == null) {
      print('Cannot check group membership: No user is logged in');
      return false;
    }

    try {
      final userGroupDoc = await getUserGroupsCollection().doc(groupId).get();
      return userGroupDoc.exists;
    } catch (e) {
      print('Error checking group membership: $e');
      return false;
    }
  }

  /// Fetch a group by ID from the global groups collection
  Future<Group?> getGroupById(String groupId) async {
    try {
      final groupDoc = await groupsCollection.doc(groupId).get();

      if (!groupDoc.exists) {
        print('Group not found: $groupId');
        return null;
      }

      return Group.fromMap(groupDoc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching group: $e');
      return null;
    }
  }

  // === Transaction Operations ===

  /// Get transactions for a specific group
  ///
  /// Returns a stream that updates in real-time when transactions change
  Stream<List<TransactionModel>> getGroupTransactions(
    String groupId, {
    int? limit,
  }) async* {
    try {
      // First check if the user is a member of this group
      bool isMember = await isUserGroupMember(groupId);

      if (!isMember) {
        print('Permission denied: User is not a member of group $groupId');
        yield [];
        return;
      }

      var query = getGroupTransactionsCollection(
        groupId,
      ).orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      yield* query.snapshots().map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => TransactionModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .toList(),
          );
    } catch (e) {
      print('Error getting group transactions: $e');
      yield [];
    }
  }

  /// Add a transaction to a group
  Future<void> addGroupTransaction(
    String groupId,
    TransactionModel transaction,
  ) async {
    try {
      await getGroupTransactionsCollection(
        groupId,
      ).doc(transaction.id).set(transaction.toMap());
    } catch (e) {
      print('Error adding group transaction: $e');
      throw e;
    }
  }

  /// Add transaction to user's personal collection (deprecated)
  ///
  /// Maintained for backward compatibility only
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await getTransactionsCollection()
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      print('Error adding transaction: $e');
      throw e;
    }
  }

  /// Update transaction in user's personal collection (deprecated)
  ///
  /// Maintained for backward compatibility only
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await getTransactionsCollection()
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      print('Error updating transaction: $e');
      throw e;
    }
  }

  /// Delete transaction from user's personal collection (deprecated)
  ///
  /// Maintained for backward compatibility only
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await getTransactionsCollection().doc(transactionId).delete();
    } catch (e) {
      print('Error deleting transaction: $e');
      throw e;
    }
  }

  /// Get all transactions across all groups
  ///
  /// Aggregates transactions from all groups the user is a member of
  Stream<List<TransactionModel>> getTransactions() {
    try {
      // If no groups are available or logged out, return empty list
      if (currentUserId == null) {
        return Stream.value([]);
      }

      return getUserGroupsCollection().snapshots().asyncMap((
        groupSnapshot,
      ) async {
        final groups = groupSnapshot.docs;
        List<TransactionModel> allTransactions = [];

        // For each group the user is a member of, get its transactions
        for (final groupDoc in groups) {
          final String groupId = groupDoc.id;
          final groupTransactionsSnapshot =
              await getGroupTransactionsCollection(
            groupId,
          ).orderBy('date', descending: true).get();

          final groupTransactions = groupTransactionsSnapshot.docs
              .map(
                (doc) => TransactionModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

          allTransactions.addAll(groupTransactions);
        }

        // Sort all transactions by date
        allTransactions.sort((a, b) => b.date.compareTo(a.date));
        return allTransactions;
      });
    } catch (e) {
      print('Error getting transactions: $e');
      throw e;
    }
  }

  /// Get recent transactions from all groups
  ///
  /// Returns a limited number of the most recent transactions
  Stream<List<TransactionModel>> getRecentTransactions({int limit = 4}) {
    try {
      if (currentUserId == null) {
        return Stream.value([]);
      }

      return getTransactions().map((allTransactions) {
        // Take just the most recent transactions
        return allTransactions.take(limit).toList();
      }).handleError((error) {
        print('Error in getRecentTransactions: $error');
        // Return an empty list instead of propagating the error
        return [];
      });
    } catch (e) {
      print('Error getting recent transactions: $e');
      // Return an empty stream instead of throwing
      return Stream.value([]);
    }
  }
}
