import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/transactions/transaction_detail_screen.dart';
import 'screens/receipt/add_receipt_screen.dart';
import 'screens/groups/groups_screen.dart';
import 'screens/groups/group_detail_page.dart';
import 'screens/groups/create_join_group_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'core/constants/app_colors.dart';
import 'core/models/transaction.dart';
import 'core/models/group.dart';
import 'main.dart'; // Import for the global navigator key

/// Custom page transition that slides pages in parallel (Snapchat-style)
///
/// Creates an animation where both the current page and the new page
/// slide simultaneously in opposite directions.
class ParallelSlideRoute extends PageRouteBuilder {
  final Widget page;
  final SlideDirection direction;

  ParallelSlideRoute({required this.page, required this.direction})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Define the incoming slide offset based on direction
            final incomingOffset = direction == SlideDirection.rightToLeft
                ? const Offset(1.0, 0.0) // Coming from right
                : const Offset(-1.0, 0.0); // Coming from left

            // Define the outgoing slide offset (opposite direction)
            final outgoingOffset = direction == SlideDirection.rightToLeft
                ? const Offset(-1.0, 0.0) // Going to left
                : const Offset(1.0, 0.0); // Going to right

            // Create animations with easing
            final incomingAnimation = Tween(
              begin: incomingOffset,
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation);

            final outgoingAnimation = Tween(
              begin: Offset.zero,
              end: outgoingOffset,
            )
                .chain(CurveTween(curve: Curves.easeInOut))
                .animate(secondaryAnimation);

            return Stack(
              children: [
                // Outgoing page (current page sliding out)
                SlideTransition(
                  position: outgoingAnimation,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const SizedBox.expand(),
                  ),
                ),
                // Incoming page (new page sliding in)
                SlideTransition(position: incomingAnimation, child: child),
              ],
            );
          },
        );
}

/// Custom page transition with expanding circle reveal effect
///
/// Used for the "Add Receipt" button to create a visually appealing transition
/// that starts from the FAB's position and expands to reveal the new screen.
class CircleRevealRoute extends PageRouteBuilder {
  final Offset
      centerOffset; // Center point of the circle (typically the FAB position)
  final double startRadius; // Initial radius (typically the FAB radius)
  final double endRadius; // Final radius (large enough to cover the screen)
  final Widget page; // Destination page
  final Color revealColor; // Color of the expanding circle

  CircleRevealRoute({
    required this.centerOffset,
    required this.startRadius,
    required this.endRadius,
    required this.page,
    required this.revealColor,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          opaque: false,
          barrierColor: Colors.transparent,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Split the animation into two parts:
            // 1. Circle expansion (0.0-0.6)
            // 2. Page slide up (0.5-1.0)

            // First part: Circle expansion
            final circleAnimationValue = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ).value;

            // Second part: Page slide up
            final slideAnimationValue = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuint),
            ).value;

            // Calculate current radius
            final currentRadius =
                startRadius + (endRadius - startRadius) * circleAnimationValue;

            // Calculate slide offset
            final slideOffset = Offset(0.0, 200 * (1.0 - slideAnimationValue));

            return Stack(
              children: [
                // Circle expansion
                CustomPaint(
                  painter: CircleRevealPainter(
                    centerOffset: centerOffset,
                    radius: currentRadius,
                    color: revealColor,
                  ),
                  child: const SizedBox.expand(),
                ),

                // Sliding page (only visible after circle expands)
                Opacity(
                  opacity: slideAnimationValue,
                  child: Transform.translate(
                    offset: slideOffset,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

/// Custom painter that draws the expanding circle for CircleRevealRoute
class CircleRevealPainter extends CustomPainter {
  final Offset centerOffset;
  final double radius;
  final Color color;

  CircleRevealPainter({
    required this.centerOffset,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(centerOffset, radius, paint);
  }

  @override
  bool shouldRepaint(CircleRevealPainter oldDelegate) {
    return oldDelegate.centerOffset != centerOffset ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}

/// Custom page transition that slides a page up from the bottom
///
/// Used for modal-style screens where content appears to slide up
/// from the bottom of the screen with a darkened background.
class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide up animation
            var slideTween = Tween(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            // Background fade animation
            var fadeTween = Tween(
              begin: 0.0,
              end: 0.5,
            ).chain(CurveTween(curve: Curves.easeOut));

            return Stack(
              children: [
                // Fade overlay for background dimming
                FadeTransition(
                  opacity: animation.drive(fadeTween),
                  child: Container(color: AppColors.black),
                ),
                // Slide animation for new page
                SlideTransition(
                  position: animation.drive(slideTween),
                  child: child,
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          opaque: false,
          barrierColor: AppColors.transparent,
        );
}

/// Direction enum for slide transitions
enum SlideDirection { leftToRight, rightToLeft }

/// Main application widget
///
/// Configures the app's themes, routes, and navigation transitions.
/// Handles authentication state to determine the initial route.
class ReceiptApp extends StatelessWidget {
  final bool isLoggedIn;

  const ReceiptApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Receipt Tracker',
      theme: AppColors.getLightTheme(),
      darkTheme: AppColors.getDarkTheme(),
      themeMode: themeProvider.themeMode,
      initialRoute: isLoggedIn ? '/' : '/login',
      navigatorKey:
          navigatorKey, // Global navigator key for access from anywhere
      routes: {'/login': (context) => const LoginScreen()},
      onGenerateRoute: (settings) {
        // Special case for add receipt (always slides up)
        if (settings.name == '/add_receipt') {
          return SlideUpRoute(page: const AddReceiptScreen());
        }

        // Handle transaction detail and group detail
        if (settings.name == '/transaction-detail') {
          final transaction = settings.arguments as TransactionModel;
          return ParallelSlideRoute(
            page: TransactionDetailScreen(transaction: transaction),
            direction: SlideDirection.rightToLeft,
          );
        }

        if (settings.name == '/group-detail') {
          final group = settings.arguments as Group;
          return ParallelSlideRoute(
            page: GroupDetailPage(group: group),
            direction: SlideDirection.rightToLeft,
          );
        }

        if (settings.name == '/create-join-group') {
          return ParallelSlideRoute(
            page: const CreateJoinGroupScreen(),
            direction: SlideDirection.rightToLeft,
          );
        }

        // For main navigation screens, use the default navigation
        // The direction logic is handled in AppBottomNavigation
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/transactions':
            return MaterialPageRoute(
              builder: (_) => const TransactionsScreen(),
            );
          case '/groups':
            return MaterialPageRoute(builder: (_) => const GroupsScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
        }

        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
