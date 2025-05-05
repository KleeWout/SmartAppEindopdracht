import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);
    
    if (dateToCompare == today) {
      return 'Today';
    } else if (dateToCompare == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    } else {
      return DateFormat('MMMM d, yyyy').format(date); // March 20, 2025
    }
  }
  
  static String formatGroupHeader(DateTime date) {
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    
    if (date.isAfter(startOfCurrentMonth)) {
      return 'March ${date.day}, ${date.year}';
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date); // March 17
    } else {
      return DateFormat('MMMM d, yyyy').format(date); // March 17, 2025
    }
  }
  
  static String formatReceiptDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date); // 20 march 2025
  }
  
  static String getMonthYearString(DateTime date) {
    return DateFormat('MMMM yyyy').format(date); // March 2025
  }
}