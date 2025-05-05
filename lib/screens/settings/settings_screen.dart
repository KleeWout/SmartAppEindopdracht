import 'package:eindopdracht/widgets/common/add_receipt_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_bottom_navigation.dart';
import '../../screens/receipt/category_selection_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _displayName;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current authenticated user
      final user = Provider.of<AuthService>(context, listen: false).currentUser;

      // First try to get user data from Firestore which is more likely to have the latest profile image
      final userData = await _firestoreService.getUserData();

      if (mounted) {
        setState(() {
          // Prefer Firestore data if available
          if (userData != null &&
              userData.containsKey('displayName') &&
              userData['displayName'] != null) {
            _displayName = userData['displayName'];
            _profileImageUrl = userData['profileImageUrl'];
          } else if (user != null) {
            // Fall back to Firebase Auth data
            _displayName = user.displayName;
            _profileImageUrl = user.photoURL;

            // If this is first login and displayName is still null or empty, use email as fallback
            if ((_displayName == null || _displayName!.isEmpty) &&
                user.email != null) {
              // Extract username from email (everything before @)
              _displayName = user.email!.split('@')[0];

              // Create a Firestore record for the user to ensure future data is available
              if (userData == null) {
                _firestoreService.updateUserData({
                  'displayName': _displayName,
                  'email': user.email,
                });
              }
            }
          }

          // For debugging - add a print statement to see what URL we're trying to load
          print('Debug - Profile Image URL: $_profileImageUrl');
          print('Debug - Display Name: $_displayName');

          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        iconTheme: IconThemeData(
          color: AppColors.primary, // Use app's primary color for back arrow
        ),
        title: Text('Settings',
            style: AppStyles.heading.copyWith(
              color: AppColors.getAppBarTextColor(context),
            )),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Card
                  Card(
                    color: AppColors.getCardBackgroundColor(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.getCardBorderColor(context),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Profile avatar and info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.2),
                                backgroundImage: _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                                child: _profileImageUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _displayName ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? 'No email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.getSecondaryTextColor(
                                            context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Settings sections
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Settings list
                  Card(
                    color: AppColors.getCardBackgroundColor(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.getCardBorderColor(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () => _navigateToEditProfile(context),
                        ),
                        _buildDivider(),
                        _buildSettingItem(
                          icon: Icons.lock_outline,
                          title: 'Security',
                          onTap: () => _navigateToSecurity(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    color: AppColors.getCardBackgroundColor(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.getCardBorderColor(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CategorySelectionScreen(
                                  currentCategory: '',
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        ListTile(
                          leading: Icon(Icons.dark_mode_outlined,
                              color: AppColors.primary),
                          title: const Text('Dark Mode'),
                          trailing: Switch.adaptive(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeColor: AppColors.primary,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade300,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            trackOutlineColor:
                                WidgetStateProperty.all(Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(context, authService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 4),
      // Removed floatingActionButton and floatingActionButtonLocation
    );
  }

  // Helper method to navigate to EditProfileScreen
  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    )
        .then((_) {
      // Refresh user data when returning from EditProfileScreen
      _loadUserData();
    });
  }

  // Helper method to navigate to SecurityScreen
  void _navigateToSecurity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SecurityScreen(),
      ),
    );
  }

  // Helper method to build a single setting item
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Helper method to build a divider
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.getDividerColor(context),
    );
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthService authService,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Sign out and clear saved credentials
                await authService.signOut();
                await authService.clearSavedCredentials();

                // Navigate to login screen
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
