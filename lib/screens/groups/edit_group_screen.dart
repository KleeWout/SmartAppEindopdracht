import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/models/group.dart';
import '../../providers/groups_provider.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/common/form_field_widget.dart';

class EditGroupScreen extends StatefulWidget {
  final Group group;

  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final StorageService _storageService = StorageService.instance;
  final TextEditingController _nameController = TextEditingController();

  File? _imageFile;
  bool _isSaving = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.group.name;
    _currentImageUrl = widget.group.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Prepare data to update
      String? newImageUrl = _currentImageUrl;

      // Upload image if a new one was selected
      if (_imageFile != null) {
        try {
          // Upload image to Firebase Storage (in groups folder)
          newImageUrl = await _storageService.uploadGroupImage(
              _imageFile!, widget.group.id);
        } catch (uploadError) {
          // print('Error uploading group image: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Failed to upload group image, but group info will be updated'),
              ),
            );
          }
        }
      }

      // Create updated group
      final updatedGroup = widget.group.copyWith(
        name: _nameController.text.trim(),
        imageUrl: newImageUrl,
      );

      // Update the group in Firestore through the provider
      await Provider.of<GroupsProvider>(context, listen: false)
          .updateGroup(updatedGroup);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // print('Error in _saveGroup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating group: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        iconTheme: IconThemeData(
          color: AppColors.getAppBarTextColor(context),
        ),
        title: Text('Edit Group',
            style: AppStyles.heading
                .copyWith(color: AppColors.getAppBarTextColor(context))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Group Image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Group Avatar
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : _currentImageUrl != null
                            ? NetworkImage(_currentImageUrl!) as ImageProvider
                            : null,
                    child: (_imageFile == null && _currentImageUrl == null)
                        ? Icon(
                            Icons.group,
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

            // Group Name Field
            FormFieldWidget(
              controller: _nameController,
              label: 'Group Name',
              hint: 'Enter a name for this group',
              prefixIcon: Icons.group_outlined,
            ),

            const SizedBox(height: 16),

            // Group ID (read-only)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group ID',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.group.id,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
          ],
        ),
      ),
    );
  }
}
