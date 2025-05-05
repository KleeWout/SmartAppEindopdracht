import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingIndicator({
    super.key,
    this.message,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final loadingContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              message!,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16.0,
              ),
            ),
          ),
      ],
    );

    if (fullScreen) {
      return Container(
        color: Colors.white.withValues(alpha:  0.9),
        child: Center(
          child: loadingContent,
        ),
      );
    }

    return Center(
      child: loadingContent,
    );
  }
}