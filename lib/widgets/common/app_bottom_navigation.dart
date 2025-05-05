import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../app.dart'; // Import for custom route transitions
import '../../screens/home/home_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../screens/receipt/add_receipt_screen.dart';
import '../../screens/groups/groups_screen.dart';
import '../../screens/settings/settings_screen.dart';

/// Custom bottom navigation bar with a floating action button for adding receipts
///
/// Provides Snapchat-style slide transitions between main screens and a
/// special circle reveal animation when tapping the add receipt button.
class AppBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNavigation({super.key, required this.currentIndex, this.onTap});

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation>
    with SingleTickerProviderStateMixin {
  /// Handles navigation between screens with custom animations
  ///
  /// Uses different transition animations based on navigation direction:
  /// - Slide animation for regular navigation
  /// - Circle reveal animation for the Add Receipt button
  void _handleNavigation(BuildContext context, int index) {
    if (widget.onTap != null) {
      widget.onTap!(index);
      return;
    }

    final routes = {
      0: '/',
      1: '/transactions',
      2: '/add_receipt',
      3: '/groups',
      4: '/settings',
    };

    if (routes.containsKey(index)) {
      // Only navigate if we're not already on that route
      if (index != widget.currentIndex) {
        // Determine direction based on indices for slide animation
        final isMovingRight = index > widget.currentIndex;
        final direction = isMovingRight
            ? SlideDirection.rightToLeft
            : SlideDirection.leftToRight;

        // Special case for Add Receipt button (always use circle reveal animation)
        if (index == 2) {
          _navigateToAddReceipt(context);
        } else {
          // For horizontal navigation, use ParallelSlideRoute for Snapchat-style transitions
          Navigator.pushReplacement(
            context,
            ParallelSlideRoute(
              page: _getPageForRoute(routes[index]!),
              direction: direction,
            ),
          );
        }
      }
    }
  }

  /// Creates a circular reveal animation when navigating to Add Receipt screen
  ///
  /// Calculates the center point of the FAB to start the animation from
  /// and expands outward to cover the entire screen
  void _navigateToAddReceipt(BuildContext context) {
    // Get the position of the FAB in global coordinates
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Calculate center position of the FAB
    final Size size = renderBox.size;
    final Offset fabCenter = renderBox.localToGlobal(
      Offset(size.width / 2,
          -26 + size.height / 2 - 20), // Adjusting for FAB position
    );

    // Navigate with the circle reveal animation
    Navigator.of(context).push(
      CircleRevealRoute(
        centerOffset: fabCenter,
        startRadius: 28, // Size of the FAB (56/2)
        endRadius:
            MediaQuery.of(context).size.longestSide * 1.1, // Larger than screen
        page: const AddReceiptScreen(),
        revealColor: AppColors.primary,
      ),
    );
  }

  /// Returns the appropriate screen widget for a given route
  Widget _getPageForRoute(String route) {
    switch (route) {
      case '/':
        return const HomeScreen();
      case '/transactions':
        return const TransactionsScreen();
      case '/add_receipt':
        return const AddReceiptScreen();
      case '/groups':
        return const GroupsScreen();
      case '/settings':
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Bottom Navigation Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.getBackgroundColor(context),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: (index) => _handleNavigation(context, index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.getBackgroundColor(context),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.getTextColor(context),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: AppStyles.smallText,
            unselectedLabelStyle: AppStyles.smallText,
            elevation:
                0, // No additional elevation since we're using Container's shadow
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_outlined),
                activeIcon: Icon(Icons.receipt),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                // Empty space for the floating button
                icon: SizedBox(height: 24),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'Groups',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),

        // Floating Add Receipt Button with expanded touch target
        Positioned(
          top: -26, // Position the button to rise above the navigation bar
          child: GestureDetector(
            onTap: () => _handleNavigation(context, 2),
            behavior: HitTestBehavior.translucent,
            child: Container(
              height: 72, // Enlarged touch area for better UX
              width: 72, // Enlarged touch area for better UX
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
