import 'dart:io';
import 'package:eindopdracht/providers/groups_provider.dart';
import 'package:eindopdracht/providers/receipt_provider.dart';
import 'package:eindopdracht/providers/transaction_provider.dart';
import 'package:eindopdracht/widgets/common/form_field_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService.instance;
  final TextEditingController _nameController = TextEditingController();

  String? _displayName;
  String? _profileImageUrl;
  File? _imageFile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _firestoreService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _displayName = userData['displayName'];
          _profileImageUrl = userData['profileImageUrl'];
          _nameController.text = _displayName ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare data to update
      final Map<String, dynamic> userData = {
        'displayName': _nameController.text.trim(),
      };

      String? newPhotoURL;

      // Upload image if a new one was selected
      if (_imageFile != null) {
        try {
          // Upload image to Firebase Storage
          final imageUrl =
              await _storageService.uploadProfileImage(_imageFile!, user.uid);

          // Add image URL to update data
          userData['profileImageUrl'] = imageUrl;
          newPhotoURL = imageUrl;
        } catch (uploadError) {
          print('Error uploading profile image: $uploadError');
          // Continue with profile update even if image upload fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Failed to upload profile image, but profile info will be updated')),
            );
          }
        }
      }

      // First, update user data in Firestore which is more reliable
      await _firestoreService.updateUserData(userData);

      bool authUpdateSuccess = true;

      // Then try to update Firebase Auth profile
      try {
        await authService.updateUserProfile(
          displayName: _nameController.text.trim(),
          photoURL: newPhotoURL,
        );
      } catch (authError) {
        print('Error updating Firebase Auth profile: $authError');
        authUpdateSuccess = false;
        // We continue because Firestore update already succeeded
      }

      if (mounted) {
        if (authUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Profile information saved but some updates may not appear immediately')),
          );
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error in _saveProfile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error updating profile: ${e.toString().contains('PigeonUser') ? 'Internal error, please try again' : e}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showDeleteAccountConfirmation() {
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please enter your password to confirm:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    enabled: !isLoading,
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (passwordController.text.isEmpty) {
                            setState(() {
                              errorMessage = 'Please enter your password';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            await _deleteAccount(passwordController.text);
                            // Account deleted successfully, will navigate to login screen
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              if (e is FirebaseAuthException) {
                                if (e.code == 'wrong-password') {
                                  errorMessage = 'Incorrect password';
                                } else if (e.code == 'requires-recent-login') {
                                  errorMessage =
                                      'Please sign out and sign in again before deleting your account';
                                } else {
                                  errorMessage =
                                      e.message ?? 'Authentication error';
                                }
                              } else {
                                errorMessage = 'Failed to delete account: $e';
                              }
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAccount(String password) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null || user.email == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get providers to clear data
      final receiptProvider =
          Provider.of<ReceiptProvider>(context, listen: false);
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final groupsProvider =
          Provider.of<GroupsProvider>(context, listen: false);

      // Re-authenticate the user
      await authService.reauthenticate(user.email!, password);

      // Delete user data from Firestore
      // You could add more cleanup logic here if needed

      // Clear provider data
      receiptProvider.resetReceipt();
      transactionProvider.clearData();
      groupsProvider.clearData();

      // Delete the account
      await authService.deleteAccount();

      // Navigate to login screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        title: Text('Edit Profile',
            style: AppStyles.heading
                .copyWith(color: AppColors.getAppBarTextColor(context))),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile Image
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Profile Avatar
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.getColor(
                              context,
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primaryDark.withValues(alpha: 0.2)),
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : _profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                      as ImageProvider
                                  : null,
                          child:
                              (_imageFile == null && _profileImageUrl == null)
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.primary,
                                    )
                                  : null,
                        ),
                      ),

                      // Edit button overlay
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Name Field
                  FormFieldWidget(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Enter your new name',
                    prefixIcon: Icons.person_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getColor(
                            context, AppColors.primary, AppColors.primaryDark),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Delete Account Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showDeleteAccountConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
