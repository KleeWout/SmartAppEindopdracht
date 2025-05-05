import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/group.dart';
import '../../providers/groups_provider.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/common/form_field_widget.dart';

class CreateJoinGroupScreen extends StatefulWidget {
  const CreateJoinGroupScreen({super.key});

  @override
  State<CreateJoinGroupScreen> createState() => _CreateJoinGroupScreenState();
}

class _CreateJoinGroupScreenState extends State<CreateJoinGroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _createGroupNameController = TextEditingController();
  final _joinGroupIdController = TextEditingController();
  final _joinGroupNameController = TextEditingController();
  final StorageService _storageService = StorageService.instance;

  File? _imageFile;
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createGroupNameController.dispose();
    _joinGroupIdController.dispose();
    _joinGroupNameController.dispose();
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

  Future<void> _createGroup() async {
    if (_createGroupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Generate unique group ID
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      String? imageUrl;

      // Upload image if selected
      if (_imageFile != null) {
        try {
          imageUrl =
              await _storageService.uploadGroupImage(_imageFile!, groupId);
        } catch (e) {
          // print('Error uploading group image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Failed to upload group image, but group will be created')),
            );
          }
        }
      }

      // Create the group with optional image URL
      await Provider.of<GroupsProvider>(context, listen: false).addGroup(
        Group(
          id: groupId,
          name: _createGroupNameController.text.trim(),
          isFavorite: false,
          imageUrl: imageUrl,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // print('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _joinGroup() async {
    if (_joinGroupIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a group ID')));
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // Use provided group name or a default if not provided
      final groupName = _joinGroupNameController.text.trim().isNotEmpty
          ? _joinGroupNameController.text.trim()
          : 'Joined Group';

      await Provider.of<GroupsProvider>(context, listen: false).joinGroup(
        Group(
          id: _joinGroupIdController.text.trim(),
          name: groupName,
          isFavorite: false,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // print('Error joining group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining group: $e')),
        );
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        title: Text('Group Options', style: AppStyles.heading.copyWith(color: AppColors.getAppBarTextColor(context))),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Create Group'), Tab(text: 'Join Group')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Create Group Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group image selector
                GestureDetector(
                  onTap: _pickImage,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          child: _imageFile == null
                              ? Icon(Icons.group,
                                  size: 50, color: AppColors.primary)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create a New Group',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create a group to share expenses with friends, family, or colleagues.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FormFieldWidget(
                  controller: _createGroupNameController,
                  label: 'Group Name',
                  hint: 'Enter a name for your group',
                  prefixIcon: Icons.create,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('CREATE GROUP'),
                ),
              ],
            ),
          ),

          // Join Group Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.people, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  'Join an Existing Group',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter the group ID shared with you to join an existing group.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FormFieldWidget(
                  controller: _joinGroupIdController,
                  label: 'Group ID',
                  hint: 'Enter the group ID',
                  prefixIcon: Icons.vpn_key,
                ),
                const SizedBox(height: 16),
                FormFieldWidget(
                  controller: _joinGroupNameController,
                  label: 'Group Name (Optional)',
                  hint: 'Enter a name for this group',
                  prefixIcon: Icons.edit,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isJoining ? null : _joinGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('JOIN GROUP'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
