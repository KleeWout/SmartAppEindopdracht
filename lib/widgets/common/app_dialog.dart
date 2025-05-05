import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final bool dismissible;
  final EdgeInsetsGeometry contentPadding;
  final double borderRadius;

  const AppDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.dismissible = true,
    this.contentPadding = const EdgeInsets.all(20.0),
    this.borderRadius = 12.0,
  });

  /// Shows a loading dialog with a circular progress indicator
  static Future<void> showLoading(
    BuildContext context, {
    String message = 'Loading...',
    String? subMessage,
    bool dismissible = false,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder:
          (BuildContext context) => AppDialog(
            dismissible: dismissible,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                if (subMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      subMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  /// Shows a confirmation dialog with custom title, message and actions
  static Future<T?> showConfirmation<T>(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool dismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder:
          (BuildContext context) => AppDialog(
            dismissible: dismissible,
            title: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(context),
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(context),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryText,
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                  if (onCancel != null) onCancel();
                },
                child: Text(cancelText),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.of(context).pop(true);
                  if (onConfirm != null) onConfirm();
                },
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: contentPadding,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  child: title!,
                ),
              ),
            ),
            const Divider(),
          ],
          content,
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
          ],
        ],
      ),
    );
  }
}
