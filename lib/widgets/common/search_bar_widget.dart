import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final bool showClearButton;
  final IconData? prefixIcon;
  final bool showBorder;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.showClearButton = true,
    this.prefixIcon = Icons.search,
    this.showBorder = true,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
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

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        AppColors.getColor(context, AppColors.primary, AppColors.primaryDark);
    final secondaryTextColor = AppColors.getSecondaryTextColor(context);
    final backgroundColor = AppColors.getCardBackgroundColor(context);
    final borderColor =
        _isFocused ? primaryColor : AppColors.getCardBorderColor(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: widget.showBorder
            ? Border.all(
                color: borderColor,
                width: _isFocused ? 2.0 : 1.0,
              )
            : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(
              widget.prefixIcon,
              color:
                  _isFocused ? primaryColor : AppColors.getIconColor(context),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: secondaryTextColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(
                color: AppColors.getTextColor(context),
              ),
              onChanged: widget.onChanged,
              cursorColor: primaryColor,
              // Ensure keyboard appears when tapped
              showCursor: true,
              // Make sure text input is enabled
              enableInteractiveSelection: true,
              // Ensure input is not blocked
              keyboardType: TextInputType.text,
              // Set text input action
              textInputAction: TextInputAction.search,
            ),
          ),
          if (widget.showClearButton && widget.controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                widget.controller.clear();
                widget.onChanged('');
                // Request focus after clearing to keep keyboard open
                _focusNode.requestFocus();
              },
              color: _isFocused ? primaryColor : null,
            ),
        ],
      ),
    );
  }
}
