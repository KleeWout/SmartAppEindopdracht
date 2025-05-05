import 'package:flutter/material.dart';

/// Core color definitions and theme configuration for the app
///
/// Contains all color constants, theme generation methods, and utility functions
/// to maintain consistent styling across both light and dark themes.
class AppColors {
  // === Primary Theme Colors ===
  static const Color primary = Color(0xFF4169F7);
  static const Color primaryDark = Color(0xFF537AFD);
  static const Color secondary = Color(0xFF4169F7);
  static const Color secondaryDark = Color(0xFF537AFD);
  static const MaterialColor primarySwatch = Colors.blue;

  // === Background Colors ===
  static const Color background = Color(0xFFF4F7FA);
  static const Color backgroundDark = Color(0xFF101927);
  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundDark = Color(0xFF101726);
  static const Color transparent = Colors.transparent;

  // === Text Colors ===
  static const Color text = Color(0xFF333333);
  static const Color textDark = Color(0xFFEEEEEE);
  static const Color secondaryText = Color(0xFF757575);
  static const Color secondaryTextDark = Color.fromARGB(255, 192, 185, 185);

  // === UI Element Colors ===
  static const Color divider = Color(0xFFEEEEEE);
  static const Color dividerDark = Color(0xFF3A3A3A);
  static const Color iconBackground = Color(0xFF3D3D3D);
  static const Color iconBackgroundDark = Color.fromARGB(255, 225, 224, 224);
  static const Color buttonSecondary = Color(0xFFE7F0FF);
  static const Color buttonSecondaryDark = Color(0xFF2A3A5F);
  static const Color borderGray1 = Color(0xFFe3e3e3);
  static const Color borderGray1Dark = Color(0xff374151);

  // === Gray Scale Colors ===
  static const Color black = Colors.black;
  static const Color grey = Color(0xFFBDBDBD);
  static const Color greyDark = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color lightGreyDark = Color(0xFF474747);

  // === Status Colors ===
  static const Color error = Colors.red;
  static const Color errorDark = Colors.redAccent;
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFFFD54F);

  // === App Bar and Navigation Colors ===
  static const Color appBarBackground = Colors.white;
  static const Color appBarBackgroundDark = Color(0xFF1A2540);
  static const Color appBarText = Color(0xFF333333);
  static const Color appBarTextDark = Colors.white;

  // === Modal Colors ===
  static const Color modalBarrier = Colors.black;
  static const Color modalBackground = Colors.white;
  static const Color modalBackgroundDark = Color(0xFF2C2C2C);

  // === Shadow Colors ===
  static const Color shadow = Color(0xFF000000);
  static const Color shadowDark = Color(0xFF000000);

  // === Theme Configuration Methods ===

  /// Creates the light theme for the app
  static ThemeData getLightTheme() {
    return ThemeData(
      primarySwatch: primarySwatch,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarText,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        titleLarge: TextStyle(color: text),
        titleMedium: TextStyle(color: text),
        titleSmall: TextStyle(color: text),
        labelLarge: TextStyle(color: text),
      ),
      dividerColor: divider,
      cardColor: cardBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: cardBackground,
        error: error,
      ),
    );
  }

  /// Creates the dark theme for the app
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackgroundDark,
        foregroundColor: appBarTextDark,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
        titleLarge: TextStyle(color: textDark),
        titleMedium: TextStyle(color: textDark),
        titleSmall: TextStyle(color: textDark),
        labelLarge: TextStyle(color: textDark),
      ),
      dividerColor: dividerDark,
      cardColor: cardBackgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: cardBackgroundDark,
        background: backgroundDark,
        error: errorDark,
      ),
    );
  }

  // === Utility Methods ===

  /// Returns the appropriate color based on the current theme
  ///
  /// Automatically selects between light and dark variants based on the
  /// current theme brightness in the provided context.
  static Color getColor(
      BuildContext context, Color lightColor, Color darkColor) {
    return Theme.of(context).brightness == Brightness.light
        ? lightColor
        : darkColor;
  }

  // === Convenience Getters for Common Colors ===

  /// Gets the main background color based on current theme
  static Color getBackgroundColor(BuildContext context) {
    return getColor(context, background, backgroundDark);
  }

  /// Gets the card background color based on current theme
  static Color getCardBackgroundColor(BuildContext context) {
    return getColor(context, cardBackground, cardBackgroundDark);
  }

  /// Gets the card border color based on current theme
  static Color getCardBorderColor(BuildContext context) {
    return getColor(context, borderGray1, borderGray1Dark);
  }

  /// Gets the primary text color based on current theme
  static Color getTextColor(BuildContext context) {
    return getColor(context, text, textDark);
  }

  /// Gets the secondary text color based on current theme
  static Color getSecondaryTextColor(BuildContext context) {
    return getColor(context, secondaryText, secondaryTextDark);
  }

  /// Gets the divider color based on current theme
  static Color getDividerColor(BuildContext context) {
    return getColor(context, divider, dividerDark);
  }

  /// Gets the error color based on current theme
  static Color getErrorColor(BuildContext context) {
    return getColor(context, error, errorDark);
  }

  /// Gets the app bar background color based on current theme
  static Color getAppBarBackgroundColor(BuildContext context) {
    return getColor(context, appBarBackground, appBarBackgroundDark);
  }

  /// Gets the app bar text color based on current theme
  static Color getAppBarTextColor(BuildContext context) {
    return getColor(context, appBarText, appBarTextDark);
  }

  /// Gets the icon color based on current theme
  static Color getIconColor(BuildContext context) {
    return getColor(context, iconBackground, iconBackgroundDark);
  }

  /// Gets the receipt detail divider color based on current theme
  static Color getReceiptDetailDividerColor(BuildContext context) {
    return getColor(context, divider, dividerDark);
  }

  /// Gets the receipt detail shadow color based on current theme
  static Color getReceiptDetailShadowColor(BuildContext context) {
    return getColor(context, shadow, shadowDark);
  }

  /// Gets the receipt detail header color based on current theme
  static Color getReceiptDetailHeader(BuildContext context) {
    return getColor(context, Colors.blue.shade50, AppColors.primary);
  }

  /// Gets the edit transaction border color based on current theme
  static Color getEditTransactionBorder(BuildContext context) {
    return getColor(context, Colors.black, Colors.white);
  }

  /// Creates a primary button style that adapts to current theme
  static ButtonStyle getPrimaryButtonStyle(BuildContext context,
      {double borderRadius = 8}) {
    return ElevatedButton.styleFrom(
      backgroundColor: getColor(context, primary, primary),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
