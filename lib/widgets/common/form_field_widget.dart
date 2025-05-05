import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

/// A customized form field widget with consistent styling across the app
///
/// Provides adaptive theming for both light and dark modes,
/// focus-state visual feedback, and error handling capabilities.
class FormFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;
  final FloatingLabelBehavior floatingLabelBehavior;
  final Function(String)? onChanged;

  const FormFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.onChanged,
  });

  @override
  State<FormFieldWidget> createState() => _FormFieldWidgetState();
}

class _FormFieldWidgetState extends State<FormFieldWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// Updates the focus state when the field gains or loses focus
  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-appropriate colors for current context
    final errorColor = AppColors.getErrorColor(context);
    final primaryColor =
        AppColors.getColor(context, AppColors.primary, AppColors.primaryDark);
    final secondaryTextColor = AppColors.getSecondaryTextColor(context);
    final borderColor = AppColors.getColor(
        context, AppColors.lightGrey, AppColors.lightGreyDark);

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: TextStyle(color: secondaryTextColor),
        // Label changes color based on focus and error states
        labelStyle: TextStyle(
          color: widget.errorText != null
              ? errorColor
              : _isFocused
                  ? primaryColor // Only primary color when focused
                  : secondaryTextColor,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: widget.errorText != null
              ? errorColor
              : _isFocused
                  ? primaryColor // Only primary color when focused
                  : secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        // Prefix icon changes color based on focus state
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: _isFocused ? primaryColor : secondaryTextColor,
              )
            : null,
        filled: true,
        fillColor: AppColors.getCardBackgroundColor(context),
        // Normal state border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.buttonRadius / 2),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.buttonRadius / 2),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),
        contentPadding: const EdgeInsets.all(16.0),
        // Focused state border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.buttonRadius / 2),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2.0, // Thicker border when focused
          ),
        ),
        // Error state borders
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.buttonRadius / 2),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.buttonRadius / 2),
          borderSide: BorderSide(color: errorColor),
        ),
        errorText: widget.errorText,
        errorStyle: TextStyle(color: errorColor),
        suffixIcon: widget.suffixIcon,
        floatingLabelBehavior: widget.floatingLabelBehavior,
      ),
      style: TextStyle(
        color: AppColors.getTextColor(context),
        fontSize: 16,
      ),
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      cursorColor: primaryColor,
    );
  }
}
