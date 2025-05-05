import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  // Singleton pattern
  StorageService._privateConstructor();
  static final StorageService _instance = StorageService._privateConstructor();
  static StorageService get instance => _instance;

  final _uuid = const Uuid();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get local path for temporary storage
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Upload an image to Firebase Storage and return the download URL
  Future<String> uploadReceiptImage(File imageFile, String groupId) async {
    try {
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Verify file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      // Generate a unique filename
      final fileName = '${_uuid.v4()}.jpg';

      // Create reference to the file path in Firebase Storage
      // Store under users/{userId}/receipts/{groupId}/{fileName} for better security
      final storageRef = _storage.ref().child(
            'users/${user.uid}/receipts/$groupId/$fileName',
          );

      // Set metadata to specify content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': user.uid,
          'groupId': groupId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file to Firebase Storage with metadata
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Wait for upload to complete and get download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload a profile image to Firebase Storage and return the download URL
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Verify file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      // Generate a filename using userId for consistency in overwriting previous profile images
      final fileName = 'profile.jpg';

      // Create reference to the file path in Firebase Storage
      // Store under users/{userId}/profile/{fileName}
      final storageRef = _storage.ref().child(
            'users/$userId/profile/$fileName',
          );

      // Set metadata to specify content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'profile',
        },
      );

      // Upload file to Firebase Storage with metadata
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Wait for upload to complete and get download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Upload a group image to Firebase Storage and return the download URL
  Future<String> uploadGroupImage(File imageFile, String groupId) async {
    try {
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Verify file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      // Generate a filename for consistency in overwriting previous group images
      final fileName = 'group_avatar.jpg';

      // Create reference to the file path in Firebase Storage
      // Store under groups/{groupId}/profile/{fileName}
      final storageRef = _storage.ref().child(
            'groups/$groupId/profile/$fileName',
          );

      // Set metadata to specify content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'groupId': groupId,
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'group_profile',
        },
      );

      // Upload file to Firebase Storage with metadata
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Wait for upload to complete and get download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload group image: $e');
    }
  }

  // Get image from Firebase Storage based on URL
  Future<File?> getReceiptImage(String imageUrl) async {
    try {
      // Create a temporary file
      final path = await _localPath;
      final fileName = '${_uuid.v4()}_temp.jpg';
      final tempFile = File('$path/$fileName');

      // Download the file from Firebase Storage
      await _storage.refFromURL(imageUrl).writeToFile(tempFile);

      return tempFile;
    } catch (e) {
      // print('Error downloading receipt image: $e');
      throw e;
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteReceiptImage(String imageUrl) async {
    try {
      // Extract reference from the URL and delete the file
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      // print('Error deleting receipt image: $e');
      throw Exception('Failed to delete image');
    }
  }

  // Create required local directories
  Future<void> createRequiredDirectories() async {
    final path = await _localPath;
    final receiptsDir = Directory('$path/receipts');

    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
  }
}
