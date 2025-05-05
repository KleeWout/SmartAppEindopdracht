import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _euroFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );
  
  static String formatEuro(double amount) {
    return _euroFormatter.format(amount);
  }
  
  static String formatWithoutSymbol(double amount) {
    return amount.toStringAsFixed(2);
  }
  
  static String formatCompact(double amount) {
    // If it's a round number, don't show decimal places
    if (amount == amount.roundToDouble()) {
      return '€${amount.toInt()}';
    }
    return '€${amount.toStringAsFixed(2)}';
  }
}