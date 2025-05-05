import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../screens/receipt/add_receipt_screen.dart';
import 'dart:math';

class AddReceiptButton extends StatelessWidget {
  const AddReceiptButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: FloatingActionButton(
        onPressed: () {
          _animateToNewScreen(context);
        },
        backgroundColor: AppColors.primary,
        tooltip: 'Add new receipt',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _animateToNewScreen(BuildContext context) {
    // Get the render box of the FAB
    final RenderBox buttonBox = context.findRenderObject() as RenderBox;
    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final buttonSize = buttonBox.size;

    // Calculate the center of the button
    final buttonCenter = Offset(
      buttonPosition.dx + buttonSize.width / 2,
      buttonPosition.dy + buttonSize.height / 2,
    );

    // Calculate the maximum radius needed to cover the entire screen
    final screenSize = MediaQuery.of(context).size;
    final maxRadius = sqrt(
        pow(max(buttonCenter.dx, screenSize.width - buttonCenter.dx), 2) +
            pow(max(buttonCenter.dy, screenSize.height - buttonCenter.dy), 2));

    // Show the expanding circle overlay
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            const AddReceiptScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child) {
          return Stack(
            children: [
              // The expanding circle animation
              AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    painter: CircleExpansionPainter(
                      center: buttonCenter,
                      radius: animation.value * maxRadius,
                      color: Colors.blue,
                    ),
                    child: Container(),
                  );
                },
              ),
              // Fade in the new screen on top of the circle
              FadeTransition(
                opacity: animation,
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom painter for the expanding circle animation
class CircleExpansionPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  CircleExpansionPainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CircleExpansionPainter oldDelegate) {
    return center != oldDelegate.center ||
        radius != oldDelegate.radius ||
        color != oldDelegate.color;
  }
}
