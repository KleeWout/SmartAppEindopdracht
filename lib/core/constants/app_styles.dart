import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Text styles
  static const TextStyle heading = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16.0,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14.0,
    color: AppColors.secondaryText,
  );

  static const TextStyle amount = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
  static const TextStyle smallText = TextStyle(
    fontSize: 12.0,
    color: AppColors.secondaryText,
  );

  // Card styles
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const double cardRadius = 12.0;
  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 8.0,
    offset: const Offset(0, 2),
  );

  // Button styles
  static const double buttonRadius = 24.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    vertical: 12.0,
    horizontal: 24.0,
  );

  //input styles
  static const TextStyle inputLabel = TextStyle(
    fontSize: 16.0,
    color: AppColors.text,
  );

  //Transaction item styles
  static const TextStyle transactionTitle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w500,
    // color: Color(0xFF333333),
  );

  static const TextStyle transactionCategory = TextStyle(
    fontSize: 16.0,
    color: Color(0xFF7A8AA3),
  );

  static TextStyle receiptDetailText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
}
